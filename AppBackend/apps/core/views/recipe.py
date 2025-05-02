# AppBackend/apps/core/views/recipe.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q, Exists, OuterRef
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page

from ..mixins import CacheInvalidationMixin

from ..models import (
    Recipe, Step, M2MStpIgt, FavoriteRecipe,
    IngredientType, Ingredient, M2MUsrIng,
    M2MIngAlg
)
from ..serializers import (
    RecipeListSerializer, RecipeDetailSerializer,
    StepSerializer, FavoriteRecipeSerializer
)


@method_decorator(cache_page(60 * 60 * 10), name='list')
class RecipeViewSet(viewsets.ReadOnlyModelViewSet):
    """API для доступа к рецептам"""
    queryset = Recipe.objects.all()
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        """Выбор сериализатора в зависимости от действия"""
        if self.action == 'retrieve':
            return RecipeDetailSerializer
        return RecipeListSerializer

    def get_serializer_context(self):
        """Добавление request в контекст сериализатора"""
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context

    def get_queryset(self):
        """Фильтрация рецептов по различным параметрам"""
        queryset = Recipe.objects.all()

        # Поиск по названию или описанию
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(rcp_title__icontains=search) | Q(rcp_description__icontains=search)
            )

        return queryset

    @action(detail=False, methods=['get'])
    def recommended(self, request):
        """Рекомендуемые рецепты для пользователя"""
        # Получаем ингредиенты пользователя
        user_ingredients = M2MUsrIng.objects.filter(mui_usr_id=request.user)
        user_ingredient_ids = [item.mui_ing_id_id for item in user_ingredients]

        # Получаем оборудование пользователя
        user_equipment_ids = request.user.equipment.values_list('eqp_id', flat=True)

        # Получаем аллергены пользователя
        user_allergen_ids = request.user.allergens.values_list('alg_id', flat=True)

        # Исключаем рецепты с ингредиентами-аллергенами
        excluded_ingredient_ids = []
        if user_allergen_ids:
            # Получаем ингредиенты с аллергенами
            allergen_ingredients = Ingredient.objects.filter(
                Exists(
                    M2MIngAlg.objects.filter(
                        mia_ing_id=OuterRef('pk'),
                        mia_alg_id__in=user_allergen_ids
                    )
                )
            )
            excluded_ingredient_ids = list(allergen_ingredients.values_list('ing_id', flat=True))

        # Базовый запрос для рецептов
        queryset = Recipe.objects.prefetch_related('equipment', 'steps', 'steps__ingredient_types')

        # Применяем фильтры
        if excluded_ingredient_ids:
            # Исключаем рецепты с аллергенами
            queryset = queryset.exclude(
                Exists(
                    Step.objects.filter(
                        stp_rcp_id=OuterRef('pk')
                    ).filter(
                        Exists(
                            M2MStpIgt.objects.filter(
                                msi_stp_id=OuterRef('pk'),
                                msi_igt_id__in=IngredientType.objects.filter(
                                    ingredients__in=excluded_ingredient_ids
                                )
                            )
                        )
                    )
                )
            )

        # Сортируем по соответствию с имеющимися ингредиентами и оборудованием
        recipes = []
        for recipe in queryset:
            score = 0

            # Проверяем оборудование
            recipe_equipment_ids = recipe.equipment.values_list('eqp_id', flat=True)
            equipment_match = all(eqp_id in user_equipment_ids for eqp_id in recipe_equipment_ids)
            if equipment_match:
                score += 10

            # Проверяем ингредиенты
            ingredient_match_count = 0
            recipe_steps = recipe.steps.all()
            required_ingredient_types = set()

            for step in recipe_steps:
                step_ingredients = M2MStpIgt.objects.filter(msi_stp_id=step)
                for ing in step_ingredients:
                    required_ingredient_types.add(ing.msi_igt_id_id)

            # Для каждого типа ингредиента проверяем, есть ли соответствующий ингредиент у пользователя
            for ing_type_id in required_ingredient_types:
                matching_ingredients = Ingredient.objects.filter(
                    ing_igt_id=ing_type_id,
                    ing_id__in=user_ingredient_ids
                )
                if matching_ingredients.exists():
                    ingredient_match_count += 1

            if required_ingredient_types:
                score += (ingredient_match_count / len(required_ingredient_types)) * 90

            recipes.append((recipe, score))

        # Сортируем по убыванию оценки
        recipes.sort(key=lambda x: x[1], reverse=True)

        # Берём топ-10 рецептов
        top_recipes = [r[0] for r in recipes[:10]]

        serializer = self.get_serializer(top_recipes, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def favorites(self, request):
        """Избранные рецепты пользователя"""
        favorite_recipes = Recipe.objects.filter(
            favorited_by__fvr_usr_id=request.user
        )

        serializer = self.get_serializer(favorite_recipes, many=True)
        return Response(serializer.data)


class StepViewSet(viewsets.ReadOnlyModelViewSet):
    """API для доступа к шагам рецептов"""
    queryset = Step.objects.all()
    serializer_class = StepSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Фильтрация шагов по рецепту"""
        queryset = super().get_queryset()
        recipe_id = self.request.query_params.get('recipe_id')
        if recipe_id:
            queryset = queryset.filter(stp_rcp_id=recipe_id)
        return queryset


class FavoriteRecipeViewSet(CacheInvalidationMixin, viewsets.ModelViewSet):
    cache_prefix = 'favorite_recipe'
    """API для управления избранными рецептами"""
    serializer_class = FavoriteRecipeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает избранные рецепты текущего пользователя"""
        return FavoriteRecipe.objects.filter(fvr_usr_id=self.request.user)

    def create(self, request, *args, **kwargs):
        """Добавление рецепта в избранное"""
        if 'fvr_rcp_id' not in request.data:
            return Response(
                {"error": "Необходимо указать ID рецепта"},
                status=status.HTTP_400_BAD_REQUEST
            )

        recipe_id = request.data['fvr_rcp_id']

        # Проверка, существует ли уже такой рецепт в избранном
        if FavoriteRecipe.objects.filter(fvr_usr_id=request.user, fvr_rcp_id=recipe_id).exists():
            return Response(
                {"error": "Этот рецепт уже в избранном"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Создание связи
        favorite = FavoriteRecipe.objects.create(
            fvr_usr_id=request.user,
            fvr_rcp_id_id=recipe_id
        )

        serializer = self.get_serializer(favorite)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def destroy(self, request, *args, **kwargs):
        """Удаление рецепта из избранного"""
        instance = self.get_object()

        # Проверка, принадлежит ли связь текущему пользователю
        if instance.fvr_usr_id != request.user:
            return Response(
                {"error": "У вас нет прав на удаление этого рецепта из избранного"},
                status=status.HTTP_403_FORBIDDEN
            )

        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['delete'])
    def remove(self, request):
        """Удаление рецепта из избранного по ID рецепта"""
        if 'fvr_rcp_id' not in request.data:
            return Response(
                {"error": "Необходимо указать ID рецепта"},
                status=status.HTTP_400_BAD_REQUEST
            )

        recipe_id = request.data['fvr_rcp_id']

        # Находим запись и удаляем
        try:
            favorite = FavoriteRecipe.objects.get(
                fvr_usr_id=request.user,
                fvr_rcp_id_id=recipe_id
            )
            favorite.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except FavoriteRecipe.DoesNotExist:
            return Response(
                {"error": "Рецепт не найден в избранном"},
                status=status.HTTP_404_NOT_FOUND
            )