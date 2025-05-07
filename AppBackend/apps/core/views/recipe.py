# AppBackend/apps/core/views/recipe.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q, Exists, OuterRef
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page

from ..models import (
    Recipe, Step, M2MStpIgt, FavoriteRecipe,
    IngredientType, Ingredient, M2MUsrIng,
    M2MIngAlg
)
from ..serializers import (
    RecipeListSerializer, RecipeDetailSerializer,
    StepSerializer, FavoriteRecipeSerializer
)

import logging
import time

# Создадим логгер для рецептов
logger = logging.getLogger('apps.core.recipes')

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
        start_time = time.time()
        queryset = Recipe.objects.all()

        # Поиск по названию или описанию
        search = self.request.query_params.get('search')
        if search:
            logger.info(f"Recipe search: user_id={self.request.user.usr_id}, query='{search}'")
            queryset = queryset.filter(
                Q(rcp_title__icontains=search) | Q(rcp_description__icontains=search)
            )

        query_time = time.time() - start_time
        if query_time > 0.5:  # Логируем долгие запросы
            logger.warning(f"Slow recipe query: {query_time:.2f}s, params={self.request.query_params}")
        else:
            logger.debug(f"Recipe query executed in {query_time:.2f}s")

        return queryset

    def list(self, request, *args, **kwargs):
        """Получение списка рецептов с логированием"""
        start_time = time.time()
        logger.info(f"Listing recipes: user_id={request.user.usr_id}, params={request.query_params}")
        response = super().list(request, *args, **kwargs)
        logger.debug(f"Recipe list retrieval time: {time.time() - start_time:.2f}s")
        return response

    def retrieve(self, request, *args, **kwargs):
        """Получение конкретного рецепта с логированием"""
        start_time = time.time()
        instance = self.get_object()
        logger.info(
            f"Recipe viewed: recipe_id={instance.rcp_id}, title='{instance.rcp_title}', user_id={request.user.usr_id}")
        response = super().retrieve(request, *args, **kwargs)
        logger.debug(f"Recipe retrieval time: {time.time() - start_time:.2f}s")
        return response

    @action(detail=False, methods=['get'])
    def recommended(self, request):
        """Рекомендуемые рецепты для пользователя"""
        start_time = time.time()
        logger.info(f"Requesting recommended recipes for user_id={request.user.usr_id}")

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
            logger.info(f"Excluding {len(excluded_ingredient_ids)} ingredients due to user allergens")

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

        processing_time = time.time() - start_time
        if processing_time > 1.0:  # Логируем медленную обработку
            logger.warning(f"Slow recommendation processing: {processing_time:.2f}s for user_id={request.user.usr_id}")

        logger.info(
            f"Recommended {len(top_recipes)} recipes for user_id={request.user.usr_id}, time={processing_time:.2f}s")
        serializer = self.get_serializer(top_recipes, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def favorites(self, request):
        """Избранные рецепты пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Getting favorite recipes for user_id={user_id}")

        favorite_recipes = Recipe.objects.filter(
            favorited_by__fvr_usr_id=request.user
        )

        count = favorite_recipes.count()
        logger.info(f"Retrieved {count} favorite recipes for user_id={user_id}, time={time.time() - start_time:.2f}s")
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
            logger.debug(f"Filtering steps for recipe_id={recipe_id}, user_id={self.request.user.usr_id}")
            queryset = queryset.filter(stp_rcp_id=recipe_id)
        return queryset

    def list(self, request, *args, **kwargs):
        """Получение списка шагов с логированием"""
        start_time = time.time()
        recipe_id = request.query_params.get('recipe_id')
        if recipe_id:
            logger.info(f"Listing steps for recipe_id={recipe_id}, user_id={request.user.usr_id}")
        else:
            logger.info(f"Listing all steps, user_id={request.user.usr_id}")

        response = super().list(request, *args, **kwargs)
        logger.debug(f"Steps list retrieval time: {time.time() - start_time:.2f}s")
        return response


class FavoriteRecipeViewSet(viewsets.ModelViewSet):
    cache_prefix = 'favorite_recipe'
    """API для управления избранными рецептами"""
    serializer_class = FavoriteRecipeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает избранные рецепты текущего пользователя"""
        return FavoriteRecipe.objects.filter(fvr_usr_id=self.request.user)

    def create(self, request, *args, **kwargs):
        """Добавление рецепта в избранное"""
        start_time = time.time()
        user_id = request.user.usr_id

        if 'fvr_rcp_id' not in request.data:
            logger.warning(f"Missing recipe ID in favorite add request: user_id={user_id}")
            return Response(
                {"error": "Необходимо указать ID рецепта"},
                status=status.HTTP_400_BAD_REQUEST
            )

        recipe_id = request.data['fvr_rcp_id']
        logger.info(f"Adding recipe to favorites: user_id={user_id}, recipe_id={recipe_id}")

        # Проверка, существует ли уже такой рецепт в избранном
        if FavoriteRecipe.objects.filter(fvr_usr_id=request.user, fvr_rcp_id=recipe_id).exists():
            logger.info(f"Recipe already in favorites: user_id={user_id}, recipe_id={recipe_id}")
            return Response(
                {"error": "Этот рецепт уже в избранном"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Создание связи
        favorite = FavoriteRecipe.objects.create(
            fvr_usr_id=request.user,
            fvr_rcp_id_id=recipe_id
        )

        logger.info(
            f"Recipe added to favorites: user_id={user_id}, recipe_id={recipe_id}, time={time.time() - start_time:.2f}s")
        serializer = self.get_serializer(favorite)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def destroy(self, request, *args, **kwargs):
        """Удаление рецепта из избранного"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        recipe_id = instance.fvr_rcp_id_id

        # Проверка, принадлежит ли связь текущему пользователю
        if instance.fvr_usr_id != request.user:
            logger.warning(
                f"Unauthorized favorite delete attempt: user_id={user_id}, recipe_id={recipe_id}, owner_id={instance.fvr_usr_id.usr_id}")
            return Response(
                {"error": "У вас нет прав на удаление этого рецепта из избранного"},
                status=status.HTTP_403_FORBIDDEN
            )

        logger.info(f"Removing recipe from favorites: user_id={user_id}, recipe_id={recipe_id}")
        self.perform_destroy(instance)
        logger.info(
            f"Recipe removed from favorites: user_id={user_id}, recipe_id={recipe_id}, time={time.time() - start_time:.2f}s")
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['delete'])
    def remove(self, request):
        """Удаление рецепта из избранного по ID рецепта"""
        start_time = time.time()
        user_id = request.user.usr_id

        if 'fvr_rcp_id' not in request.data:
            logger.warning(f"Missing recipe ID in favorite remove request: user_id={user_id}")
            return Response(
                {"error": "Необходимо указать ID рецепта"},
                status=status.HTTP_400_BAD_REQUEST
            )

        recipe_id = request.data['fvr_rcp_id']
        logger.info(f"Removing recipe from favorites by ID: user_id={user_id}, recipe_id={recipe_id}")

        # Находим запись и удаляем
        try:
            favorite = FavoriteRecipe.objects.get(
                fvr_usr_id=request.user,
                fvr_rcp_id_id=recipe_id
            )
            favorite.delete()
            logger.info(
                f"Recipe removed from favorites: user_id={user_id}, recipe_id={recipe_id}, time={time.time() - start_time:.2f}s")
            return Response(status=status.HTTP_204_NO_CONTENT)
        except FavoriteRecipe.DoesNotExist:
            logger.warning(f"Recipe not found in favorites: user_id={user_id}, recipe_id={recipe_id}")
            return Response(
                {"error": "Рецепт не найден в избранном"},
                status=status.HTTP_404_NOT_FOUND
            )