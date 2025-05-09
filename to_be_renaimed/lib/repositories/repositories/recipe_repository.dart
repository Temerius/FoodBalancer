// lib/repositories/repositories/recipe_repository.dart
import '../../models/recipe.dart';
import '../services/cache_service.dart';
import '../models/cache_config.dart';
import '../../services/api_service.dart';

class RecipeRepository {
  static const String _cacheKey = 'recipes';
  static const String _favoritesCacheKey = 'favorite_recipes';
  static const String _recipeDetailsCacheKey = 'recipe_details';

  final ApiService _apiService;
  List<Recipe> _recipes = [];
  List<int> _favoriteRecipeIds = [];

  // Map to store detailed recipe data
  final Map<int, Recipe> _recipeDetails = {};

  RecipeRepository({required ApiService apiService})
      : _apiService = apiService;

  // Getter for recipes
  List<Recipe> get recipes => _recipes;

  // Getter for favorite recipe IDs
  List<int> get favoriteRecipeIds => _favoriteRecipeIds;

  // Get all recipes
  Future<List<Recipe>> getAllRecipes({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING ALL RECIPES (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    // If recipes already in memory and no update required
    if (_recipes.isNotEmpty && !cacheConfig.forceRefresh) {
      print("RECIPES ALREADY IN MEMORY: ${_recipes.length} items");
      return _recipes;
    }

    // Try to load from cache
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        print("LOADING RECIPES FROM CACHE: ${cachedData.length} items");
        final List<dynamic> recipesJson = cachedData;

        try {
          _recipes = recipesJson.map((json) => Recipe.fromJson(json)).toList();
          print("RECIPES LOADED FROM CACHE SUCCESSFULLY: ${_recipes.length} items");

          // Get favorite recipes to update isFavorite flag
          await _updateFavoriteStatus();

          return _recipes;
        } catch (e) {
          print("ERROR PARSING RECIPES FROM CACHE: $e");
          // If parsing error occurs, continue to load from API
        }
      }
    }

    // Load from API
    try {
      print("FETCHING RECIPES FROM API...");

      // Get all paginated results
      final allResults = await _apiService.getAllPaginatedResults('/api/recipes/?limit=100');
      print("ALL PAGES FETCHED, TOTAL RECIPES: ${allResults.length}");

      _recipes = allResults.map((json) => Recipe.fromJson(json)).toList();

      // Save to cache
      print("SAVING RECIPES TO CACHE...");
      await CacheService.save(_cacheKey, allResults);

      // Get favorite recipes to update isFavorite flag
      await _updateFavoriteStatus();

      return _recipes;
    } catch (e) {
      print("ERROR FETCHING RECIPES FROM API: $e");
      if (_recipes.isNotEmpty) {
        print("RETURNING RECIPES FROM MEMORY DUE TO ERROR: ${_recipes.length} items");
        return _recipes; // Return data from memory in case of error
      }
      rethrow;
    }
  }

