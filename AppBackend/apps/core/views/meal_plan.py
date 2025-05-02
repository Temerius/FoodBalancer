# AppBackend/apps/core/views/meal_plan.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q, Prefetch
from datetime import datetime, timedelta

from ..mixins import CacheInvalidationMixin
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page

from ..models import (
    WeaklyMealPlan, DailyMealPlan, ActualDayMeal,
    M2MRcpDmp, M2MRcpAdm, M2MIngDmp, M2MIngAdm
)
from ..serializers import (
    WeaklyMealPlanSerializer, DailyMealPlanSerializer,
    ActualDayMealSerializer, MealRecipeSerializer, MealIngredientSerializer
)


class MealPlanViewSet(CacheInvalidationMixin, viewsets.ModelViewSet):
    cache_prefix = 'meal_plan'
    """API для доступа к недельным планам питания"""
    serializer_class = WeaklyMealPlanSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает планы питания текущего пользователя"""
        return WeaklyMealPlan.objects.filter(wmp_usr_id=self.request.user)

    def perform_create(self, serializer):
        """Привязка плана питания к текущему пользователю"""
        serializer.save(wmp_usr_id=self.request.user)

    @action(detail=False, methods=['get'])
    def current(self, request):
        """Получить текущий план питания пользователя"""
        today = datetime.now().date()

        try:
            current_plan = WeaklyMealPlan.objects.get(
                wmp_usr_id=request.user,
                wmp_start__lte=today,
                wmp_end__gte=today
            )
            serializer = self.get_serializer(current_plan)
            return Response(serializer.data)
        except WeaklyMealPlan.DoesNotExist:
            return Response(
                {"error": "Текущий план питания не найден"},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=True, methods=['get'])
    def days(self, request, pk=None):
        """Получить дневные планы питания для конкретного недельного плана"""
        weekly_plan = self.get_object()

        # Проверка, принадлежит ли план текущему пользователю
        if weekly_plan.wmp_usr_id != request.user:
            return Response(
                {"error": "У вас нет прав на просмотр этого плана питания"},
                status=status.HTTP_403_FORBIDDEN
            )

        daily_plans = DailyMealPlan.objects.filter(dmp_wmp_id=weekly_plan)
        serializer = DailyMealPlanSerializer(daily_plans, many=True, context=self.get_serializer_context())

        return Response({
            "count": daily_plans.count(),
            "results": serializer.data
        })


class DailyMealPlanViewSet(CacheInvalidationMixin, viewsets.ModelViewSet):
    cache_prefix = 'daily_plan'
    """API для доступа к дневным планам питания"""
    serializer_class = DailyMealPlanSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает дневные планы питания, доступные текущему пользователю"""
        return DailyMealPlan.objects.filter(dmp_wmp_id__wmp_usr_id=self.request.user)

    def get_serializer_context(self):
        """Добавление request в контекст сериализатора"""
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context

    @action(detail=True, methods=['get'])
    def meals(self, request, pk=None):
        """Получить фактические приемы пищи для конкретного дня"""
        daily_plan = self.get_object()

        # Проверка, принадлежит ли план текущему пользователю
        if daily_plan.dmp_wmp_id.wmp_usr_id != request.user:
            return Response(
                {"error": "У вас нет прав на просмотр этого дня"},
                status=status.HTTP_403_FORBIDDEN
            )

        meals = ActualDayMeal.objects.filter(
            adm_usr_id=request.user,
            adm_date=daily_plan.dmp_date
        )
        serializer = ActualDayMealSerializer(meals, many=True, context=self.get_serializer_context())

        return Response({
            "count": meals.count(),
            "results": serializer.data
        })


class ActualMealViewSet(CacheInvalidationMixin, viewsets.ModelViewSet):
    cache_prefix = 'actual_meal'
    """API для доступа к фактическим приемам пищи"""
    serializer_class = ActualDayMealSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает фактические приемы пищи текущего пользователя"""
        return ActualDayMeal.objects.filter(adm_usr_id=self.request.user)

    def perform_create(self, serializer):
        """Привязка приема пищи к текущему пользователю"""
        serializer.save(adm_usr_id=self.request.user)

    @action(detail=True, methods=['get'])
    def recipes(self, request, pk=None):
        """Получить рецепты для конкретного приема пищи"""
        meal = self.get_object()

        # Проверка, принадлежит ли прием пищи текущему пользователю
        if meal.adm_usr_id != request.user:
            return Response(
                {"error": "У вас нет прав на просмотр этого приема пищи"},
                status=status.HTTP_403_FORBIDDEN
            )

        meal_recipes = M2MRcpAdm.objects.filter(mra_adm_id=meal)
        serializer = MealRecipeSerializer(meal_recipes, many=True)

        return Response({
            "count": meal_recipes.count(),
            "results": serializer.data
        })

    @action(detail=True, methods=['post'])
    def add_recipe(self, request, pk=None):
        """Добавление рецепта к приему пищи"""
        meal = self.get_object()

        # Проверка, принадлежит ли прием пищи текущему пользователю
        if meal.adm_usr_id != request.user:
            return Response(
                {"error": "У вас нет прав на изменение этого приема пищи"},
                status=status.HTTP_403_FORBIDDEN
            )

        if 'recipe_id' not in request.data:
            return Response(
                {"error": "Необходимо указать ID рецепта"},
                status=status.HTTP_400_BAD_REQUEST
            )

        recipe_id = request.data['recipe_id']

        # Проверка, существует ли уже такой рецепт в приеме пищи
        if M2MRcpAdm.objects.filter(mra_adm_id=meal, mra_rcp_id=recipe_id).exists():
            return Response(
                {"error": "Этот рецепт уже добавлен к приему пищи"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Создание связи
        M2MRcpAdm.objects.create(mra_adm_id=meal, mra_rcp_id_id=recipe_id)

        return Response({"success": True}, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def remove_recipe(self, request, pk=None):
        """Удаление рецепта из приема пищи"""
        meal = self.get_object()

        # Проверка, принадлежит ли прием пищи текущему пользователю
        if meal.adm_usr_id != request.user:
            return Response(
                {"error": "У вас нет прав на изменение этого приема пищи"},
                status=status.HTTP_403_FORBIDDEN
            )

        if 'recipe_id' not in request.data:
            return Response(
                {"error": "Необходимо указать ID рецепта"},
                status=status.HTTP_400_BAD_REQUEST
            )

        recipe_id = request.data['recipe_id']

        # Удаление связи
        try:
            meal_recipe = M2MRcpAdm.objects.get(mra_adm_id=meal, mra_rcp_id=recipe_id)
            meal_recipe.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except M2MRcpAdm.DoesNotExist:
            return Response(
                {"error": "Рецепт не найден в этом приеме пищи"},
                status=status.HTTP_404_NOT_FOUND
            )