
from rest_framework import serializers
from ..models import (
    WeaklyMealPlan, DailyMealPlan, ActualDayMeal,
    M2MRcpDmp, M2MRcpAdm, M2MIngDmp, M2MIngAdm
)
from .recipe import RecipeListSerializer
from .ingredient import IngredientDetailSerializer


class MealRecipeSerializer(serializers.ModelSerializer):
    """Сериализатор для рецептов в приеме пищи"""
    recipe = RecipeListSerializer(source='mra_rcp_id', read_only=True)

    class Meta:
        model = M2MRcpAdm
        fields = ['recipe']


class MealIngredientSerializer(serializers.ModelSerializer):
    """Сериализатор для ингредиентов в приеме пищи"""
    ingredient = IngredientDetailSerializer(source='mia_ing_id', read_only=True)

    class Meta:
        model = M2MIngAdm
        fields = ['mia_quantity', 'mia_quantity_type', 'ingredient']


class ActualDayMealSerializer(serializers.ModelSerializer):
    """Сериализатор для фактических приемов пищи"""
    recipes = serializers.SerializerMethodField()
    ingredients = serializers.SerializerMethodField()

    class Meta:
        model = ActualDayMeal
        fields = ['adm_id', 'adm_date', 'adm_type', 'adm_time', 'recipes', 'ingredients']

    def get_recipes(self, obj):
        """Получить рецепты для приема пищи"""
        meal_recipes = M2MRcpAdm.objects.filter(mra_adm_id=obj)
        return MealRecipeSerializer(meal_recipes, many=True).data

    def get_ingredients(self, obj):
        """Получить ингредиенты для приема пищи"""
        meal_ingredients = M2MIngAdm.objects.filter(mia_adm_id=obj)
        return MealIngredientSerializer(meal_ingredients, many=True).data


class DailyMealPlanRecipeSerializer(serializers.ModelSerializer):
    """Сериализатор для рецептов в дневном плане питания"""
    recipe = RecipeListSerializer(source='mrd_rcp_id', read_only=True)

    class Meta:
        model = M2MRcpDmp
        fields = ['mrd_id', 'recipe']


class DailyMealPlanIngredientSerializer(serializers.ModelSerializer):
    """Сериализатор для ингредиентов в дневном плане питания"""
    ingredient = IngredientDetailSerializer(source='mid_ing_id', read_only=True)

    class Meta:
        model = M2MIngDmp
        fields = ['mid_quantity', 'mid_quantity_type', 'ingredient']


class DailyMealPlanSerializer(serializers.ModelSerializer):
    """Сериализатор для дневных планов питания"""
    recipes = serializers.SerializerMethodField()
    meals = serializers.SerializerMethodField()

    class Meta:
        model = DailyMealPlan
        fields = ['dmp_id', 'dmp_date', 'dmp_cal_day', 'recipes', 'meals']

    def get_recipes(self, obj):
        """Получить рецепты для дневного плана питания"""
        daily_recipes = M2MRcpDmp.objects.filter(mrd_dmp_id=obj)
        return DailyMealPlanRecipeSerializer(daily_recipes, many=True).data

    def get_meals(self, obj):
        """Получить фактические приемы пищи для этой даты"""
        request = self.context.get('request')
        if request and hasattr(request, 'user') and request.user.is_authenticated:
            meals = ActualDayMeal.objects.filter(
                adm_usr_id=request.user,
                adm_date=obj.dmp_date
            )
            return ActualDayMealSerializer(meals, many=True, context=self.context).data
        return []


class WeaklyMealPlanSerializer(serializers.ModelSerializer):
    """Сериализатор для недельных планов питания"""
    days = serializers.SerializerMethodField()

    class Meta:
        model = WeaklyMealPlan
        fields = ['wmp_id', 'wmp_start', 'wmp_end', 'days']

    def get_days(self, obj):
        """Получить дневные планы питания для недельного плана"""
        daily_plans = DailyMealPlan.objects.filter(dmp_wmp_id=obj)
        return DailyMealPlanSerializer(daily_plans, many=True, context=self.context).data