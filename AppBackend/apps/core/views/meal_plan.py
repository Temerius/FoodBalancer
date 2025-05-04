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

import logging
import time

# Создаем логгер для модуля планов питания
logger = logging.getLogger('apps.core.meal_plan')


class MealPlanViewSet(CacheInvalidationMixin, viewsets.ModelViewSet):
    cache_prefix = 'meal_plan'
    """API для доступа к недельным планам питания"""
    serializer_class = WeaklyMealPlanSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает планы питания текущего пользователя"""
        user_id = self.request.user.usr_id
        logger.debug(f"Getting meal plans for user_id={user_id}")
        return WeaklyMealPlan.objects.filter(wmp_usr_id=self.request.user)

    def perform_create(self, serializer):
        """Привязка плана питания к текущему пользователю"""
        user_id = self.request.user.usr_id
        logger.info(f"Creating new meal plan for user_id={user_id}")
        serializer.save(wmp_usr_id=self.request.user)

    def list(self, request, *args, **kwargs):
        """Получение списка планов питания"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Listing meal plans for user_id={user_id}")

        response = super().list(request, *args, **kwargs)
        count = response.data['count'] if 'count' in response.data else 'unknown'
        logger.info(f"Retrieved {count} meal plans for user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response

    def retrieve(self, request, *args, **kwargs):
        """Получение конкретного плана питания"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        plan_id = instance.wmp_id

        logger.info(f"Retrieving meal plan: plan_id={plan_id}, user_id={user_id}")
        response = super().retrieve(request, *args, **kwargs)
        logger.info(f"Retrieved meal plan: plan_id={plan_id}, user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response

    def create(self, request, *args, **kwargs):
        """Создание нового плана питания"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Creating meal plan: user_id={user_id}")

        response = super().create(request, *args, **kwargs)

        if response.status_code == status.HTTP_201_CREATED:
            plan_id = response.data['wmp_id']
            logger.info(
                f"Meal plan created successfully: plan_id={plan_id}, user_id={user_id}, time={time.time() - start_time:.2f}s")
        else:
            logger.warning(
                f"Failed to create meal plan: user_id={user_id}, status={response.status_code}, time={time.time() - start_time:.2f}s")

        return response

    def update(self, request, *args, **kwargs):
        """Обновление плана питания"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        plan_id = instance.wmp_id

        logger.info(f"Updating meal plan: plan_id={plan_id}, user_id={user_id}")
        response = super().update(request, *args, **kwargs)

        if response.status_code == status.HTTP_200_OK:
            logger.info(
                f"Meal plan updated successfully: plan_id={plan_id}, user_id={user_id}, time={time.time() - start_time:.2f}s")
        else:
            logger.warning(
                f"Failed to update meal plan: plan_id={plan_id}, user_id={user_id}, status={response.status_code}, time={time.time() - start_time:.2f}s")

        return response

    def destroy(self, request, *args, **kwargs):
        """Удаление плана питания"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        plan_id = instance.wmp_id

        logger.info(f"Deleting meal plan: plan_id={plan_id}, user_id={user_id}")
        response = super().destroy(request, *args, **kwargs)
        logger.info(f"Meal plan deleted: plan_id={plan_id}, user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response

    @action(detail=False, methods=['get'])
    def current(self, request):
        """Получить текущий план питания пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id
        today = datetime.now().date()

        logger.info(f"Getting current meal plan for user_id={user_id}, date={today}")

        try:
            current_plan = WeaklyMealPlan.objects.get(
                wmp_usr_id=request.user,
                wmp_start__lte=today,
                wmp_end__gte=today
            )
            logger.info(
                f"Found current meal plan: plan_id={current_plan.wmp_id}, user_id={user_id}, time={time.time() - start_time:.2f}s")
            serializer = self.get_serializer(current_plan)
            return Response(serializer.data)
        except WeaklyMealPlan.DoesNotExist:
            logger.warning(f"No current meal plan found for user_id={user_id}, time={time.time() - start_time:.2f}s")
            return Response(
                {"error": "Текущий план питания не найден"},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=True, methods=['get'])
    def days(self, request, pk=None):
        """Получить дневные планы питания для конкретного недельного плана"""
        start_time = time.time()
        weekly_plan = self.get_object()
        user_id = request.user.usr_id
        plan_id = weekly_plan.wmp_id

        # Проверка, принадлежит ли план текущему пользователю
        if weekly_plan.wmp_usr_id != request.user:
            logger.warning(
                f"Unauthorized access attempt to meal plan: plan_id={plan_id}, requested_by={user_id}, owner={weekly_plan.wmp_usr_id.usr_id}")
            return Response(
                {"error": "У вас нет прав на просмотр этого плана питания"},
                status=status.HTTP_403_FORBIDDEN
            )

        logger.info(f"Getting daily plans for weekly plan: plan_id={plan_id}, user_id={user_id}")
        daily_plans = DailyMealPlan.objects.filter(dmp_wmp_id=weekly_plan)
        count = daily_plans.count()

        serializer = DailyMealPlanSerializer(daily_plans, many=True, context=self.get_serializer_context())
        logger.info(
            f"Retrieved {count} daily plans for weekly plan: plan_id={plan_id}, user_id={user_id}, time={time.time() - start_time:.2f}s")

        return Response({
            "count": count,
            "results": serializer.data
        })


class DailyMealPlanViewSet(CacheInvalidationMixin, viewsets.ModelViewSet):
    cache_prefix = 'daily_plan'
    """API для доступа к дневным планам питания"""
    serializer_class = DailyMealPlanSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает дневные планы питания, доступные текущему пользователю"""
        user_id = self.request.user.usr_id
        logger.debug(f"Getting daily meal plans for user_id={user_id}")
        return DailyMealPlan.objects.filter(dmp_wmp_id__wmp_usr_id=self.request.user)

    def get_serializer_context(self):
        """Добавление request в контекст сериализатора"""
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context

    def retrieve(self, request, *args, **kwargs):
        """Получение конкретного дневного плана"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        plan_id = instance.dmp_id
        date = instance.dmp_date

        logger.info(f"Retrieving daily meal plan: plan_id={plan_id}, date={date}, user_id={user_id}")
        response = super().retrieve(request, *args, **kwargs)
        logger.info(
            f"Retrieved daily meal plan: plan_id={plan_id}, date={date}, user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response

    @action(detail=True, methods=['get'])
    def meals(self, request, pk=None):
        """Получить фактические приемы пищи для конкретного дня"""
        start_time = time.time()
        daily_plan = self.get_object()
        user_id = request.user.usr_id
        plan_id = daily_plan.dmp_id
        date = daily_plan.dmp_date

        # Проверка, принадлежит ли план текущему пользователю
        if daily_plan.dmp_wmp_id.wmp_usr_id != request.user:
            logger.warning(
                f"Unauthorized access attempt to daily plan: plan_id={plan_id}, requested_by={user_id}, owner={daily_plan.dmp_wmp_id.wmp_usr_id.usr_id}")
            return Response(
                {"error": "У вас нет прав на просмотр этого дня"},
                status=status.HTTP_403_FORBIDDEN
            )

        logger.info(f"Getting meals for daily plan: plan_id={plan_id}, date={date}, user_id={user_id}")
        meals = ActualDayMeal.objects.filter(
            adm_usr_id=request.user,
            adm_date=daily_plan.dmp_date
        )
        count = meals.count()

        serializer = ActualDayMealSerializer(meals, many=True, context=self.get_serializer_context())
        logger.info(
            f"Retrieved {count} meals for daily plan: plan_id={plan_id}, date={date}, user_id={user_id}, time={time.time() - start_time:.2f}s")

        return Response({
            "count": count,
            "results": serializer.data
        })


class ActualMealViewSet(CacheInvalidationMixin, viewsets.ModelViewSet):
    cache_prefix = 'actual_meal'
    """API для доступа к фактическим приемам пищи"""
    serializer_class = ActualDayMealSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает фактические приемы пищи текущего пользователя"""
        user_id = self.request.user.usr_id
        logger.debug(f"Getting actual meals for user_id={user_id}")
        return ActualDayMeal.objects.filter(adm_usr_id=self.request.user)

    def perform_create(self, serializer):
        """Привязка приема пищи к текущему пользователю"""
        user_id = self.request.user.usr_id
        logger.info(f"Creating new actual meal for user_id={user_id}")
        serializer.save(adm_usr_id=self.request.user)

    def create(self, request, *args, **kwargs):
        """Создание нового приема пищи"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Creating actual meal: user_id={user_id}, data={request.data}")

        meal_type = request.data.get('adm_type', 'unknown')
        meal_date = request.data.get('adm_date', 'unknown')

        response = super().create(request, *args, **kwargs)

        if response.status_code == status.HTTP_201_CREATED:
            meal_id = response.data['adm_id']
            logger.info(
                f"Actual meal created successfully: meal_id={meal_id}, type={meal_type}, date={meal_date}, user_id={user_id}, time={time.time() - start_time:.2f}s")
        else:
            logger.warning(
                f"Failed to create actual meal: type={meal_type}, date={meal_date}, user_id={user_id}, status={response.status_code}, time={time.time() - start_time:.2f}s")

        return response

    def update(self, request, *args, **kwargs):
        """Обновление приема пищи"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        meal_id = instance.adm_id

        logger.info(f"Updating actual meal: meal_id={meal_id}, user_id={user_id}")
        response = super().update(request, *args, **kwargs)

        if response.status_code == status.HTTP_200_OK:
            logger.info(
                f"Actual meal updated successfully: meal_id={meal_id}, user_id={user_id}, time={time.time() - start_time:.2f}s")
        else:
            logger.warning(
                f"Failed to update actual meal: meal_id={meal_id}, user_id={user_id}, status={response.status_code}, time={time.time() - start_time:.2f}s")

        return response

    def destroy(self, request, *args, **kwargs):
        """Удаление приема пищи"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        meal_id = instance.adm_id

        logger.info(f"Deleting actual meal: meal_id={meal_id}, user_id={user_id}")
        response = super().destroy(request, *args, **kwargs)
        logger.info(f"Actual meal deleted: meal_id={meal_id}, user_id={user_id}, time={time.time() - start_time:.2f}s")

        return response

    @action(detail=True, methods=['get'])
    def recipes(self, request, pk=None):
        """Получить рецепты для конкретного приема пищи"""
        start_time = time.time()
        meal = self.get_object()
        user_id = request.user.usr_id
        meal_id = meal.adm_id
        meal_type = meal.adm_type or 'unknown'

        # Проверка, принадлежит ли прием пищи текущему пользователю
        if meal.adm_usr_id != request.user:
            logger.warning(
                f"Unauthorized access attempt to meal: meal_id={meal_id}, requested_by={user_id}, owner={meal.adm_usr_id.usr_id}")
            return Response(
                {"error": "У вас нет прав на просмотр этого приема пищи"},
                status=status.HTTP_403_FORBIDDEN
            )

        logger.info(f"Getting recipes for meal: meal_id={meal_id}, type={meal_type}, user_id={user_id}")
        meal_recipes = M2MRcpAdm.objects.filter(mra_adm_id=meal)
        count = meal_recipes.count()

        serializer = MealRecipeSerializer(meal_recipes, many=True)
        logger.info(
            f"Retrieved {count} recipes for meal: meal_id={meal_id}, type={meal_type}, user_id={user_id}, time={time.time() - start_time:.2f}s")

        return Response({
            "count": count,
            "results": serializer.data
        })

    @action(detail=True, methods=['post'])
    def add_recipe(self, request, pk=None):
        """Добавление рецепта к приему пищи"""
        start_time = time.time()
        meal = self.get_object()
        user_id = request.user.usr_id
        meal_id = meal.adm_id
        meal_type = meal.adm_type or 'unknown'

        # Проверка, принадлежит ли прием пищи текущему пользователю
        if meal.adm_usr_id != request.user:
            logger.warning(
                f"Unauthorized recipe add attempt to meal: meal_id={meal_id}, requested_by={user_id}, owner={meal.adm_usr_id.usr_id}")
            return Response(
                {"error": "У вас нет прав на изменение этого приема пищи"},
                status=status.HTTP_403_FORBIDDEN
            )

        if 'recipe_id' not in request.data:
            logger.warning(f"Missing recipe ID in add request: meal_id={meal_id}, user_id={user_id}")
            return Response(
                {"error": "Необходимо указать ID рецепта"},
                status=status.HTTP_400_BAD_REQUEST
            )

        recipe_id = request.data['recipe_id']
        logger.info(f"Adding recipe to meal: meal_id={meal_id}, recipe_id={recipe_id}, user_id={user_id}")

        # Проверка, существует ли уже такой рецепт в приеме пищи
        if M2MRcpAdm.objects.filter(mra_adm_id=meal, mra_rcp_id=recipe_id).exists():
            logger.info(f"Recipe already in meal: meal_id={meal_id}, recipe_id={recipe_id}, user_id={user_id}")
            return Response(
                {"error": "Этот рецепт уже добавлен к приему пищи"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Создание связи
        M2MRcpAdm.objects.create(mra_adm_id=meal, mra_rcp_id_id=recipe_id)
        logger.info(
            f"Recipe added to meal: meal_id={meal_id}, recipe_id={recipe_id}, user_id={user_id}, time={time.time() - start_time:.2f}s")

        return Response({"success": True}, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def remove_recipe(self, request, pk=None):
        """Удаление рецепта из приема пищи"""
        start_time = time.time()
        meal = self.get_object()
        user_id = request.user.usr_id
        meal_id = meal.adm_id
        meal_type = meal.adm_type or 'unknown'

        # Проверка, принадлежит ли прием пищи текущему пользователю
        if meal.adm_usr_id != request.user:
            logger.warning(
                f"Unauthorized recipe remove attempt from meal: meal_id={meal_id}, requested_by={user_id}, owner={meal.adm_usr_id.usr_id}")
            return Response(
                {"error": "У вас нет прав на изменение этого приема пищи"},
                status=status.HTTP_403_FORBIDDEN
            )

        if 'recipe_id' not in request.data:
            logger.warning(f"Missing recipe ID in remove request: meal_id={meal_id}, user_id={user_id}")
            return Response(
                {"error": "Необходимо указать ID рецепта"},
                status=status.HTTP_400_BAD_REQUEST
            )

        recipe_id = request.data['recipe_id']
        logger.info(f"Removing recipe from meal: meal_id={meal_id}, recipe_id={recipe_id}, user_id={user_id}")

        # Удаление связи
        try:
            meal_recipe = M2MRcpAdm.objects.get(mra_adm_id=meal, mra_rcp_id=recipe_id)
            meal_recipe.delete()
            logger.info(
                f"Recipe removed from meal: meal_id={meal_id}, recipe_id={recipe_id}, user_id={user_id}, time={time.time() - start_time:.2f}s")
            return Response(status=status.HTTP_204_NO_CONTENT)
        except M2MRcpAdm.DoesNotExist:
            logger.warning(f"Recipe not found in meal: meal_id={meal_id}, recipe_id={recipe_id}, user_id={user_id}")
            return Response(
                {"error": "Рецепт не найден в этом приеме пищи"},
                status=status.HTTP_404_NOT_FOUND
            )