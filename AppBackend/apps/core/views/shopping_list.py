# AppBackend/apps/core/views/shopping_list.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from ..models import ShoppingList, M2MIngSpl, IngredientType
from ..serializers import ShoppingListSerializer, ShoppingListItemSerializer

import logging
import time

# Создаем логгер для списка покупок
logger = logging.getLogger('apps.core.shopping')


class ShoppingListViewSet(viewsets.ModelViewSet):
    cache_prefix = 'shopping_list'
    """API для доступа к списку покупок"""
    serializer_class = ShoppingListSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает список покупок текущего пользователя"""
        logger.debug(f"Accessing shopping list: user_id={self.request.user.usr_id}")
        return ShoppingList.objects.filter(spl_usr_id=self.request.user)

    def get_object(self):
        """Получить текущий список покупок пользователя или создать новый"""
        user_id = self.request.user.usr_id
        logger.debug(f"Getting shopping list object: user_id={user_id}")

        try:
            return ShoppingList.objects.get(spl_usr_id=self.request.user)
        except ShoppingList.DoesNotExist:
            logger.info(f"Creating new shopping list for user_id={user_id}")
            return ShoppingList.objects.create(spl_usr_id=self.request.user)

    @action(detail=True, methods=['get'])
    def items(self, request, pk=None):
        """Получить элементы списка покупок"""
        start_time = time.time()
        shopping_list = self.get_object()
        user_id = request.user.usr_id

        # Получаем все элементы или только невыполненные
        only_unchecked = request.query_params.get('unchecked', 'false').lower() == 'true'

        if only_unchecked:
            logger.info(f"Getting unchecked shopping list items: user_id={user_id}")
            items = M2MIngSpl.objects.filter(mis_spl_id=shopping_list, is_checked=False)
        else:
            logger.info(f"Getting all shopping list items: user_id={user_id}")
            items = M2MIngSpl.objects.filter(mis_spl_id=shopping_list)

        item_count = items.count()
        logger.info(
            f"Retrieved {item_count} shopping list items for user_id={user_id}, time={time.time() - start_time:.2f}s")
        serializer = ShoppingListItemSerializer(items, many=True)

        return Response({
            "count": item_count,
            "results": serializer.data
        })

    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        """Добавление элемента в список покупок"""
        start_time = time.time()
        shopping_list = self.get_object()
        user_id = request.user.usr_id

        logger.info(f"Adding item to shopping list: user_id={user_id}")

        if not all(k in request.data for k in ('mis_igt_id', 'mis_quantity', 'mis_quantity_type')):
            logger.warning(f"Missing required fields for shopping list item: user_id={user_id}, data={request.data}")
            return Response(
                {"error": "Необходимо указать тип ингредиента, количество и единицу измерения"},
                status=status.HTTP_400_BAD_REQUEST
            )

        ingredient_type_id = request.data['mis_igt_id']

        # Проверяем существование типа ингредиента
        try:
            ingredient_type = IngredientType.objects.get(igt_id=ingredient_type_id)
            logger.debug(f"Found ingredient type: {ingredient_type.igt_name}")
        except IngredientType.DoesNotExist:
            logger.warning(f"Invalid ingredient type: type_id={ingredient_type_id}, user_id={user_id}")
            return Response(
                {"error": "Указанный тип ингредиента не существует"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Проверка, существует ли уже такой элемент в списке
        existing_item = M2MIngSpl.objects.filter(
            mis_spl_id=shopping_list,
            mis_igt_id=ingredient_type_id,
            mis_quantity_type=request.data['mis_quantity_type']
        ).first()

        if existing_item:
            # Обновляем количество существующего элемента
            old_quantity = existing_item.mis_quantity
            existing_item.mis_quantity += int(request.data['mis_quantity'])
            existing_item.is_checked = False  # Сбрасываем статус "выполнено"
            existing_item.save()
            logger.info(
                f"Updated existing item quantity: item_id={existing_item.mis_id}, type='{ingredient_type.igt_name}', "
                f"old_quantity={old_quantity}, new_quantity={existing_item.mis_quantity}, user_id={user_id}")
            serializer = ShoppingListItemSerializer(existing_item)
            return Response(serializer.data, status=status.HTTP_200_OK)

        # Создание нового элемента
        quantity = int(request.data['mis_quantity'])
        quantity_type = request.data['mis_quantity_type']

        item = M2MIngSpl.objects.create(
            mis_spl_id=shopping_list,
            mis_igt_id_id=ingredient_type_id,
            mis_quantity=quantity,
            mis_quantity_type=quantity_type,
            is_checked=False
        )

        logger.info(f"Added new item to shopping list: item_id={item.mis_id}, type='{ingredient_type.igt_name}', "
                    f"quantity={quantity} {quantity_type}, user_id={user_id}, time={time.time() - start_time:.2f}s")
        serializer = ShoppingListItemSerializer(item)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def update_item(self, request, pk=None):
        """Обновление элемента списка покупок"""
        start_time = time.time()
        shopping_list = self.get_object()
        user_id = request.user.usr_id

        if 'item_id' not in request.data:
            logger.warning(f"Missing item ID in update request: user_id={user_id}")
            return Response(
                {"error": "Необходимо указать ID элемента"},
                status=status.HTTP_400_BAD_REQUEST
            )

        item_id = request.data['item_id']
        logger.info(f"Updating shopping list item: item_id={item_id}, user_id={user_id}")

        try:
            item = M2MIngSpl.objects.get(mis_id=item_id, mis_spl_id=shopping_list)
        except M2MIngSpl.DoesNotExist:
            logger.warning(f"Item not found in shopping list: item_id={item_id}, user_id={user_id}")
            return Response(
                {"error": "Элемент не найден в списке покупок"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Сохраняем старые значения для лога
        old_quantity = item.mis_quantity
        old_quantity_type = item.mis_quantity_type
        old_is_checked = item.is_checked

        # Обновление данных
        if 'mis_quantity' in request.data:
            item.mis_quantity = request.data['mis_quantity']

        if 'mis_quantity_type' in request.data:
            item.mis_quantity_type = request.data['mis_quantity_type']

        if 'is_checked' in request.data:
            item.is_checked = request.data['is_checked']

        item.save()

        # Логируем изменения
        changes = []
        if old_quantity != item.mis_quantity:
            changes.append(f"quantity: {old_quantity} -> {item.mis_quantity}")
        if old_quantity_type != item.mis_quantity_type:
            changes.append(f"type: {old_quantity_type} -> {item.mis_quantity_type}")
        if old_is_checked != item.is_checked:
            changes.append(f"checked: {old_is_checked} -> {item.is_checked}")

        if changes:
            logger.info(
                f"Item updated: item_id={item_id}, changes: {', '.join(changes)}, user_id={user_id}, time={time.time() - start_time:.2f}s")
        else:
            logger.info(f"Item update called but no changes made: item_id={item_id}, user_id={user_id}")

        serializer = ShoppingListItemSerializer(item)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def remove_item(self, request, pk=None):
        """Удаление элемента из списка покупок"""
        start_time = time.time()
        shopping_list = self.get_object()
        user_id = request.user.usr_id

        if 'item_id' not in request.data:
            logger.warning(f"Missing item ID in remove request: user_id={user_id}")
            return Response(
                {"error": "Необходимо указать ID элемента"},
                status=status.HTTP_400_BAD_REQUEST
            )

        item_id = request.data['item_id']
        logger.info(f"Removing item from shopping list: item_id={item_id}, user_id={user_id}")

        try:
            item = M2MIngSpl.objects.get(mis_id=item_id, mis_spl_id=shopping_list)
            item_type_name = item.mis_igt_id.igt_name
            item.delete()
            logger.info(
                f"Item removed from shopping list: item_id={item_id}, type='{item_type_name}', user_id={user_id}, time={time.time() - start_time:.2f}s")
            return Response(status=status.HTTP_204_NO_CONTENT)
        except M2MIngSpl.DoesNotExist:
            logger.warning(f"Item not found in shopping list: item_id={item_id}, user_id={user_id}")
            return Response(
                {"error": "Элемент не найден в списке покупок"},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=True, methods=['post'])
    def clear_checked(self, request, pk=None):
        """Удаление всех выполненных элементов из списка покупок"""
        start_time = time.time()
        shopping_list = self.get_object()
        user_id = request.user.usr_id

        logger.info(f"Clearing checked items from shopping list: user_id={user_id}")

        checked_count = M2MIngSpl.objects.filter(mis_spl_id=shopping_list, is_checked=True).count()
        deleted_count, _ = M2MIngSpl.objects.filter(mis_spl_id=shopping_list, is_checked=True).delete()

        logger.info(
            f"Cleared {deleted_count} checked items from shopping list: user_id={user_id}, time={time.time() - start_time:.2f}s")
        return Response(
            {"deleted_count": deleted_count},
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=['post'])
    def clear_all(self, request, pk=None):
        """Очистка всего списка покупок"""
        start_time = time.time()
        shopping_list = self.get_object()
        user_id = request.user.usr_id

        logger.info(f"Clearing all items from shopping list: user_id={user_id}")

        item_count_before = M2MIngSpl.objects.filter(mis_spl_id=shopping_list).count()
        deleted_count, _ = M2MIngSpl.objects.filter(mis_spl_id=shopping_list).delete()

        logger.info(
            f"Cleared all {deleted_count} items from shopping list: user_id={user_id}, time={time.time() - start_time:.2f}s")
        return Response(
            {"deleted_count": deleted_count},
            status=status.HTTP_200_OK
        )