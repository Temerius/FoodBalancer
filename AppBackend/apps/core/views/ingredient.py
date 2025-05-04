# AppBackend/apps/core/views/ingredient.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q
from datetime import datetime, timedelta

from ..mixins import CacheInvalidationMixin
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page

from ..models import IngredientType, Ingredient, M2MUsrIng
from ..serializers import IngredientTypeSerializer, IngredientSerializer, IngredientDetailSerializer, \
    UserIngredientSerializer

import logging
import time

# Создаем логгер для модуля ингредиентов
logger = logging.getLogger('apps.core.refrigerator')


class IngredientTypeViewSet(viewsets.ReadOnlyModelViewSet):
    """API для доступа к типам ингредиентов"""
    queryset = IngredientType.objects.all()
    serializer_class = IngredientTypeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Фильтрация типов ингредиентов по категории или названию"""
        start_time = time.time()
        queryset = IngredientType.objects.all()

        # Фильтрация по категории
        category = self.request.query_params.get('category')
        if category:
            logger.debug(f"Filtering ingredient types by category: {category}")
            queryset = queryset.filter(category=category)

        # Поиск по названию
        search = self.request.query_params.get('search')
        if search:
            logger.info(f"Searching ingredient types: query='{search}', user_id={self.request.user.usr_id}")
            queryset = queryset.filter(igt_name__icontains=search)

        query_time = time.time() - start_time
        if query_time > 0.5:  # Логируем долгие запросы
            logger.warning(f"Slow ingredient type query: {query_time:.2f}s, params={self.request.query_params}")

        return queryset

    def list(self, request, *args, **kwargs):
        """Получение списка типов ингредиентов"""
        start_time = time.time()
        logger.info(f"Listing ingredient types: user_id={request.user.usr_id}, params={request.query_params}")
        response = super().list(request, *args, **kwargs)
        logger.debug(
            f"Retrieved {response.data['count'] if 'count' in response.data else 'unknown'} ingredient types in {time.time() - start_time:.2f}s")
        return response


class IngredientViewSet(viewsets.ReadOnlyModelViewSet):
    """API для доступа к ингредиентам"""
    queryset = Ingredient.objects.all()
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        """Выбор сериализатора в зависимости от действия"""
        if self.action == 'retrieve':
            return IngredientDetailSerializer
        return IngredientSerializer

    def get_queryset(self):
        """Фильтрация ингредиентов по типу или названию"""
        start_time = time.time()
        queryset = Ingredient.objects.all()

        # Фильтрация по типу
        type_id = self.request.query_params.get('type_id')
        if type_id:
            logger.debug(f"Filtering ingredients by type: {type_id}")
            queryset = queryset.filter(ing_igt_id=type_id)

        # Поиск по названию
        search = self.request.query_params.get('search')
        if search:
            logger.info(f"Searching ingredients: query='{search}', user_id={self.request.user.usr_id}")
            queryset = queryset.filter(ing_name__icontains=search)

        query_time = time.time() - start_time
        if query_time > 0.5:  # Логируем долгие запросы
            logger.warning(f"Slow ingredient query: {query_time:.2f}s, params={self.request.query_params}")

        return queryset

    def list(self, request, *args, **kwargs):
        """Получение списка ингредиентов"""
        start_time = time.time()
        user_id = request.user.usr_id
        search = request.query_params.get('search', '')
        type_id = request.query_params.get('type_id', '')

        log_params = f"search='{search}'" if search else ""
        log_params += f", type_id={type_id}" if type_id else ""
        logger.info(f"Listing ingredients: user_id={user_id}{', ' + log_params if log_params else ''}")

        response = super().list(request, *args, **kwargs)
        count = response.data['count'] if 'count' in response.data else 'unknown'
        logger.info(f"Retrieved {count} ingredients for user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response

    def retrieve(self, request, *args, **kwargs):
        """Получение конкретного ингредиента"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        ingredient_id = instance.ing_id

        logger.info(f"Retrieving ingredient: ingredient_id={ingredient_id}, user_id={user_id}")
        response = super().retrieve(request, *args, **kwargs)
        logger.info(
            f"Retrieved ingredient: ingredient_id={ingredient_id}, name='{instance.ing_name}', user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response


class RefrigeratorViewSet(CacheInvalidationMixin, viewsets.ModelViewSet):
    cache_prefix = 'refrigerator'
    """API для доступа к холодильнику пользователя (ингредиенты пользователя)"""
    serializer_class = UserIngredientSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает ингредиенты текущего пользователя"""
        user_id = self.request.user.usr_id
        logger.debug(f"Accessing refrigerator: user_id={user_id}")
        return M2MUsrIng.objects.filter(mui_usr_id=self.request.user)

    def list(self, request, *args, **kwargs):
        """Получение списка ингредиентов пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Listing refrigerator ingredients: user_id={user_id}")

        response = super().list(request, *args, **kwargs)
        count = response.data['count'] if 'count' in response.data else 'unknown'
        logger.info(
            f"Retrieved {count} refrigerator ingredients for user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response

    def create(self, request, *args, **kwargs):
        """Добавление ингредиента в холодильник пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id

        logger.info(f"Adding ingredient to refrigerator: user_id={user_id}")

        if not all(k in request.data for k in ('mui_ing_id', 'mui_quantity', 'mui_quantity_type')):
            logger.warning(f"Missing required fields for ingredient: user_id={user_id}, data={request.data}")
            return Response(
                {"error": "Необходимо указать ингредиент, количество и единицу измерения"},
                status=status.HTTP_400_BAD_REQUEST
            )

        ingredient_id = request.data['mui_ing_id']

        # Проверка, существует ли уже такой ингредиент у пользователя
        if M2MUsrIng.objects.filter(mui_usr_id=request.user, mui_ing_id=ingredient_id).exists():
            logger.info(f"Ingredient already in refrigerator: ingredient_id={ingredient_id}, user_id={user_id}")
            return Response(
                {"error": "Этот ингредиент уже есть в холодильнике"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Создание связи
        try:
            ingredient = Ingredient.objects.get(ing_id=ingredient_id)
            quantity = request.data['mui_quantity']
            quantity_type = request.data['mui_quantity_type']

            refrigerator_item = M2MUsrIng.objects.create(
                mui_usr_id=request.user,
                mui_ing_id_id=ingredient_id,
                mui_quantity=quantity,
                mui_quantity_type=quantity_type
            )

            logger.info(
                f"Ingredient added to refrigerator: ingredient_id={ingredient_id}, name='{ingredient.ing_name}', "
                f"quantity={quantity} {quantity_type}, user_id={user_id}, time={time.time() - start_time:.2f}s")
            serializer = self.get_serializer(refrigerator_item)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except Ingredient.DoesNotExist:
            logger.warning(f"Ingredient not found: ingredient_id={ingredient_id}, user_id={user_id}")
            return Response(
                {"error": "Указанный ингредиент не существует"},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(
                f"Error adding ingredient to refrigerator: ingredient_id={ingredient_id}, user_id={user_id}, error: {str(e)}",
                exc_info=True)
            return Response(
                {"error": f"Произошла ошибка: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def update(self, request, *args, **kwargs):
        """Обновление ингредиента в холодильнике"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        ingredient_id = instance.mui_ing_id.ing_id
        ingredient_name = instance.mui_ing_id.ing_name

        # Проверка, принадлежит ли ингредиент текущему пользователю
        if instance.mui_usr_id != request.user:
            logger.warning(
                f"Unauthorized refrigerator update attempt: ingredient_id={ingredient_id}, requested_by={user_id}, owner={instance.mui_usr_id.usr_id}")
            return Response(
                {"error": "У вас нет прав на редактирование этого ингредиента"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Сохраняем старые значения для лога
        old_quantity = instance.mui_quantity
        old_quantity_type = instance.mui_quantity_type

        logger.info(
            f"Updating refrigerator ingredient: ingredient_id={ingredient_id}, name='{ingredient_name}', user_id={user_id}")
        response = super().update(request, *args, **kwargs)

        # Логируем изменения
        if response.status_code == status.HTTP_200_OK:
            new_quantity = response.data.get('mui_quantity', old_quantity)
            new_quantity_type = response.data.get('mui_quantity_type', old_quantity_type)

            changes = []
            if old_quantity != new_quantity:
                changes.append(f"quantity: {old_quantity} -> {new_quantity}")
            if old_quantity_type != new_quantity_type:
                changes.append(f"type: {old_quantity_type} -> {new_quantity_type}")

            if changes:
                logger.info(
                    f"Refrigerator ingredient updated: ingredient_id={ingredient_id}, name='{ingredient_name}', "
                    f"changes: {', '.join(changes)}, user_id={user_id}, time={time.time() - start_time:.2f}s")
            else:
                logger.info(
                    f"Refrigerator ingredient update called but no changes made: ingredient_id={ingredient_id}, user_id={user_id}")
        else:
            logger.warning(
                f"Failed to update refrigerator ingredient: ingredient_id={ingredient_id}, user_id={user_id}, status={response.status_code}")

        return response

    def destroy(self, request, *args, **kwargs):
        """Удаление ингредиента из холодильника"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        ingredient_id = instance.mui_ing_id.ing_id
        ingredient_name = instance.mui_ing_id.ing_name

        # Проверка, принадлежит ли ингредиент текущему пользователю
        if instance.mui_usr_id != request.user:
            logger.warning(
                f"Unauthorized refrigerator delete attempt: ingredient_id={ingredient_id}, requested_by={user_id}, owner={instance.mui_usr_id.usr_id}")
            return Response(
                {"error": "У вас нет прав на удаление этого ингредиента"},
                status=status.HTTP_403_FORBIDDEN
            )

        logger.info(
            f"Removing ingredient from refrigerator: ingredient_id={ingredient_id}, name='{ingredient_name}', user_id={user_id}")
        self.perform_destroy(instance)
        logger.info(
            f"Ingredient removed from refrigerator: ingredient_id={ingredient_id}, name='{ingredient_name}', user_id={user_id}, time={time.time() - start_time:.2f}s")
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        """Получить ингредиенты с истекающим сроком годности (в течение 3 дней)"""
        start_time = time.time()
        user_id = request.user.usr_id

        logger.info(f"Checking expiring ingredients: user_id={user_id}")

        now = datetime.now().date()
        future = now + timedelta(days=3)

        # Получаем ингредиенты пользователя
        user_ingredients = M2MUsrIng.objects.filter(mui_usr_id=request.user).select_related('mui_ing_id')

        # Фильтруем по сроку годности
        expiring_items = []
        for item in user_ingredients:
            if item.mui_ing_id.ing_exp_date and now <= item.mui_ing_id.ing_exp_date <= future:
                expiring_items.append(item)

        count = len(expiring_items)
        logger.info(f"Found {count} expiring ingredients for user_id={user_id}, time={time.time() - start_time:.2f}s")

        serializer = self.get_serializer(expiring_items, many=True)
        return Response(serializer.data)