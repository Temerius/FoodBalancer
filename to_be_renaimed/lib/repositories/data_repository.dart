import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/allergen.dart';
import '../models/equipment.dart';
import '../models/ingredient.dart';
import '../models/ingredient_type.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../models/shopping_list.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/cache_manager.dart';

class DataRepository with ChangeNotifier {

  final ApiService _apiService;

  DataRepository({ApiService? apiService}) :
        _apiService = apiService ?? ApiService();

  // Current session data
  User? _currentUser;
  List<Allergen> _allergens = [];
  List<Equipment> _equipment = [];
  List<IngredientType> _ingredientTypes = [];
  List<Recipe> _recipes = [];

  // Loading status
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get user => _currentUser;
  List<Allergen> get allergens => _allergens;
  List<Equipment> get equipment => _equipment;
  List<IngredientType> get ingredientTypes => _ingredientTypes;
  List<Recipe> get recipes => _recipes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize repository and load cached data
  // Initialize repository and load cached data
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Load data from cache first
      await _loadFromCache();

      // Check if cache is outdated
      final cacheExpired = await CacheManager.isAllCacheExpired();

      // If data is not in cache or outdated, fetch from API
      if (_currentUser == null || cacheExpired) {
        await refreshAllData();
      }

      // Load user-specific data if user is logged in
      if (_currentUser != null) {
        await loadUserData();
      }

