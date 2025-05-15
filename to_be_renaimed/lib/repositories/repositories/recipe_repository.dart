
import 'package:flutter/cupertino.dart';

import '../../models/recipe.dart';
import '../services/cache_service.dart';
import '../models/cache_config.dart';
import '../../services/api_service.dart';

class RecipeRepository with ChangeNotifier{
  static const String _cacheKey = 'recipes';
  static const String _favoritesCacheKey = 'favorite_recipes';
  static const String _recipeDetailsCacheKey = 'recipe_details';

  final ApiService _apiService;
  List<Recipe> _recipes = [];
  List<int> _favoriteRecipeIds = [];

  
  final Map<int, Recipe> _recipeDetails = {};

  RecipeRepository({required ApiService apiService})
      : _apiService = apiService;

  
  List<Recipe> get recipes => _recipes;

  
  List<int> get favoriteRecipeIds => _favoriteRecipeIds;

  
  Future<List<Recipe>> getAllRecipes({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING ALL RECIPES (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    
    if (_recipes.isNotEmpty && !cacheConfig.forceRefresh) {
      print("RECIPES ALREADY IN MEMORY: ${_recipes.length} items");
      return _recipes;
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        print("LOADING RECIPES FROM CACHE: ${cachedData.length} items");
        final List<dynamic> recipesJson = cachedData;

        try {
          _recipes = recipesJson.map((json) => Recipe.fromJson(json)).toList();
          print("RECIPES LOADED FROM CACHE SUCCESSFULLY: ${_recipes.length} items");

          
          await _updateFavoriteStatus();

          notifyListeners();

          return _recipes;
        } catch (e) {
          print("ERROR PARSING RECIPES FROM CACHE: $e");
          
        }
      }
    }

    
    try {
      print("FETCHING RECIPES FROM API...");

      
      final allResults = await _apiService.getAllPaginatedResults('/api/recipes/?limit=100');
      print("ALL PAGES FETCHED, TOTAL RECIPES: ${allResults.length}");

      _recipes = allResults.map((json) => Recipe.fromJson(json)).toList();

      
      print("SAVING RECIPES TO CACHE...");
      await CacheService.save(_cacheKey, allResults);

      
      await _updateFavoriteStatus();

      return _recipes;
    } catch (e) {
      print("ERROR FETCHING RECIPES FROM API: $e");
      if (_recipes.isNotEmpty) {
        print("RETURNING RECIPES FROM MEMORY DUE TO ERROR: ${_recipes.length} items");
        return _recipes; 
      }
      rethrow;
    }
  }

  
  Future<List<Recipe>> getFavoriteRecipes({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;

    
    await getAllRecipes(config: cacheConfig);

    
    await _loadFavoriteRecipeIds(config: cacheConfig);

    
    return _recipes.where((recipe) => recipe.isFavorite).toList();
  }

  
  



  Future<Recipe?> getRecipeDetails(int recipeId, {CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING RECIPE DETAILS FOR ID: $recipeId (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    
    if (_recipeDetails.containsKey(recipeId) && !cacheConfig.forceRefresh) {
      print("RECIPE DETAILS ALREADY IN MEMORY");
      return _recipeDetails[recipeId];
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get("${_recipeDetailsCacheKey}_$recipeId", cacheConfig);

      if (cachedData != null) {
        print("LOADING RECIPE DETAILS FROM CACHE");
        try {
          final recipe = Recipe.fromJson(cachedData);
          _processRecipeIngredients(recipe);

          
          recipe.isFavorite = _favoriteRecipeIds.contains(recipeId);

          _recipeDetails[recipeId] = recipe;
          return recipe;
        } catch (e) {
          print("ERROR PARSING RECIPE DETAILS FROM CACHE: $e");
        }
      }
    }

    
    try {
      print("FETCHING RECIPE DETAILS FROM API...");
      final response = await _apiService.get('/api/recipes/$recipeId/');

      
      final recipe = Recipe.fromJson(response);

      
      if (_favoriteRecipeIds.isEmpty) {
        await _loadFavoriteRecipeIds();
      }

      
      recipe.isFavorite = _favoriteRecipeIds.contains(recipeId);

      
      _recipeDetails[recipeId] = recipe;

      
      final cacheData = Map<String, dynamic>.from(response);
      cacheData.remove('is_favorite');
      await CacheService.save("${_recipeDetailsCacheKey}_$recipeId", cacheData);

      return recipe;
    } catch (e) {
      print("ERROR FETCHING RECIPE DETAILS: $e");
      
      if (_recipeDetails.containsKey(recipeId)) {
        return _recipeDetails[recipeId];
      }
      rethrow;
    }
  }

  void _processRecipeIngredients(Recipe recipe) {
    if (recipe.steps.isEmpty) return;

    
    for (var step in recipe.steps) {
      
      for (var ingredient in step.ingredients) {
        if (ingredient.ingredientType != null) {
          
          ingredient.ingredientType!.determineCategory();
        }
      }
    }

    
    for (var ingredient in recipe.ingredients) {
      if (ingredient.ingredientType != null) {
        ingredient.ingredientType!.determineCategory();
      }
    }
  }

  
  Future<bool> toggleFavoriteRecipe(int recipeId) async {
    print("\n===== TOGGLING FAVORITE STATUS FOR RECIPE ID: $recipeId =====");

    try {
      
      final recipeIndex = _recipes.indexWhere((recipe) => recipe.id == recipeId);

      if (recipeIndex == -1) {
        print("RECIPE NOT FOUND IN MEMORY, LOADING FROM API...");
        
        final recipe = await getRecipeDetails(recipeId);
        if (recipe == null) {
          print("RECIPE NOT FOUND");
          return false;
        }
      }

      
      bool isFavorite = _favoriteRecipeIds.contains(recipeId);
      bool newStatus = !isFavorite;

      
      try {
        if (newStatus) {
          
          await _apiService.post('/api/favorites/', {'fvr_rcp_id': recipeId});
        } else {
          
          
          await _apiService.delete('/api/favorites/remove/', data: {'fvr_rcp_id': recipeId});
        }

        
        if (newStatus) {
          _favoriteRecipeIds.add(recipeId);
        } else {
          _favoriteRecipeIds.remove(recipeId);
        }

        
        if (recipeIndex != -1) {
          _recipes[recipeIndex] = _recipes[recipeIndex].copyWith(isFavorite: newStatus);
        }

        
        if (_recipeDetails.containsKey(recipeId)) {
          _recipeDetails[recipeId] = _recipeDetails[recipeId]!.copyWith(isFavorite: newStatus);
        }

        
        await CacheService.save(_favoritesCacheKey, _favoriteRecipeIds);

        return true;
      } catch (e) {
        print("API ERROR WHEN TOGGLING FAVORITE: $e");
        return false;
      }
    } catch (e) {
      print("ERROR TOGGLING FAVORITE: $e");
      return false;
    }
  }


  
  Future<List<int>> _loadFavoriteRecipeIds({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== LOADING FAVORITE RECIPE IDS (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    
    if (_favoriteRecipeIds.isNotEmpty && !cacheConfig.forceRefresh) {
      print("FAVORITE IDS ALREADY IN MEMORY: $_favoriteRecipeIds");
      return _favoriteRecipeIds;
    }

    
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
          print("FAVORITE IDS LOADED FROM CACHE: $_favoriteRecipeIds");
          return favoriteIds;
        } catch (e) {
          print("ERROR PARSING FAVORITE RECIPES FROM CACHE: $e");
        }
      }
    }

    
    try {
      print("FETCHING FAVORITE RECIPES FROM API...");
      final response = await _apiService.get('/api/favorites/');
      print("FAVORITE RECIPES API RESPONSE: $response");

      List<int> favoriteIds = [];

      
      if (response.containsKey('results')) {
        final List<dynamic> favoritesJson = response['results'];
        for (var item in favoritesJson) {
          _extractFavoriteRecipeId(item, favoriteIds);
        }
      } else if (response['raw_data'] is List) {
        
        final List<dynamic> favoritesJson = response['raw_data'];
        for (var item in favoritesJson) {
          _extractFavoriteRecipeId(item, favoriteIds);
        }
      } else if (response is List) {
        
        final List<dynamic> favoritesJson = response as List;
        for (var item in favoritesJson) {
          _extractFavoriteRecipeId(item, favoriteIds);
        }
      }

      print("FAVORITE IDS EXTRACTED: $favoriteIds");

      
      await CacheService.save(_favoritesCacheKey, favoriteIds);

      
      _favoriteRecipeIds = favoriteIds;

      return favoriteIds;
    } catch (e) {
      print("ERROR FETCHING FAVORITE RECIPES: $e");
      return _favoriteRecipeIds; 
    }
  }

  
  void _extractFavoriteRecipeId(dynamic item, List<int> favoriteIds) {
    if (item is Map<String, dynamic>) {
      dynamic recipeId;

      
      if (item.containsKey('recipe') && item['recipe'] is Map<String, dynamic>) {
        
        recipeId = item['recipe']['rcp_id'];
      } else if (item.containsKey('fvr_rcp_id')) {
        recipeId = item['fvr_rcp_id'];
      } else if (item.containsKey('recipe_id')) {
        recipeId = item['recipe_id'];
      } else if (item.containsKey('id')) {
        recipeId = item['id'];
      }

      
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
      
      favoriteIds.add(item);
    } else if (item is String) {
      
      int? parsedId = int.tryParse(item);
      if (parsedId != null) {
        favoriteIds.add(parsedId);
      }
    }
  }

  
  Future<void> _updateFavoriteStatus() async {
    print("\n===== UPDATING FAVORITE STATUS =====");
    print("CURRENT FAVORITE IDS: $_favoriteRecipeIds");
    print("TOTAL RECIPES IN MEMORY: ${_recipes.length}");

    
    if (_favoriteRecipeIds.isEmpty) {
      print("LOADING FAVORITE IDS...");
      await _loadFavoriteRecipeIds();
    }

    
    int updatedCount = 0;
    for (var i = 0; i < _recipes.length; i++) {
      bool isFavorite = _favoriteRecipeIds.contains(_recipes[i].id);

      if (_recipes[i].isFavorite != isFavorite) {
        print("UPDATING RECIPE ${_recipes[i].id} (${_recipes[i].title}): ${_recipes[i].isFavorite} -> $isFavorite");
        _recipes[i] = _recipes[i].copyWith(isFavorite: isFavorite);
        updatedCount++;
      }
    }

    print("UPDATED $updatedCount RECIPES' FAVORITE STATUS");
    print("===== FAVORITE STATUS UPDATE COMPLETE =====\n");

    
    notifyListeners();
  }

  
  Future<void> clearCache() async {
    print("\n===== CLEARING RECIPE CACHE =====");
    await CacheService.clear(_cacheKey);
    await CacheService.clear(_favoritesCacheKey);

    
    for (var recipeId in _recipeDetails.keys) {
      await CacheService.clear("${_recipeDetailsCacheKey}_$recipeId");
    }

    print("RECIPE CACHE CLEARED");
  }
}