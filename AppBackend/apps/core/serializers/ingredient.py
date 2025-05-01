# AppBackend/apps/core/serializers/ingredient.py
from rest_framework import serializers
from ..models import IngredientType, Ingredient, M2MUsrIng


class IngredientTypeSerializer(serializers.ModelSerializer):
    """Сериализатор для типов ингредиентов"""

    class Meta:
        model = IngredientType
        fields = ['igt_id', 'igt_name', 'igt_img_url', 'category']


class IngredientSerializer(serializers.ModelSerializer):
    """Базовый сериализатор для ингредиентов"""
    ing_igt_id = serializers.PrimaryKeyRelatedField(queryset=IngredientType.objects.all())

    class Meta:
        model = Ingredient
        fields = [
            'ing_id', 'ing_name', 'ing_exp_date', 'ing_weight', 'ing_calories',
            'ing_protein', 'ing_fat', 'ing_hydrates', 'ing_igt_id', 'ing_img_url'
        ]


class IngredientDetailSerializer(serializers.ModelSerializer):
    """Детальный сериализатор для ингредиентов с включением типа"""
    ing_igt_id = IngredientTypeSerializer(read_only=True)

    class Meta:
        model = Ingredient
        fields = [
            'ing_id', 'ing_name', 'ing_exp_date', 'ing_weight', 'ing_calories',
            'ing_protein', 'ing_fat', 'ing_hydrates', 'ing_igt_id', 'ing_img_url'
        ]


class UserIngredientSerializer(serializers.ModelSerializer):
    """Сериализатор для ингредиентов пользователя (холодильник)"""
    ingredient = IngredientDetailSerializer(source='mui_ing_id', read_only=True)

    class Meta:
        model = M2MUsrIng
        fields = ['mui_id', 'mui_quantity', 'mui_quantity_type', 'ingredient']