      _isInitialized = true;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Refresh all data from the API
  Future<void> refreshAllData() async {
    _setLoading(true);
    try {
      await Future.wait([
        _fetchUser(),
        _fetchAllergens(),
        _fetchEquipment(),
        _fetchIngredientTypes(),
        _fetchRecipes(),
      ]);

      // Update cache with fresh data
      await _updateCache();

      // Mark the data as fresh
      await CacheManager.touchCache();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load user's specific data
  Future<void> loadUserData() async {
    if (_currentUser == null) return;

    _setLoading(true);
    try {
      await Future.wait([
        _fetchUserAllergens(),  // Make sure this is called
        _fetchUserEquipment(),
        _fetchUserIngredients(),
        _fetchFavoriteRecipes(),
        _fetchCurrentMealPlan(),
        _fetchShoppingList(),
      ]);

      // Link references between objects
      _linkReferences();

      // Update cache with user-specific data
      await _updateCache();

      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  // Update user profile
  // Обновление профиля пользователя
  // Обновление профиля пользователя
  // Обновление профиля пользователя
  Future<bool> updateUserProfile(User updatedUser) async {
    _setLoading(true);
    try {
      // Формируем данные для запроса
      final Map<String, dynamic> userData = {
        'usr_name': updatedUser.name,
        'usr_height': updatedUser.height,
        'usr_weight': updatedUser.weight,
        'usr_age': updatedUser.age,
        'usr_cal_day': updatedUser.caloriesPerDay,
      };

      // Добавляем пол, если он указан, точно в формате, соответствующем enum в PostgreSQL
      if (updatedUser.gender != null) {
        userData['usr_gender'] = updatedUser.gender!.toPostgreSqlValue();
      }

      print("Отправляем данные на сервер: ${jsonEncode(userData)}");

      // Отправляем запрос на обновление профиля
      final response = await _apiService.put('/api/users/profile/', userData);

      // Обновляем данные об аллергенах, если они указаны
      if (updatedUser.allergenIds.isNotEmpty) {
        await _apiService.post('/api/user-allergens/update/', {
          'allergen_ids': updatedUser.allergenIds,
        });
      }

      // Обновляем данные об оборудовании, если оно указано
      if (updatedUser.equipmentIds.isNotEmpty) {
        await _apiService.post('/api/user-equipment/user_equipment/', {
          'equipment_ids': updatedUser.equipmentIds,
        });
      }

      // Если пришел ответ от сервера, обновляем локальную копию пользователя
      if (response.containsKey('usr_id')) {
        _currentUser = User.fromJson(response);
      } else {
        // Если сервер не вернул данные пользователя, используем переданные
        _currentUser = updatedUser;
      }

      // Обновляем кэш
      await CacheManager.saveUser(_currentUser!.toJson());

      _setLoading(false);
      notifyListeners();
      await refreshUserData();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update the refreshUserData method in data_repository.dart

  Future<void> refreshUserData() async {
    _setLoading(true);
    try {
      // Fetch user profile
      await _fetchUser();

      // Make sure we have all allergens loaded
      await _fetchAllergens();

      // Fetch user allergens
      await _fetchUserAllergens();

      // Other data fetching methods...

      // Update cache
      await _updateCache();

      // Notify listeners to update the UI
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update cache with fresh data
  Future<void> _updateCache() async {
    // Save basic data
    if (_currentUser != null) {
      await CacheManager.saveUser(_currentUser!.toJson());
    }

    if (_allergens.isNotEmpty) {
      await CacheManager.saveAllergens(_allergens.map((a) => a.toJson()).toList());
    }

    if (_equipment.isNotEmpty) {
      await CacheManager.saveEquipment(_equipment.map((e) => e.toJson()).toList());
    }

    if (_ingredientTypes.isNotEmpty) {
      await CacheManager.saveIngredientTypes(_ingredientTypes.map((t) => t.toJson()).toList());
    }

    if (_recipes.isNotEmpty) {
      await CacheManager.saveRecipes(_recipes.map((r) => r.toJson()).toList());

      // Save recipe details
      Map<String, dynamic> recipeDetailsMap = {};
      for (var recipe in _recipes) {
        recipeDetailsMap[recipe.id.toString()] = {
          'steps': recipe.steps.map((step) => step.toJson()).toList(),
          'ingredients': recipe.ingredients.map((ingredient) => ingredient.toJson()).toList(),
          'required_equipment': recipe.requiredEquipment.map((equip) => equip.id).toList(),
        };
      }

      await CacheManager.saveRecipeDetails(recipeDetailsMap);
    }
  }

  // Private methods for fetching data
  Future<void> _fetchUser() async {
    try {
      final userData = await _apiService.get('/api/users/profile/');
      _currentUser = User.fromJson(userData);
      await CacheManager.saveUser(userData);
    } catch (e) {
      throw Exception('Failed to load user data: $e');
    }
  }

  // Add or modify in data_repository.dart

  Future<void> _fetchAllergens() async {
    try {
      // Fix pagination by requesting more items
      final response = await _apiService.get('/api/allergens/?limit=1000');

      if (response.containsKey('results')) {
        final List<dynamic> allergensJson = response['results'];
        _allergens = allergensJson.map((json) => Allergen.fromJson(json)).toList();
      }
    } catch (e) {
      throw Exception('Failed to load allergens: $e');
    }
  }

  Future<void> _fetchEquipment() async {
    try {
      final response = await _apiService.get('/api/equipment/');
      final List<dynamic> equipmentJson = response['results'];
      _equipment = equipmentJson.map((json) => Equipment.fromJson(json)).toList();
      await CacheManager.saveEquipment(equipmentJson.cast<Map<String, dynamic>>());
    } catch (e) {
      throw Exception('Failed to load equipment: $e');
    }
  }

  Future<List<int>> getUserAllergenIds() async {
    try {
      print("Directly fetching user allergens");

      // Get user allergens with higher limit
      final response = await _apiService.get('/api/user-allergens/?limit=1000');
      print("User allergens direct response: $response");

      List<int> allergenIds = [];

      if (response.containsKey('results')) {
        final List<dynamic> userAllergensJson = response['results'];

        for (var item in userAllergensJson) {
          print("Processing allergen item: $item");

          if (item.containsKey('mua_alg_id')) {
            var algId = item['mua_alg_id'];
            if (algId is Map) {
              if (algId.containsKey('alg_id')) {
                allergenIds.add(algId['alg_id'] as int);
              }
            } else if (algId is int) {
              allergenIds.add(algId);
            }
          } else if (item.containsKey('alg_id')) {
            allergenIds.add(item['alg_id'] as int);
          }
        }
      }

      print("Directly fetched allergen IDs: $allergenIds");
      return allergenIds;
    } catch (e) {
      print("Error directly fetching allergen IDs: $e");
      return [];
    }
  }

  Future<void> _fetchIngredientTypes() async {
    try {
      final response = await _apiService.get('/api/ingredient-types/');
      final List<dynamic> typesJson = response['results'];
      _ingredientTypes = typesJson.map((json) => IngredientType.fromJson(json)).toList();
      await CacheManager.saveIngredientTypes(typesJson.cast<Map<String, dynamic>>());
    } catch (e) {
      throw Exception('Failed to load ingredient types: $e');
    }
  }

  Future<void> _fetchRecipes() async {
    try {
      final response = await _apiService.get('/api/recipes/');
      final List<dynamic> recipesJson = response['results'];
      _recipes = recipesJson.map((json) => Recipe.fromJson(json)).toList();
      await CacheManager.saveRecipes(recipesJson.cast<Map<String, dynamic>>());

      // Fetch details for each recipe (this could be optimized)
      Map<String, dynamic> recipeDetailsMap = {};
      for (var recipe in _recipes) {
        await _fetchRecipeDetails(recipe);
        // Store recipe details in the map
        recipeDetailsMap[recipe.id.toString()] = {
          'steps': recipe.steps.map((step) => step.toJson()).toList(),
          'ingredients': recipe.ingredients.map((ingredient) => ingredient.toJson()).toList(),
          'required_equipment': recipe.requiredEquipment.map((equip) => equip.id).toList(),
        };
      }

      // Save recipe details to cache
      await CacheManager.saveRecipeDetails(recipeDetailsMap);
    } catch (e) {
      throw Exception('Failed to load recipes: $e');
    }
  }

  Future<void> _fetchRecipeDetails(Recipe recipe) async {
    try {
      final response = await _apiService.get('/api/recipes/${recipe.id}/');

      // Process steps
      final List<dynamic> stepsJson = response['steps'] ?? [];
      recipe.steps = stepsJson.map((json) => RecipeStep.fromJson(json)).toList();

      // Process ingredients
      final List<dynamic> ingredientsJson = response['ingredients'] ?? [];
      recipe.ingredients = ingredientsJson.map((json) => RecipeIngredient.fromJson(json)).toList();

      // Process equipment
      final List<dynamic> equipmentJson = response['equipment'] ?? [];
      final equipmentIds = equipmentJson.map<int>((json) => json['eqp_id']).toList();
      recipe.requiredEquipment = _equipment
          .where((equip) => equipmentIds.contains(equip.id))
          .toList();
    } catch (e) {
      print('Error fetching details for recipe ${recipe.id}: $e');
    }
  }

  // In the DataRepository's _fetchUserAllergens method, we need to make sure it's correctly getting the user's allergies:

  Future<void> _fetchUserAllergens() async {
    if (_currentUser == null) return;

    try {
      // Get user allergens from the API - this URL should match your backend
      final response = await _apiService.get('/api/user-allergens/?limit=100');

      List<int> allergenIds = [];

      if (response.containsKey('results')) {
        final List<dynamic> userAllergensJson = response['results'];

        for (var item in userAllergensJson) {
          // Extract the allergen ID from the response
          // The exact structure depends on your API's response format
          if (item.containsKey('mua_alg_id')) {
            allergenIds.add(item['mua_alg_id']);
          }
        }
      }

      // Update the user's allergen IDs
      _currentUser!.allergenIds = allergenIds;

      // Now map these IDs to actual Allergen objects
      _currentUser!.allergens = [];
      for (var allergen in _allergens) {
        if (allergenIds.contains(allergen.id)) {
          _currentUser!.allergens.add(allergen);
        }
      }
    } catch (e) {
      print('Error loading user allergens: $e');
    }
  }



  Future<void> _fetchUserEquipment() async {
    if (_currentUser == null) return;

    try {
      _currentUser!.equipment = _equipment
          .where((equip) => _currentUser!.equipmentIds.contains(equip.id))
          .map((equip) => equip.copyWith(isSelected: true))
          .toList();
    } catch (e) {
      print('Error loading user equipment: $e');
    }
  }

  Future<void> _fetchUserIngredients() async {
    if (_currentUser == null) return;

    try {
      // Изменяем путь с '/api/users/refrigerator/' на '/api/refrigerator/'
      final response = await _apiService.get('/api/refrigerator/');
      final List<dynamic> itemsJson = response['results'];

      // Создаем список объектов UserIngredient
      final refrigeratorItems = itemsJson.map((json) => UserIngredient.fromJson(json)).toList();

      // Связываем с ингредиентами
      for (var item in refrigeratorItems) {
        final response = await _apiService.get('/api/ingredients/${item.ingredientId}/');
        item.ingredient = Ingredient.fromJson(response);

        // Связываем ингредиент с его типом
        if (_ingredientTypes.any((type) => type.id == item.ingredient!.ingredientTypeId)) {
          item.ingredient!.type = _ingredientTypes.firstWhere(
                (type) => type.id == item.ingredient!.ingredientTypeId,
          );
        }
      }

      _currentUser!.refrigeratorItems = refrigeratorItems;
    } catch (e) {
      print('Error loading user ingredients: $e');
    }
  }

  Future<void> _fetchFavoriteRecipes() async {
    if (_currentUser == null) return;

    try {
      // Изменяем путь с '/api/users/favorites/' на '/api/favorites/'
      final response = await _apiService.get('/api/favorites/');
      final List<dynamic> favoritesJson = response['results'];
      final favoriteIds = favoritesJson.map<int>((json) => json['fvr_rcp_id']).toList();

      // Mark recipes as favorites
      for (var recipe in _recipes) {
        if (favoriteIds.contains(recipe.id)) {
          recipe.isFavorite = true;
        }
      }

      _currentUser!.favoriteRecipes = _recipes.where((recipe) => recipe.isFavorite).toList();
    } catch (e) {
      print('Error loading favorite recipes: $e');
    }
  }

  Future<void> _fetchCurrentMealPlan() async {
    if (_currentUser == null) return;

    try {
      // Find current meal plan
      final response = await _apiService.get('/api/meal-plans/current/');
      if (response.containsKey('error')) {
        // No current meal plan
        return;
      }

      final weeklyPlan = WeeklyMealPlan.fromJson(response);
      Map<String, dynamic> mealPlanData = response;

      // Fetch daily plans
      final dailyPlansResponse = await _apiService.get('/api/meal-plans/${weeklyPlan.id}/days/');
      final List<dynamic> daysJson = dailyPlansResponse['results'];
      weeklyPlan.dailyPlans = daysJson.map((json) => DailyMealPlan.fromJson(json)).toList();
      mealPlanData['days'] = daysJson;

      // Fetch meals for each day
      for (var day in weeklyPlan.dailyPlans) {
        final mealsResponse = await _apiService.get('/api/meal-plans/days/${day.id}/meals/');
        final List<dynamic> mealsJson = mealsResponse['results'];

        // Create meals list
        final meals = <Meal>[];
        for (var mealJson in mealsJson) {
          final meal = Meal.fromJson(mealJson);

          // Fetch recipes for this meal
          final recipesResponse = await _apiService.get('/api/meals/${meal.id}/recipes/');
          final List<dynamic> recipeMappingsJson = recipesResponse['results'];

          for (var mapping in recipeMappingsJson) {
            final mealRecipe = MealRecipe.fromJson(mapping);
            final recipeId = mealRecipe.recipeId;

            // Find the recipe in our cached recipes
            if (_recipes.any((r) => r.id == recipeId)) {
              mealRecipe.recipe = _recipes.firstWhere((r) => r.id == recipeId);
              meal.recipes.add(mealRecipe);
            }
          }

          meals.add(meal);
        }

        day.meals = meals;

        // Add meals to the JSON data
        int dayIndex = mealPlanData['days'].indexWhere((d) => d['dmp_id'] == day.id);
        if (dayIndex != -1) {
          mealPlanData['days'][dayIndex]['meals'] = mealsJson;

          // Add meal recipes
          for (int i = 0; i < meals.length; i++) {
            if (i < mealsJson.length) {
              mealPlanData['days'][dayIndex]['meals'][i]['recipes'] =
                  meals[i].recipes.map((r) => {'mra_rcp_id': r.recipeId}).toList();
            }
          }
        }
      }

      _currentUser!.currentMealPlan = weeklyPlan;

      // Save meal plan to cache
      await CacheManager.saveMealPlan(mealPlanData);
    } catch (e) {
      print('Error loading meal plan: $e');
    }
  }

  Future<void> _fetchShoppingList() async {
    if (_currentUser == null) return;

    try {
      // Fetch user's shopping list
      final response = await _apiService.get('/api/shopping-list/');
      if (response.containsKey('error')) {
        // No shopping list
        return;
      }

      final shoppingList = ShoppingList.fromJson(response);
      Map<String, dynamic> shoppingListData = response;

      // Fetch items
      final itemsResponse = await _apiService.get('/api/shopping-list/${shoppingList.id}/items/');
      final List<dynamic> itemsJson = itemsResponse['results'];
      final items = itemsJson.map((json) => ShoppingListItem.fromJson(json)).toList();
      shoppingListData['items'] = itemsJson;

      // Link with ingredient types
      for (var item in items) {
        if (_ingredientTypes.any((type) => type.id == item.ingredientTypeId)) {
          item.ingredientType = _ingredientTypes.firstWhere(
                (type) => type.id == item.ingredientTypeId,
          );
        }
      }

      shoppingList.items = items;
      _currentUser!.shoppingList = shoppingList;

      // Save shopping list to cache
      await CacheManager.saveShoppingList(shoppingListData);
    } catch (e) {
      print('Error loading shopping list: $e');
    }
  }

  // Link references between objects to ensure data consistency
  void _linkReferences() {
    // Link recipe ingredients with ingredient types
    for (var recipe in _recipes) {
      for (var ingredient in recipe.ingredients) {
        if (_ingredientTypes.any((type) => type.id == ingredient.ingredientTypeId)) {
          ingredient.ingredientType = _ingredientTypes.firstWhere(
                (type) => type.id == ingredient.ingredientTypeId,
          );
        }
      }

      // Link step ingredients with ingredient types
      for (var step in recipe.steps) {
        for (var ingredient in step.ingredients) {
          if (_ingredientTypes.any((type) => type.id == ingredient.ingredientTypeId)) {
            ingredient.ingredientType = _ingredientTypes.firstWhere(
                  (type) => type.id == ingredient.ingredientTypeId,
            );
          }
        }
      }
    }
  }

  // Cache management
  Future<void> _loadFromCache() async {
    try {
      // Load user
      final userJson = await CacheManager.getUser();
      if (userJson != null) {
        _currentUser = User.fromJson(userJson);
      }

      // Load allergens
      final allergensJson = await CacheManager.getAllergens();
      if (allergensJson != null) {
        _allergens = allergensJson.map((json) => Allergen.fromJson(json)).toList();
      }

      // Load equipment
      final equipmentJson = await CacheManager.getEquipment();
      if (equipmentJson != null) {
        _equipment = equipmentJson.map((json) => Equipment.fromJson(json)).toList();
      }

      // Load ingredient types
      final typesJson = await CacheManager.getIngredientTypes();
      if (typesJson != null) {
        _ingredientTypes = typesJson.map((json) => IngredientType.fromJson(json)).toList();
      }

      // Load recipes
      final recipesJson = await CacheManager.getRecipes();
      if (recipesJson != null) {
        _recipes = recipesJson.map((json) => Recipe.fromJson(json)).toList();

        // Load recipe details if available
        final recipeDetailsMap = await CacheManager.getRecipeDetails();
        if (recipeDetailsMap != null) {
          for (var recipe in _recipes) {
            final detailsJson = recipeDetailsMap[recipe.id.toString()];
            if (detailsJson != null) {
              // Load steps
              if (detailsJson['steps'] != null) {
                recipe.steps = (detailsJson['steps'] as List)
                    .map((json) => RecipeStep.fromJson(Map<String, dynamic>.from(json)))
                    .toList();
              }

              // Load ingredients
              if (detailsJson['ingredients'] != null) {
                recipe.ingredients = (detailsJson['ingredients'] as List)
                    .map((json) => RecipeIngredient.fromJson(Map<String, dynamic>.from(json)))
                    .toList();
              }

              // Load equipment
              if (detailsJson['required_equipment'] != null) {
                final equipmentIds = List<int>.from(detailsJson['required_equipment']);
                recipe.requiredEquipment = _equipment
                    .where((equip) => equipmentIds.contains(equip.id))
                    .toList();
              }
            }
          }
        }
      }

      // Load user-specific data if user is loaded
      if (_currentUser != null) {
        // Load shopping list
        final shoppingListJson = await CacheManager.getShoppingList();
        if (shoppingListJson != null) {
          final shoppingList = ShoppingList.fromJson(shoppingListJson);

          // Load items
          if (shoppingListJson['items'] != null) {
            final items = (shoppingListJson['items'] as List)
                .map((json) => ShoppingListItem.fromJson(Map<String, dynamic>.from(json)))
                .toList();

            // Link with ingredient types
            for (var item in items) {
              if (_ingredientTypes.any((type) => type.id == item.ingredientTypeId)) {
                item.ingredientType = _ingredientTypes.firstWhere(
                      (type) => type.id == item.ingredientTypeId,
                );
              }
            }

            shoppingList.items = items;
          }

          _currentUser!.shoppingList = shoppingList;
        }

        // Load meal plan
        final mealPlanJson = await CacheManager.getMealPlan();
        if (mealPlanJson != null) {
          final weeklyPlan = WeeklyMealPlan.fromJson(mealPlanJson);

          // Load daily plans
          if (mealPlanJson['days'] != null) {
            final dailyPlans = (mealPlanJson['days'] as List)
                .map((json) => DailyMealPlan.fromJson(Map<String, dynamic>.from(json)))
                .toList();

            // Load meals for each day
            for (var day in dailyPlans) {
              final dayJson = (mealPlanJson['days'] as List)
                  .firstWhere((d) => d['dmp_id'] == day.id);

              if (dayJson['meals'] != null) {
                final meals = (dayJson['meals'] as List)
                    .map((json) => Meal.fromJson(Map<String, dynamic>.from(json)))
                    .toList();

                // Load recipes for each meal
                for (var meal in meals) {
                  final mealJson = (dayJson['meals'] as List)
                      .firstWhere((m) => m['adm_id'] == meal.id);

                  if (mealJson['recipes'] != null) {
                    for (var recipeMapping in (mealJson['recipes'] as List)) {
                      final recipeId = recipeMapping['mra_rcp_id'];

                      // Find the recipe in our cached recipes
                      if (_recipes.any((r) => r.id == recipeId)) {
                        final recipe = _recipes.firstWhere((r) => r.id == recipeId);
                        final mealRecipe = MealRecipe(
                          mealId: meal.id,
                          recipeId: recipeId,
                          recipe: recipe,
                        );
                        meal.recipes.add(mealRecipe);
                      }
                    }
                  }
                }

                day.meals = meals;
              }
            }

            weeklyPlan.dailyPlans = dailyPlans;
          }

          _currentUser!.currentMealPlan = weeklyPlan;
        }
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
  }

  void updateLocalUser(User updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Add this to your DataRepository class
  Future<List<Allergen>> getAllAllergens() async {
    try {
      // Direct API call to get all allergens with no pagination limit
      final response = await _apiService.get('/api/allergens/?limit=1000');

      if (response.containsKey('results')) {
        final List<dynamic> allergensJson = response['results'];
        return allergensJson.map((json) => Allergen.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching allergens: $e');
      return [];
    }
  }
}