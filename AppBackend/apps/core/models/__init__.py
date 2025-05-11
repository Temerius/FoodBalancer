# AppBackend/apps/core/models/__init__.py
from .base import TimeStampedModel
from .allergen import Allergen, M2MUsrAlg
from .equipment import Equipment, M2MUsrEqp, M2MRcpEqp
from .ingredient import IngredientType, Ingredient, M2MUsrIng, IngredientToAllergen
from .recipe import Recipe, Step, Image, M2MStpIgt, FavoriteRecipe
from .meal_plan import WeaklyMealPlan, DailyMealPlan, ActualDayMeal, M2MRcpDmp, M2MRcpAdm, M2MIngDmp, M2MIngAdm
from .shopping_list import ShoppingList, M2MIngSpl