# Make sure to import the correct unittest module
import unittest
import sys
import os
import requests
import json
import random
import string
from datetime import date, datetime, timedelta

# Configuration
BASE_URL = "http://localhost:8000/api"
HEADERS = {
    "Content-Type": "application/json",
}


# Use the standard unittest.TestCase (not pytest's version)
class CookHelperAPITestSuite(unittest.TestCase):
    """Test suite for the CookHelper API"""

    def setUp(self):
        """Set up the test environment"""
        self.base_url = BASE_URL

        # Create a random user for testing
        self.test_email = f"test_{self.random_string()}@example.com"
        self.test_password = "TestPassword123"
        self.test_name = f"Test User {self.random_string()}"

        # Register user
        try:
            self.register_user()

            # Login to get token
            self.login_user()
        except requests.RequestException as e:
            self.fail(f"API setup failed: {str(e)}\n"
                      "Make sure the server is running and properly configured.")
        except Exception as e:
            self.fail(f"Setup failed: {str(e)}")

    def tearDown(self):
        """Clean up after tests"""
        # Logout if we have a token
        if hasattr(self, 'token'):
            try:
                self.logout_user()
            except:
                # If logout fails, we'll just continue
                pass

    def random_string(self, length=8):
        """Generate a random string for test data"""
        return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

    def safe_request(self, method, url, **kwargs):
        """Make a request with error handling"""
        try:
            response = method(url, **kwargs)
            return response
        except requests.ConnectionError:
            self.fail("Connection error. Make sure the server is running.")
        except requests.Timeout:
            self.fail("Request timed out. Server may be overloaded.")
        except Exception as e:
            self.fail(f"Request failed: {str(e)}")

    # ===== USER MANAGEMENT TESTS =====

    def register_user(self):
        """Register a test user"""
        url = f"{self.base_url}/users/register/"
        data = {
            "usr_mail": self.test_email,
            "usr_name": self.test_name,
            "password": self.test_password,
            "usr_height": 180,
            "usr_weight": 75,
            "usr_age": 30,
            "usr_gender": "MALE",  # Using uppercase MALE which matches the PostgreSQL enum
            "usr_cal_day": 2000
        }

        response = self.safe_request(requests.post, url, json=data)

        if response.status_code == 201:
            user_data = response.json()
            self.assertIn('user', user_data)
            self.assertIn('token', user_data)
            self.assertEqual(user_data['user']['usr_mail'], self.test_email)
            self.token = user_data['token']
            HEADERS["Authorization"] = f"Token {self.token}"
            print(f"User registered: {self.test_email}")
        elif response.status_code == 400 and 'уже существует' in response.text:
            # User already exists, we'll just login
            print(f"User already exists: {self.test_email}")
        else:
            # Check for Django Debug Toolbar errors
            if response.status_code == 500 and 'djdt' in response.text and 'NoReverseMatch' in response.text:
                raise Exception("Django Debug Toolbar error detected. Run debug_toolbar_fix.py to fix this issue.")
            elif response.status_code == 400 and 'gender_enum' in response.text:
                raise Exception(
                    "Invalid gender format. PostgreSQL enums are case-sensitive. Use 'MALE' or 'FEMALE' in uppercase.")
            else:
                raise Exception(f"Failed to register user: {response.text}")

    def login_user(self):
        """Login the test user"""
        url = f"{self.base_url}/users/login/"
        data = {
            "email": self.test_email,
            "password": self.test_password
        }

        response = self.safe_request(requests.post, url, json=data)

        if response.status_code == 200:
            user_data = response.json()
            self.assertIn('token', user_data)
            self.token = user_data['token']
            HEADERS["Authorization"] = f"Token {self.token}"
            print(f"Logged in: {self.test_email}")
        else:
            # Check for common errors
            if response.status_code == 500 and 'djdt' in response.text and 'NoReverseMatch' in response.text:
                raise Exception("Django Debug Toolbar error detected. Run debug_toolbar_fix.py to fix this issue.")
            elif response.status_code == 401:
                raise Exception(f"Authentication failed: {response.text}")
            else:
                raise Exception(f"Failed to login: {response.text}")

    def logout_user(self):
        """Logout the test user"""
        url = f"{self.base_url}/users/logout/"

        response = self.safe_request(requests.post, url, headers=HEADERS)

        if response.status_code == 200:
            print(f"Logged out: {self.test_email}")
            if "Authorization" in HEADERS:
                del HEADERS["Authorization"]
        else:
            print(f"Failed to logout: {response.text}")

    def test_01_register_user(self):
        """Test user registration"""
        # Generate unique email
        unique_email = f"unique_{self.random_string()}@example.com"

        url = f"{self.base_url}/users/register/"
        data = {
            "usr_mail": unique_email,
            "usr_name": f"Unique {self.random_string()}",
            "password": self.test_password,
            "usr_height": 170,
            "usr_weight": 70,
            "usr_age": 25,
            "usr_gender": "FEMALE",  # Using uppercase FEMALE which matches the PostgreSQL enum
            "usr_cal_day": 1800
        }

        response = self.safe_request(requests.post, url, json=data)
        self.assertEqual(response.status_code, 201)

        user_data = response.json()
        self.assertIn('user', user_data)
        self.assertIn('token', user_data)
        self.assertEqual(user_data['user']['usr_mail'], unique_email)

    def login_user(self):
        """Login the test user"""
        url = f"{self.base_url}/users/login/"
        data = {
            "email": self.test_email,
            "password": self.test_password
        }

        response = requests.post(url, json=data)

        if response.status_code == 200:
            user_data = response.json()
            self.assertIn('token', user_data)
            self.token = user_data['token']
            HEADERS["Authorization"] = f"Token {self.token}"
            print(f"Logged in: {self.test_email}")
        else:
            raise Exception(f"Failed to login: {response.text}")

    def test_02_login_user(self):
        """Test user login"""
        url = f"{self.base_url}/users/login/"
        data = {
            "email": self.test_email,
            "password": self.test_password
        }

        response = requests.post(url, json=data)
        self.assertEqual(response.status_code, 200)

        user_data = response.json()
        self.assertIn('token', user_data)
        self.assertIn('user', user_data)
        self.assertEqual(user_data['user']['usr_mail'], self.test_email)

    def test_03_get_profile(self):
        """Test getting user profile"""
        url = f"{self.base_url}/users/profile/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        profile = response.json()
        self.assertEqual(profile['usr_mail'], self.test_email)
        self.assertEqual(profile['usr_name'], self.test_name)

    def test_04_update_profile(self):
        """Test updating user profile"""
        url = f"{self.base_url}/users/profile/"

        # New profile data
        data = {
            "usr_name": f"Updated {self.random_string()}",
            "usr_height": 175,
            "usr_weight": 72,
            "usr_cal_day": 2200
        }

        response = requests.put(url, json=data, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        updated_profile = response.json()
        self.assertEqual(updated_profile['usr_name'], data['usr_name'])
        self.assertEqual(updated_profile['usr_height'], data['usr_height'])
        self.assertEqual(updated_profile['usr_weight'], data['usr_weight'])
        self.assertEqual(updated_profile['usr_cal_day'], data['usr_cal_day'])

    def test_05_password_reset_request(self):
        """Test password reset request"""
        url = f"{self.base_url}/users/password-reset/"
        data = {
            "email": self.test_email
        }

        response = requests.post(url, json=data)
        self.assertEqual(response.status_code, 200)

        result = response.json()
        self.assertTrue(result['success'])

    def logout_user(self):
        """Logout the test user"""
        url = f"{self.base_url}/users/logout/"

        response = requests.post(url, headers=HEADERS)

        if response.status_code == 200:
            print(f"Logged out: {self.test_email}")
            HEADERS.pop("Authorization", None)
        else:
            print(f"Failed to logout: {response.text}")

    def test_06_logout_user(self):
        """Test user logout"""
        url = f"{self.base_url}/users/logout/"

        response = requests.post(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        # Login again for remaining tests
        self.login_user()

    # ===== ALLERGEN TESTS =====

    def test_07_get_allergens(self):
        """Test getting all allergens"""
        url = f"{self.base_url}/allergens/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        allergens = response.json()
        self.assertIsInstance(allergens, list)

        # If there are allergens, test adding one to user
        if allergens:
            self.test_allergen_id = allergens[0]['alg_id']
            self.add_allergen_to_user()

    def add_allergen_to_user(self):
        """Add an allergen to the test user"""
        url = f"{self.base_url}/user-allergens/"
        data = {
            "mua_alg_id": self.test_allergen_id
        }

        response = requests.post(url, json=data, headers=HEADERS)

        if response.status_code == 201:
            print(f"Added allergen {self.test_allergen_id} to user")
        elif response.status_code == 400 and 'уже добавлен' in response.text:
            print(f"Allergen {self.test_allergen_id} already added to user")
        else:
            print(f"Failed to add allergen: {response.text}")

    def test_08_user_allergens(self):
        """Test getting user allergens"""
        url = f"{self.base_url}/user-allergens/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        user_allergens = response.json()
        self.assertIsInstance(user_allergens, list)

    def test_09_user_allergens_specific(self):
        """Test getting specific user allergens"""
        url = f"{self.base_url}/user-allergens/user_allergens/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        allergen_ids = response.json()
        self.assertIsInstance(allergen_ids, list)

    # ===== EQUIPMENT TESTS =====

    def test_10_get_equipment(self):
        """Test getting all equipment"""
        url = f"{self.base_url}/equipment/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        equipment = response.json()
        self.assertIsInstance(equipment, list)

        # If there is equipment, test adding one to user
        if equipment:
            self.test_equipment_id = equipment[0]['eqp_id']
            self.add_equipment_to_user()

    def add_equipment_to_user(self):
        """Add equipment to the test user"""
        url = f"{self.base_url}/user-equipment/"
        data = {
            "mue_eqp_id": self.test_equipment_id
        }

        response = requests.post(url, json=data, headers=HEADERS)

        if response.status_code == 201:
            print(f"Added equipment {self.test_equipment_id} to user")
        elif response.status_code == 400 and 'уже добавлено' in response.text:
            print(f"Equipment {self.test_equipment_id} already added to user")
        else:
            print(f"Failed to add equipment: {response.text}")

    def test_11_user_equipment(self):
        """Test getting user equipment"""
        url = f"{self.base_url}/user-equipment/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        user_equipment = response.json()
        self.assertIsInstance(user_equipment, list)

    def test_12_user_equipment_specific(self):
        """Test getting specific user equipment"""
        url = f"{self.base_url}/user-equipment/user_equipment/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        equipment_ids = response.json()
        self.assertIsInstance(equipment_ids, list)

    # ===== INGREDIENT TESTS =====

    def test_13_get_ingredient_types(self):
        """Test getting all ingredient types"""
        url = f"{self.base_url}/ingredient-types/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        ingredient_types = response.json()
        self.assertIsInstance(ingredient_types, list)

        # Save for later tests
        if ingredient_types:
            self.test_ingredient_type_id = ingredient_types[0]['igt_id']

    def test_14_get_ingredients(self):
        """Test getting all ingredients"""
        url = f"{self.base_url}/ingredients/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        ingredients = response.json()
        self.assertIsInstance(ingredients, list)

        # Save for later tests
        if ingredients:
            self.test_ingredient_id = ingredients[0]['ing_id']
            self.add_ingredient_to_refrigerator()

    def add_ingredient_to_refrigerator(self):
        """Add ingredient to user's refrigerator"""
        if not hasattr(self, 'test_ingredient_id'):
            print("No test ingredient available")
            return

        url = f"{self.base_url}/refrigerator/"
        data = {
            "mui_ing_id": self.test_ingredient_id,
            "mui_quantity": 500,
            "mui_quantity_type": "grams"
        }

        response = requests.post(url, json=data, headers=HEADERS)

        if response.status_code == 201:
            print(f"Added ingredient {self.test_ingredient_id} to refrigerator")
            self.refrigerator_item_id = response.json().get('mui_id')
        elif response.status_code == 400 and 'уже есть в холодильнике' in response.text:
            # Get the refrigerator to find the item ID
            fridge_response = requests.get(url, headers=HEADERS)
            if fridge_response.status_code == 200:
                fridge_items = fridge_response.json()
                for item in fridge_items:
                    if item['ingredient']['ing_id'] == self.test_ingredient_id:
                        self.refrigerator_item_id = item['mui_id']
                        break
            print(f"Ingredient {self.test_ingredient_id} already in refrigerator")
        else:
            print(f"Failed to add ingredient to refrigerator: {response.text}")

    def test_15_get_refrigerator(self):
        """Test getting user's refrigerator"""
        url = f"{self.base_url}/refrigerator/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        refrigerator = response.json()
        self.assertIsInstance(refrigerator, list)

    def test_16_expiring_soon(self):
        """Test getting ingredients expiring soon"""
        url = f"{self.base_url}/refrigerator/expiring_soon/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        expiring = response.json()
        self.assertIsInstance(expiring, list)

    def test_17_update_refrigerator_item(self):
        """Test updating a refrigerator item"""
        if not hasattr(self, 'refrigerator_item_id'):
            self.skipTest("No refrigerator item available")

        url = f"{self.base_url}/refrigerator/{self.refrigerator_item_id}/"
        data = {
            "mui_quantity": 750,
            "mui_quantity_type": "grams"
        }

        response = requests.put(url, json=data, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        updated_item = response.json()
        self.assertEqual(updated_item['mui_quantity'], data['mui_quantity'])
        self.assertEqual(updated_item['mui_quantity_type'], data['mui_quantity_type'])

    # ===== RECIPE TESTS =====

    def test_18_get_recipes(self):
        """Test getting all recipes"""
        url = f"{self.base_url}/recipes/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        recipes = response.json()
        self.assertIsInstance(recipes, list)

        # Save for later tests
        if recipes:
            self.test_recipe_id = recipes[0]['rcp_id']
            self.get_recipe_details()
            self.add_recipe_to_favorites()

    def get_recipe_details(self):
        """Get details for test recipe"""
        if not hasattr(self, 'test_recipe_id'):
            print("No test recipe available")
            return

        url = f"{self.base_url}/recipes/{self.test_recipe_id}/"

        response = requests.get(url, headers=HEADERS)

        if response.status_code == 200:
            recipe = response.json()
            print(f"Got details for recipe {self.test_recipe_id}")
            # Save step id for later tests if available
            if recipe.get('steps') and len(recipe['steps']) > 0:
                self.test_step_id = recipe['steps'][0]['stp_id']
        else:
            print(f"Failed to get recipe details: {response.text}")

    def add_recipe_to_favorites(self):
        """Add a recipe to favorites"""
        if not hasattr(self, 'test_recipe_id'):
            print("No test recipe available")
            return

        url = f"{self.base_url}/favorites/"
        data = {
            "fvr_rcp_id": self.test_recipe_id
        }

        response = requests.post(url, json=data, headers=HEADERS)

        if response.status_code == 201:
            print(f"Added recipe {self.test_recipe_id} to favorites")
            self.favorite_id = response.json().get('fvr_id')
        elif response.status_code == 400 and 'уже в избранном' in response.text:
            # Get favorites to find the id
            fav_response = requests.get(url, headers=HEADERS)
            if fav_response.status_code == 200:
                favorites = fav_response.json()
                for fav in favorites:
                    if fav['recipe']['rcp_id'] == self.test_recipe_id:
                        self.favorite_id = fav['fvr_id']
                        break
            print(f"Recipe {self.test_recipe_id} already in favorites")
        else:
            print(f"Failed to add recipe to favorites: {response.text}")

    def test_19_recommended_recipes(self):
        """Test getting recommended recipes"""
        url = f"{self.base_url}/recipes/recommended/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        recommended = response.json()
        self.assertIsInstance(recommended, list)

    def test_20_favorite_recipes(self):
        """Test getting favorite recipes"""
        url = f"{self.base_url}/recipes/favorites/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        favorites = response.json()
        self.assertIsInstance(favorites, list)

    def test_21_get_steps(self):
        """Test getting recipe steps"""
        url = f"{self.base_url}/steps/"

        if hasattr(self, 'test_recipe_id'):
            url += f"?recipe_id={self.test_recipe_id}"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        steps = response.json()
        self.assertIsInstance(steps, list)

    def test_22_get_step_detail(self):
        """Test getting step details"""
        if not hasattr(self, 'test_step_id'):
            self.skipTest("No test step available")

        url = f"{self.base_url}/steps/{self.test_step_id}/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        step = response.json()
        self.assertEqual(step['stp_id'], self.test_step_id)

    def test_23_get_favorites(self):
        """Test getting user favorites"""
        url = f"{self.base_url}/favorites/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        favorites = response.json()
        self.assertIsInstance(favorites, list)

    def test_24_remove_from_favorites(self):
        """Test removing a recipe from favorites"""
        if not hasattr(self, 'favorite_id'):
            self.skipTest("No favorite recipe available")

        url = f"{self.base_url}/favorites/remove/"
        data = {
            "fvr_rcp_id": self.test_recipe_id
        }

        response = requests.delete(url, json=data, headers=HEADERS)
        self.assertEqual(response.status_code, 204)

        # Add back for other tests
        self.add_recipe_to_favorites()

    # ===== MEAL PLAN TESTS =====

    def test_25_create_meal_plan(self):
        """Test creating a meal plan"""
        url = f"{self.base_url}/meal-plans/"

        # Create a weekly meal plan for next week
        today = date.today()
        start_date = today + timedelta(days=(7 - today.weekday()))
        end_date = start_date + timedelta(days=6)

        data = {
            "wmp_start": start_date.isoformat(),
            "wmp_end": end_date.isoformat()
        }

        response = requests.post(url, json=data, headers=HEADERS)

        if response.status_code == 201:
            self.meal_plan_id = response.json().get('wmp_id')
            print(f"Created meal plan {self.meal_plan_id}")
        elif response.status_code == 400:
            # Check if it's because the plan already exists
            response = requests.get(url, headers=HEADERS)
            if response.status_code == 200:
                meal_plans = response.json()
                for plan in meal_plans:
                    if plan['wmp_start'] == data['wmp_start'] and plan['wmp_end'] == data['wmp_end']:
                        self.meal_plan_id = plan['wmp_id']
                        print(f"Meal plan already exists with ID {self.meal_plan_id}")
                        break
            if not hasattr(self, 'meal_plan_id'):
                self.fail(f"Failed to create meal plan: {response.text}")
        else:
            self.fail(f"Failed to create meal plan: {response.text}")

    def test_26_get_meal_plans(self):
        """Test getting user's meal plans"""
        url = f"{self.base_url}/meal-plans/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        meal_plans = response.json()
        self.assertIsInstance(meal_plans, list)

    def test_27_current_meal_plan(self):
        """Test getting current meal plan"""
        url = f"{self.base_url}/meal-plans/current/"

        response = requests.get(url, headers=HEADERS)
        # Either 200 or 404 is acceptable (might not have a current plan)
        self.assertIn(response.status_code, [200, 404])

    def test_28_get_meal_plan_days(self):
        """Test getting days for a meal plan"""
        if not hasattr(self, 'meal_plan_id'):
            self.skipTest("No meal plan available")

        url = f"{self.base_url}/meal-plans/{self.meal_plan_id}/days/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        days = response.json()
        self.assertIsInstance(days['results'], list)

        # If we have days, save one for later tests
        if days['results']:
            self.daily_plan_id = days['results'][0]['dmp_id']

    def test_29_create_actual_meal(self):
        """Test creating an actual meal"""
        url = f"{self.base_url}/meals/"

        data = {
            "adm_date": date.today().isoformat(),
            "adm_type": "Breakfast",
            "adm_time": datetime.now().strftime("%H:%M")
        }

        response = requests.post(url, json=data, headers=HEADERS)

        if response.status_code == 201:
            self.meal_id = response.json().get('adm_id')
            print(f"Created meal {self.meal_id}")

            # Add a recipe to the meal if we have one
            if hasattr(self, 'test_recipe_id'):
                self.add_recipe_to_meal()
        else:
            self.fail(f"Failed to create meal: {response.text}")

    def add_recipe_to_meal(self):
        """Add a recipe to a meal"""
        if not hasattr(self, 'meal_id') or not hasattr(self, 'test_recipe_id'):
            print("Missing meal_id or test_recipe_id")
            return

        url = f"{self.base_url}/meals/{self.meal_id}/add_recipe/"
        data = {
            "recipe_id": self.test_recipe_id
        }

        response = requests.post(url, json=data, headers=HEADERS)

        if response.status_code == 201:
            print(f"Added recipe {self.test_recipe_id} to meal {self.meal_id}")
        elif response.status_code == 400 and 'уже добавлен' in response.text:
            print(f"Recipe {self.test_recipe_id} already added to meal {self.meal_id}")
        else:
            print(f"Failed to add recipe to meal: {response.text}")

    def test_30_get_meals(self):
        """Test getting user's meals"""
        url = f"{self.base_url}/meals/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        meals = response.json()
        self.assertIsInstance(meals, list)

    def test_31_get_meal_recipes(self):
        """Test getting recipes for a meal"""
        if not hasattr(self, 'meal_id'):
            self.skipTest("No meal available")

        url = f"{self.base_url}/meals/{self.meal_id}/recipes/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        recipes = response.json()
        self.assertIsInstance(recipes['results'], list)

    def test_32_remove_recipe_from_meal(self):
        """Test removing a recipe from a meal"""
        if not hasattr(self, 'meal_id') or not hasattr(self, 'test_recipe_id'):
            self.skipTest("No meal or recipe available")

        url = f"{self.base_url}/meals/{self.meal_id}/remove_recipe/"
        data = {
            "recipe_id": self.test_recipe_id
        }

        response = requests.post(url, json=data, headers=HEADERS)
        # 204 if successful, 404 if recipe wasn't in meal
        self.assertIn(response.status_code, [204, 404])

        # Add back for other tests
        self.add_recipe_to_meal()

    # ===== SHOPPING LIST TESTS =====

    def test_33_get_shopping_list(self):
        """Test getting user's shopping list"""
        url = f"{self.base_url}/shopping-list/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        shopping_list = response.json()
        self.assertIsInstance(shopping_list, list)

        if shopping_list:
            self.shopping_list_id = shopping_list[0]['spl_id']

    def test_34_add_item_to_shopping_list(self):
        """Test adding an item to shopping list"""
        if not hasattr(self, 'shopping_list_id') or not hasattr(self, 'test_ingredient_type_id'):
            self.skipTest("No shopping list or ingredient type available")

        url = f"{self.base_url}/shopping-list/{self.shopping_list_id}/add_item/"
        data = {
            "mis_igt_id": self.test_ingredient_type_id,
            "mis_quantity": 200,
            "mis_quantity_type": "grams"
        }

        response = requests.post(url, json=data, headers=HEADERS)
        self.assertIn(response.status_code, [200, 201])

        item = response.json()
        self.shopping_list_item_id = item['mis_id']

    def test_35_get_shopping_list_items(self):
        """Test getting shopping list items"""
        if not hasattr(self, 'shopping_list_id'):
            self.skipTest("No shopping list available")

        url = f"{self.base_url}/shopping-list/{self.shopping_list_id}/items/"

        response = requests.get(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        items = response.json()
        self.assertIsInstance(items['results'], list)

    def test_36_update_shopping_list_item(self):
        """Test updating a shopping list item"""
        if not hasattr(self, 'shopping_list_id') or not hasattr(self, 'shopping_list_item_id'):
            self.skipTest("No shopping list item available")

        url = f"{self.base_url}/shopping-list/{self.shopping_list_id}/update_item/"
        data = {
            "item_id": self.shopping_list_item_id,
            "mis_quantity": 300,
            "is_checked": True
        }

        response = requests.post(url, json=data, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        item = response.json()
        self.assertEqual(item['mis_quantity'], data['mis_quantity'])
        self.assertEqual(item['is_checked'], data['is_checked'])

    def test_37_remove_shopping_list_item(self):
        """Test removing a shopping list item"""
        if not hasattr(self, 'shopping_list_id') or not hasattr(self, 'shopping_list_item_id'):
            self.skipTest("No shopping list item available")

        url = f"{self.base_url}/shopping-list/{self.shopping_list_id}/remove_item/"
        data = {
            "item_id": self.shopping_list_item_id
        }

        response = requests.post(url, json=data, headers=HEADERS)
        self.assertEqual(response.status_code, 204)

        # Add an item back for other tests
        self.test_34_add_item_to_shopping_list()

    def test_38_clear_checked_items(self):
        """Test clearing checked items from shopping list"""
        if not hasattr(self, 'shopping_list_id'):
            self.skipTest("No shopping list available")

        # First make sure we have a checked item
        url = f"{self.base_url}/shopping-list/{self.shopping_list_id}/update_item/"
        data = {
            "item_id": self.shopping_list_item_id,
            "is_checked": True
        }

        requests.post(url, json=data, headers=HEADERS)

        # Now clear checked items
        url = f"{self.base_url}/shopping-list/{self.shopping_list_id}/clear_checked/"

        response = requests.post(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        result = response.json()
        self.assertIn('deleted_count', result)

        # Add an item back for other tests
        self.test_34_add_item_to_shopping_list()

    def test_39_clear_all_shopping_list(self):
        """Test clearing all shopping list items"""
        if not hasattr(self, 'shopping_list_id'):
            self.skipTest("No shopping list available")

        url = f"{self.base_url}/shopping-list/{self.shopping_list_id}/clear_all/"

        response = requests.post(url, headers=HEADERS)
        self.assertEqual(response.status_code, 200)

        result = response.json()
        self.assertIn('deleted_count', result)

        # Add an item back for future tests
        self.test_34_add_item_to_shopping_list()


if __name__ == '__main__':
    unittest.main()