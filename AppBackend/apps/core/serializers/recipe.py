# AppBackend/apps/core/serializers/recipe.py
from rest_framework import serializers
from ..models import Recipe, Step, M2MStpIgt, Image, FavoriteRecipe
from .ingredient import IngredientTypeSerializer
from .equipment import EquipmentSerializer


class ImageSerializer(serializers.ModelSerializer):
    """Сериализатор для изображений шагов рецепта"""

    class Meta:
        model = Image
        fields = ['img_id', 'img_url']


class StepIngredientSerializer(serializers.ModelSerializer):
    """Сериализатор для ингредиентов шага рецепта"""
    ingredient_type = IngredientTypeSerializer(source='msi_igt_id', read_only=True)

    class Meta:
        model = M2MStpIgt
        fields = ['msi_id', 'ingredient_type', 'msi_quantity', 'msi_quantity_type']


class StepSerializer(serializers.ModelSerializer):
    """Сериализатор для шагов рецепта"""
    images = ImageSerializer(many=True, read_only=True)
    ingredients = StepIngredientSerializer(source='ingredient_types', many=True, read_only=True)

    class Meta:
        model = Step
        fields = ['stp_id', 'stp_title', 'stp_instruction', 'images', 'ingredients']


class RecipeListSerializer(serializers.ModelSerializer):
    """Сериализатор для списка рецептов"""
    is_favorite = serializers.SerializerMethodField()

    class Meta:
        model = Recipe
        fields = ['rcp_id', 'rcp_title', 'rcp_description', 'rcp_cal', 'rcp_portion_count', 'is_favorite']

    def get_is_favorite(self, obj):
        """Проверка, находится ли рецепт в избранном у пользователя"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return FavoriteRecipe.objects.filter(
                fvr_rcp_id=obj,
                fvr_usr_id=request.user
            ).exists()
        return False


class RecipeDetailSerializer(serializers.ModelSerializer):
    """Детальный сериализатор для рецептов"""
    steps = StepSerializer(many=True, read_only=True)
    equipment = EquipmentSerializer(many=True, read_only=True)
    is_favorite = serializers.SerializerMethodField()

    class Meta:
        model = Recipe
        fields = [
            'rcp_id', 'rcp_title', 'rcp_description', 'rcp_cal', 'rcp_portion_count',
            'steps', 'equipment', 'is_favorite'
        ]

    def get_is_favorite(self, obj):
        """Проверка, находится ли рецепт в избранном у пользователя"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return FavoriteRecipe.objects.filter(
                fvr_rcp_id=obj,
                fvr_usr_id=request.user
            ).exists()
        return False


class FavoriteRecipeSerializer(serializers.ModelSerializer):
    """Сериализатор для избранных рецептов"""
    recipe = RecipeListSerializer(source='fvr_rcp_id', read_only=True)

    class Meta:
        model = FavoriteRecipe
        fields = ['fvr_id', 'recipe']