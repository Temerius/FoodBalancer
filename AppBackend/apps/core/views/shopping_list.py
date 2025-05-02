# AppBackend/apps/core/views/shopping_list.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from ..models import ShoppingList, M2MIngSpl, IngredientType
from ..serializers import ShoppingListSerializer, ShoppingListItemSerializer

from ..mixins import CacheInvalidationMixin


class ShoppingListViewSet(CacheInvalidationMixin, viewsets.ModelViewSet):
    cache_prefix = 'shopping_list'
    """API для доступа к списку покупок"""
    serializer_class = ShoppingListSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает список покупок текущего пользователя"""
        return ShoppingList.objects.filter(spl_usr_id=self.request.user)

    def get_object(self):
        """Получить текущий список покупок пользователя или создать новый"""
        try:
            return ShoppingList.objects.get(spl_usr_id=self.request.user)
        except ShoppingList.DoesNotExist:
            return ShoppingList.objects.create(spl_usr_id=self.request.user)

    @action(detail=True, methods=['get'])
    def items(self, request, pk=None):
        """Получить элементы списка покупок"""
        shopping_list = self.get_object()

        # Получаем все элементы или только невыполненные
        only_unchecked = request.query_params.get('unchecked', 'false').lower() == 'true'

        if only_unchecked:
            items = M2MIngSpl.objects.filter(mis_spl_id=shopping_list, is_checked=False)
        else:
            items = M2MIngSpl.objects.filter(mis_spl_id=shopping_list)

        serializer = ShoppingListItemSerializer(items, many=True)

        return Response({
            "count": items.count(),
            "results": serializer.data
        })

    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        """Добавление элемента в список покупок"""
        shopping_list = self.get_object()

        if not all(k in request.data for k in ('mis_igt_id', 'mis_quantity', 'mis_quantity_type')):
            return Response(
                {"error": "Необходимо указать тип ингредиента, количество и единицу измерения"},
                status=status.HTTP_400_BAD_REQUEST
            )

        ingredient_type_id = request.data['mis_igt_id']

        # Проверяем существование типа ингредиента
        try:
            IngredientType.objects.get(igt_id=ingredient_type_id)
        except IngredientType.DoesNotExist:
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
            existing_item.mis_quantity += int(request.data['mis_quantity'])
            existing_item.is_checked = False  # Сбрасываем статус "выполнено"
            existing_item.save()
            serializer = ShoppingListItemSerializer(existing_item)
            return Response(serializer.data, status=status.HTTP_200_OK)

        # Создание нового элемента
        item = M2MIngSpl.objects.create(
            mis_spl_id=shopping_list,
            mis_igt_id_id=ingredient_type_id,
            mis_quantity=request.data['mis_quantity'],
            mis_quantity_type=request.data['mis_quantity_type'],
            is_checked=False
        )

        serializer = ShoppingListItemSerializer(item)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def update_item(self, request, pk=None):
        """Обновление элемента списка покупок"""
        shopping_list = self.get_object()

        if 'item_id' not in request.data:
            return Response(
                {"error": "Необходимо указать ID элемента"},
                status=status.HTTP_400_BAD_REQUEST
            )

        item_id = request.data['item_id']

        try:
            item = M2MIngSpl.objects.get(mis_id=item_id, mis_spl_id=shopping_list)
        except M2MIngSpl.DoesNotExist:
            return Response(
                {"error": "Элемент не найден в списке покупок"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Обновление данных
        if 'mis_quantity' in request.data:
            item.mis_quantity = request.data['mis_quantity']

        if 'mis_quantity_type' in request.data:
            item.mis_quantity_type = request.data['mis_quantity_type']

        if 'is_checked' in request.data:
            item.is_checked = request.data['is_checked']

        item.save()

        serializer = ShoppingListItemSerializer(item)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def remove_item(self, request, pk=None):
        """Удаление элемента из списка покупок"""
        shopping_list = self.get_object()

        if 'item_id' not in request.data:
            return Response(
                {"error": "Необходимо указать ID элемента"},
                status=status.HTTP_400_BAD_REQUEST
            )

        item_id = request.data['item_id']

        try:
            item = M2MIngSpl.objects.get(mis_id=item_id, mis_spl_id=shopping_list)
            item.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except M2MIngSpl.DoesNotExist:
            return Response(
                {"error": "Элемент не найден в списке покупок"},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=True, methods=['post'])
    def clear_checked(self, request, pk=None):
        """Удаление всех выполненных элементов из списка покупок"""
        shopping_list = self.get_object()

        deleted_count, _ = M2MIngSpl.objects.filter(
            mis_spl_id=shopping_list,
            is_checked=True
        ).delete()

        return Response(
            {"deleted_count": deleted_count},
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=['post'])
    def clear_all(self, request, pk=None):
        """Очистка всего списка покупок"""
        shopping_list = self.get_object()

        deleted_count, _ = M2MIngSpl.objects.filter(mis_spl_id=shopping_list).delete()

        return Response(
            {"deleted_count": deleted_count},
            status=status.HTTP_200_OK
        )