from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    AllergenViewSet, UserAllergenViewSet,
    EquipmentViewSet, UserEquipmentViewSet,
    IngredientTypeViewSet, IngredientViewSet, RefrigeratorViewSet,
    RecipeViewSet, StepViewSet, FavoriteRecipeViewSet,
    MealPlanViewSet, DailyMealPlanViewSet, ActualMealViewSet,
    ShoppingListViewSet
)
from .barcode.views import get_product_by_barcode  

app_name = 'core'

router = DefaultRouter()
router.register(r'allergens', AllergenViewSet)
router.register(r'user-allergens', UserAllergenViewSet, basename='user-allergens')
router.register(r'equipment', EquipmentViewSet)
router.register(r'user-equipment', UserEquipmentViewSet, basename='user-equipment')
router.register(r'ingredient-types', IngredientTypeViewSet)
router.register(r'ingredients', IngredientViewSet)
router.register(r'refrigerator', RefrigeratorViewSet, basename='refrigerator')
router.register(r'recipes', RecipeViewSet)
router.register(r'steps', StepViewSet)
router.register(r'favorites', FavoriteRecipeViewSet, basename='favorites')
router.register(r'meal-plans', MealPlanViewSet, basename='meal-plans')
router.register(r'daily-plans', DailyMealPlanViewSet, basename='daily-plans')
router.register(r'meals', ActualMealViewSet, basename='meals')
router.register(r'shopping-list', ShoppingListViewSet, basename='shopping-list')

urlpatterns = [
    path('', include(router.urls)),
    path('barcode/', get_product_by_barcode, name='barcode'),
]