  // Get favorite recipes
  Future<List<Recipe>> getFavoriteRecipes({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;

    // Make sure we have the latest recipes first
    await getAllRecipes(config: cacheConfig);

    // Then get the latest favorite IDs
    await _loadFavoriteRecipeIds(config: cacheConfig);

    // Filter recipes by favorite status
    return _recipes.where((recipe) => recipe.isFavorite).toList();
  }

  // Get recipe details
  Future<Recipe?> getRecipeDetails(int recipeId, {CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING RECIPE DETAILS FOR ID: $recipeId (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    // Check if details already in memory
    if (_recipeDetails.containsKey(recipeId) && !cacheConfig.forceRefresh) {
      print("RECIPE DETAILS ALREADY IN MEMORY");
      return _recipeDetails[recipeId];
    }

    // Try to load from cache
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get("${_recipeDetailsCacheKey}_$recipeId", cacheConfig);

      if (cachedData != null) {
        print("LOADING RECIPE DETAILS FROM CACHE");
        try {
          final recipe = Recipe.fromJson(cachedData);
          _processRecipeIngredients(recipe);
          _recipeDetails[recipeId] = recipe;
          return recipe;
        } catch (e) {
          print("ERROR PARSING RECIPE DETAILS FROM CACHE: $e");
        }
      }
    }

    // Load from API
    try {
      print("FETCHING RECIPE DETAILS FROM API...");
      final response = await _apiService.get('/api/recipes/$recipeId/');

      // Parse recipe details
      final recipe = Recipe.fromJson(response);

      // Save to memory
      _recipeDetails[recipeId] = recipe;

      // Save to cache
      await CacheService.save("${_recipeDetailsCacheKey}_$recipeId", response);

      return recipe;
    } catch (e) {
      print("ERROR FETCHING RECIPE DETAILS: $e");
      // If already in cache, return that
      if (_recipeDetails.containsKey(recipeId)) {
        return _recipeDetails[recipeId];
      }
      rethrow;
    }
  }

  void _processRecipeIngredients(Recipe recipe) {
    if (recipe.steps.isEmpty) return;

    // Для каждого шага рецепта
    for (var step in recipe.steps) {
      // Для каждого ингредиента в шаге
      for (var ingredient in step.ingredients) {
        if (ingredient.ingredientType != null) {
          // Определяем категорию на основе имени типа ингредиента
          ingredient.ingredientType!.determineCategory();
        }
      }
    }

    // Также для основных ингредиентов рецепта
    for (var ingredient in recipe.ingredients) {
      if (ingredient.ingredientType != null) {
        ingredient.ingredientType!.determineCategory();
      }
    }
  }

  // Toggle favorite status for a recipe
  Future<bool> toggleFavoriteRecipe(int recipeId) async {
    print("\n===== TOGGLING FAVORITE STATUS FOR RECIPE ID: $recipeId =====");

    try {
      // Find the recipe in our list
      final recipeIndex = _recipes.indexWhere((recipe) => recipe.id == recipeId);

      if (recipeIndex == -1) {
        print("RECIPE NOT FOUND IN MEMORY, LOADING FROM API...");
        // Try to load the recipe if it's not in memory
        final recipe = await getRecipeDetails(recipeId);
        if (recipe == null) {
          print("RECIPE NOT FOUND");
          return false;
        }
      }

      // Get the current favorite status
      bool isFavorite = _favoriteRecipeIds.contains(recipeId);
      bool newStatus = !isFavorite;

      // Make API call to update favorite status
      try {
        if (newStatus) {
          // Add to favorites
          await _apiService.post('/api/favorites/', {'recipe_id': recipeId});
        } else {
          // Remove from favorites
          await _apiService.delete('/api/favorites/$recipeId/');
        }

        // Update local status
        if (newStatus) {
          _favoriteRecipeIds.add(recipeId);
        } else {
          _favoriteRecipeIds.remove(recipeId);
        }

        // Update recipe in memory
        if (recipeIndex != -1) {
          _recipes[recipeIndex] = _recipes[recipeIndex].copyWith(isFavorite: newStatus);
        }

        // Update cache
        await CacheService.save(_favoritesCacheKey, _favoriteRecipeIds);

        return true;
      } catch (e) {
        print("API ERROR WHEN TOGGLING FAVORITE: $e");
        // We could still update the local status even if API fails
        // but it's better to keep consistency with the server
        return false;
      }
    } catch (e) {
      print("ERROR TOGGLING FAVORITE: $e");
      return false;
    }
  }

  // Load favorite recipe IDs from API or cache
  Future<List<int>> _loadFavoriteRecipeIds({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;

    // Return from memory if already loaded and not force refreshing
    if (_favoriteRecipeIds.isNotEmpty && !cacheConfig.forceRefresh) {
      return _favoriteRecipeIds;
    }

    // Try to load from cache
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_favoritesCacheKey, cacheConfig);

      if (cachedData != null) {
        try {
          List<int> favoriteIds = [];

          if (cachedData is List) {
            for (var id in cachedData) {
              if (id is int) {
                favoriteIds.add(id);
              } else if (id is String) {
                int? parsedId = int.tryParse(id);
                if (parsedId != null) {
                  favoriteIds.add(parsedId);
                }
              }
            }
          }

          _favoriteRecipeIds = favoriteIds;
          return favoriteIds;
        } catch (e) {
          print("ERROR PARSING FAVORITE RECIPES FROM CACHE: $e");
        }
      }
    }

    // Load from API
    try {
      final response = await _apiService.get('/api/favorites/');
      List<int> favoriteIds = [];

      if (response.containsKey('results')) {
        final List<dynamic> favoritesJson = response['results'];

        for (var item in favoritesJson) {
          _extractFavoriteRecipeId(item, favoriteIds);
        }
      } else {
        final rawData = response['raw_data'] ?? response;

        if (rawData is List) {
          for (var item in rawData) {
            _extractFavoriteRecipeId(item, favoriteIds);
          }
        }
      }

      // Save to cache
      await CacheService.save(_favoritesCacheKey, favoriteIds);

      // Update member variable
      _favoriteRecipeIds = favoriteIds;

      return favoriteIds;
    } catch (e) {
      print("ERROR FETCHING FAVORITE RECIPES: $e");
      return _favoriteRecipeIds; // Return data from memory in case of error
    }
  }

  // Helper method to extract recipe ID from a favorite item
  void _extractFavoriteRecipeId(dynamic item, List<int> favoriteIds) {
    if (item is Map<String, dynamic>) {
      // Check different possible keys for recipe ID
      dynamic recipeId;

      if (item.containsKey('fvr_rcp_id')) {
        recipeId = item['fvr_rcp_id'];
      } else if (item.containsKey('recipe_id')) {
        recipeId = item['recipe_id'];
      } else if (item.containsKey('id')) {
        recipeId = item['id'];
      }

      // If found ID, convert to int
      if (recipeId != null) {
        if (recipeId is int) {
          favoriteIds.add(recipeId);
        } else if (recipeId is String) {
          int? parsedId = int.tryParse(recipeId);
          if (parsedId != null) {
            favoriteIds.add(parsedId);
          }
        }
      }
    } else if (item is int) {
      // If item is a number, it might be a direct ID
      favoriteIds.add(item);
    } else if (item is String) {
      // If item is a string, try to convert to number
      int? parsedId = int.tryParse(item);
      if (parsedId != null) {
        favoriteIds.add(parsedId);
      }
    }
  }

  // Update favorite status for all recipes
  Future<void> _updateFavoriteStatus() async {
    // Load favorite recipe IDs
    await _loadFavoriteRecipeIds();

    // Update isFavorite flag for all recipes
    for (var i = 0; i < _recipes.length; i++) {
      bool isFavorite = _favoriteRecipeIds.contains(_recipes[i].id);
      if (_recipes[i].isFavorite != isFavorite) {
        _recipes[i] = _recipes[i].copyWith(isFavorite: isFavorite);
      }
    }
  }

  // Clear recipe cache
  Future<void> clearCache() async {
    print("\n===== CLEARING RECIPE CACHE =====");
    await CacheService.clear(_cacheKey);
    await CacheService.clear(_favoritesCacheKey);

    // Clear recipe details cache
    for (var recipeId in _recipeDetails.keys) {
      await CacheService.clear("${_recipeDetailsCacheKey}_$recipeId");
    }

    print("RECIPE CACHE CLEARED");
  }
}