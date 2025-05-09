# AppBackend/apps/core/serializers/shopping_list.py
from rest_framework import serializers
from ..models import ShoppingList, M2MIngSpl
from .ingredient import IngredientTypeSerializer

class ShoppingListItemSerializer(serializers.ModelSerializer):
    """Сериализатор для элемента списка покупок"""
    ingredient_type = IngredientTypeSerializer(source='mis_igt_id', read_only=True)

    class Meta:
        model = M2MIngSpl
        fields = ['mis_id', 'mis_quantity', 'mis_quantity_type', 'is_checked', 'ingredient_type']


class ShoppingListSerializer(serializers.ModelSerializer):
    """Сериализатор для списка покупок"""
    items = ShoppingListItemSerializer(many=True, read_only=True)

    class Meta:
        model = ShoppingList
        fields = ['spl_id', 'items']