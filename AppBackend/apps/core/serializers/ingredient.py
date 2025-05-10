# AppBackend/apps/core/serializers/ingredient.py - окончательная версия

from rest_framework import serializers
from ..models import IngredientType, Ingredient, M2MUsrIng


class IngredientTypeSerializer(serializers.ModelSerializer):
    """Сериализатор для типов ингредиентов"""

    class Meta:
        model = IngredientType
        fields = ['igt_id', 'igt_name', 'igt_img_url']


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

    # Специальный метод для корректной сериализации mui_ing_id
    mui_ing_id = serializers.SerializerMethodField()
    mui_usr_id = serializers.SerializerMethodField()

    class Meta:
        model = M2MUsrIng
        fields = ['mui_id', 'mui_usr_id', 'mui_ing_id', 'mui_quantity', 'mui_quantity_type', 'ingredient']
        read_only_fields = ['mui_usr_id']

    def get_mui_ing_id(self, obj):
        """Возвращает ID ингредиента как integer"""
        return obj.mui_ing_id.ing_id if obj.mui_ing_id else None

    def get_mui_usr_id(self, obj):
        """Возвращает ID пользователя как integer"""
        return obj.mui_usr_id.usr_id if obj.mui_usr_id else None

    def to_internal_value(self, data):
        """Преобразует входящие данные для создания/обновления"""
        # Сохраняем значение mui_ing_id как есть (как integer)
        ret = super().to_internal_value(data)
        if 'mui_ing_id' in data:
            ret['mui_ing_id'] = data['mui_ing_id']
        return ret