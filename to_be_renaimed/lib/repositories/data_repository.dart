
import 'package:flutter/foundation.dart';
import 'package:to_be_renaimed/repositories/repositories/refrigerator_repository.dart';
import 'package:to_be_renaimed/repositories/repositories/shopping_list_repository.dart';
import '../models/enums.dart';
import '../models/ingredient.dart';
import '../models/ingredient_type.dart';
import '../models/refrigerator_item.dart';
import '../models/user.dart';
import '../models/allergen.dart';
import '../models/equipment.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/refrigerator_service.dart';
import 'repositories/user_repository.dart';
import 'repositories/allergen_repository.dart';
import 'repositories/equipment_repository.dart';
import 'repositories/recipe_repository.dart';
import '../services/shopping_list_service.dart';
import 'repositories/shopping_list_repository.dart';


import 'models/cache_config.dart';
import 'services/cache_service.dart';


class DataRepository with ChangeNotifier {
  final ApiService _apiService;

  
  late final UserRepository _userRepository;
  late final AllergenRepository _allergenRepository;
  late final EquipmentRepository _equipmentRepository;
  late final RecipeRepository _recipeRepository;
  late final RefrigeratorRepository _refrigeratorRepository;

  late final ShoppingListRepository _shoppingListRepository;
  bool _isLoadingShoppingList = false;
  DateTime? _lastShoppingListUpdate;


  bool get isLoadingShoppingList => _isLoadingShoppingList;
  List<ShoppingListItem> get shoppingListItems => _shoppingListRepository.items;
  double get shoppingListProgress => _shoppingListRepository.progress;

  
  List<Recipe> _recipes = [];

  
  DateTime? _lastProfileUpdate;
  DateTime? _lastAllergensUpdate;
  DateTime? _lastEquipmentUpdate;
  DateTime? _lastRecipesUpdate;
  DateTime? _lastRefrigeratorUpdate;
  DateTime? _lastRefrigeratorCategoriesUpdate;

  
  final Duration _updateInterval = const Duration(minutes: 5);

  
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _isLoadingProfile = false;
  bool _isLoadingAllergens = false;
  bool _isLoadingEquipment = false;

  
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  User? get user => _userRepository.user;
  List<Allergen> get allergens => _allergenRepository.allergens;
  List<Equipment> get equipment => _equipmentRepository.equipment;
  List<Recipe> get recipes => _recipeRepository.recipes;

  List<IngredientType> _allCategories = [];

  List<IngredientType> _userRefrigeratorCategories = [];

  List<RefrigeratorItem> _expiringItems = [];

  List<IngredientType> get allCategories => _allCategories;
  List<IngredientType> get userRefrigeratorCategories => _userRefrigeratorCategories;
  List<RefrigeratorItem> get expiringItems => _expiringItems;

  bool get isLoadingProfile => _isLoadingProfile;
  bool get isLoadingAllergens => _isLoadingAllergens;
  bool get isLoadingEquipment => _isLoadingEquipment;

  List<RefrigeratorItem> get refrigeratorItems => _refrigeratorRepository.items;
  RefrigeratorStats? get refrigeratorStats => _refrigeratorRepository.stats;

  ApiService get apiService => _apiService;

  DataRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    _userRepository = UserRepository(apiService: _apiService);
    _allergenRepository = AllergenRepository(apiService: _apiService);
    _equipmentRepository = EquipmentRepository(apiService: _apiService);
    _recipeRepository = RecipeRepository(apiService: _apiService);
    final shoppingListService = ShoppingListService(apiService: _apiService);
    _shoppingListRepository = ShoppingListRepository(shoppingListService: shoppingListService);

    final refrigeratorService = RefrigeratorService(apiService: _apiService);
    _refrigeratorRepository = RefrigeratorRepository(refrigeratorService: refrigeratorService);
  }


  Future<List<IngredientType>> getAllIngredientTypes({bool forceRefresh = false}) async {
    if (!forceRefresh && _allCategories.isNotEmpty) {
      return _allCategories;
    }

    try {
      final response = await _apiService.get('/api/ingredient-types/?limit=1000');

      if (response['results'] != null) {
        _allCategories = (response['results'] as List)
            .map((json) => IngredientType.fromJson(json))
            .toList();
      }

      notifyListeners();
      return _allCategories;
    } catch (e) {
      print("ERROR GETTING ALL INGREDIENT TYPES: $e");
      return _allCategories;
    }
  }

  Future<List<ShoppingListItem>> getShoppingListItems({
    bool onlyUnchecked = false,
    bool forceRefresh = false
  }) async {
    
    if (!forceRefresh && _shoppingListRepository.items.isNotEmpty && !_needsUpdate(_lastShoppingListUpdate)) {
      return onlyUnchecked
          ? _shoppingListRepository.items.where((item) => !item.isChecked).toList()
          : _shoppingListRepository.items;
    }

    _isLoadingShoppingList = true;
    notifyListeners();

    try {
      print("\n===== GETTING SHOPPING LIST ITEMS (forceRefresh: $forceRefresh, onlyUnchecked: $onlyUnchecked) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final items = await _shoppingListRepository.getItems(onlyUnchecked: onlyUnchecked, config: config);

      
      _lastShoppingListUpdate = DateTime.now();

      notifyListeners();
      return items;
    } catch (e) {
      print("ERROR GETTING SHOPPING LIST ITEMS: $e");
      _setError(e.toString());
      return [];
    } finally {
      _isLoadingShoppingList = false;
      notifyListeners();
    }
  }


  Future<ShoppingListItem?> addShoppingListItem({
    required int ingredientTypeId,
    required int quantity,
    required QuantityType quantityType,
  }) async {
    try {
      print("\n===== ADDING ITEM TO SHOPPING LIST =====");
      final item = await _shoppingListRepository.addItem(
        ingredientTypeId: ingredientTypeId,
        quantity: quantity,
        quantityType: quantityType,
      );

      
      _lastShoppingListUpdate = DateTime.now();

      notifyListeners();
      return item;
    } catch (e) {
      print("ERROR ADDING ITEM TO SHOPPING LIST: $e");
      _setError(e.toString());
      return null;
    }
  }


  Future<ShoppingListItem?> updateShoppingListItem({
    required int itemId,
    int? quantity,
    QuantityType? quantityType,
    bool? isChecked,
  }) async {
    try {
      print("\n===== UPDATING SHOPPING LIST ITEM =====");
      final item = await _shoppingListRepository.updateItem(
        itemId: itemId,
        quantity: quantity,
        quantityType: quantityType,
        isChecked: isChecked,
      );

      
      _lastShoppingListUpdate = DateTime.now();

      notifyListeners();
      return item;
    } catch (e) {
      print("ERROR UPDATING SHOPPING LIST ITEM: $e");
      _setError(e.toString());
      return null;
    }
  }


  Future<bool> removeShoppingListItem(int itemId) async {
    try {
      print("\n===== REMOVING ITEM FROM SHOPPING LIST =====");
      await _shoppingListRepository.removeItem(itemId);

      
      _lastShoppingListUpdate = DateTime.now();

      notifyListeners();
      return true;
    } catch (e) {
      print("ERROR REMOVING ITEM FROM SHOPPING LIST: $e");
      _setError(e.toString());
      return false;
    }
  }


  Future<bool> clearCheckedShoppingListItems() async {
    try {
      print("\n===== CLEARING CHECKED ITEMS FROM SHOPPING LIST =====");
      final deletedCount = await _shoppingListRepository.clearCheckedItems();

      
      _lastShoppingListUpdate = DateTime.now();

      notifyListeners();
      return deletedCount > 0;
    } catch (e) {
      print("ERROR CLEARING CHECKED ITEMS FROM SHOPPING LIST: $e");
      _setError(e.toString());
      return false;
    }
  }


  Future<bool> clearAllShoppingListItems() async {
    try {
      print("\n===== CLEARING ALL ITEMS FROM SHOPPING LIST =====");
      final deletedCount = await _shoppingListRepository.clearAllItems();

      
      _lastShoppingListUpdate = DateTime.now();

      notifyListeners();
      return deletedCount > 0;
    } catch (e) {
      print("ERROR CLEARING ALL ITEMS FROM SHOPPING LIST: $e");
      _setError(e.toString());
      return false;
    }
  }

  void _updateExpiringItems() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _expiringItems = refrigeratorItems.where((item) {
      if (item.ingredient?.expiryDate == null) return false;

      final expiryDate = DateTime(
        item.ingredient!.expiryDate!.year,
        item.ingredient!.expiryDate!.month,
        item.ingredient!.expiryDate!.day,
      );

      final daysDifference = expiryDate.difference(today).inDays;
      return daysDifference >= 0 && daysDifference <= 3;
    }).toList();

    
    _expiringItems.sort((a, b) {
      final aDate = a.ingredient!.expiryDate!;
      final bDate = b.ingredient!.expiryDate!;
      return aDate.compareTo(bDate);
    });

    notifyListeners();
  }


  void _updateUserRefrigeratorCategories() {
    
    final uniqueCategories = <int, IngredientType>{};

    for (var item in refrigeratorItems) {
      if (item.ingredient?.type != null) {
        uniqueCategories[item.ingredient!.type!.id] = item.ingredient!.type!;
      }
    }

    _userRefrigeratorCategories = uniqueCategories.values.toList();
    notifyListeners();
  }


  Future<List<RefrigeratorItem>> getRefrigeratorItems({bool forceRefresh = false}) async {
    
    if (!forceRefresh && _refrigeratorRepository.items.isNotEmpty && !_needsUpdate(_lastRefrigeratorUpdate)) {
      return _refrigeratorRepository.items;
    }

    _setLoading(true);
    try {
      print("\n===== GETTING REFRIGERATOR ITEMS (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final items = await _refrigeratorRepository.getItems(config: config);

      
      _updateUserRefrigeratorCategories();
      _updateExpiringItems();

      
      _lastRefrigeratorUpdate = DateTime.now();

      notifyListeners();
      return items;
    } catch (e) {
      print("ERROR GETTING REFRIGERATOR ITEMS: $e");
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }


  Future<RefrigeratorItem?> addRefrigeratorItem({
    required int ingredientId,
    required int quantity,
    required QuantityType quantityType,
  }) async {
    try {
      print("\n===== ADDING ITEM TO REFRIGERATOR =====");
      final item = await _refrigeratorRepository.addItem(
        ingredientId: ingredientId,
        quantity: quantity,
        quantityType: quantityType,
      );

      
      _updateUserRefrigeratorCategories();
      _updateExpiringItems();

      
      _lastRefrigeratorUpdate = DateTime.now();
      _lastRefrigeratorCategoriesUpdate = DateTime.now();

      notifyListeners();
      return item;
    } catch (e) {
      print("ERROR ADDING ITEM TO REFRIGERATOR: $e");
      _setError(e.toString());
      return null;
    }
  }


  Future<bool> removeRefrigeratorItem(int itemId) async {
    try {
      print("\n===== REMOVING ITEM FROM REFRIGERATOR =====");
      await _refrigeratorRepository.removeItem(itemId);

      
      _updateUserRefrigeratorCategories();
      _updateExpiringItems();

      
      _lastRefrigeratorUpdate = DateTime.now();
      _lastRefrigeratorCategoriesUpdate = DateTime.now();

      notifyListeners();
      return true;
    } catch (e) {
      print("ERROR REMOVING ITEM FROM REFRIGERATOR: $e");
      _setError(e.toString());
      return false;
    }
  }


  Future<void> initialize() async {
    _setLoading(true);
    try {
      print("\n===== INITIALIZING DATA REPOSITORY =====");

      
      await getAllIngredientTypes();

      
      await _userRepository.getUserProfile();
      await _allergenRepository.getAllAllergens();
      await _equipmentRepository.getAllEquipment();

      
      await getRecipes();
      await getRefrigeratorItems(); 

      
      _lastProfileUpdate = DateTime.now();
      _lastAllergensUpdate = DateTime.now();
      _lastEquipmentUpdate = DateTime.now();
      _lastRecipesUpdate = DateTime.now();

      _isInitialized = true;
      print("===== DATA REPOSITORY INITIALIZED =====");
    } catch (e) {
      print("ERROR DURING REPOSITORY INITIALIZATION: $e");
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }


  
  Future<bool> toggleFavoriteRecipe(int recipeId) async {
    try {
      print("\n===== TOGGLING FAVORITE STATUS FOR RECIPE ID: $recipeId =====");
      final success = await _recipeRepository.toggleFavoriteRecipe(recipeId);

      if (success) {
        notifyListeners();
      }

      return success;
    } catch (e) {
      print("ERROR TOGGLING FAVORITE: $e");
      _setError(e.toString());
      return false;
    }
  }

  
  bool _needsUpdate(DateTime? lastUpdate) {
    if (lastUpdate == null) return true;
    return DateTime.now().difference(lastUpdate) > _updateInterval;
  }

  Future<List<RefrigeratorItem>> getFilteredRefrigeratorItems({
    String? search,
    String? category,
    bool? expiringSoon,
    bool forceRefresh = false,
  }) async {
    try {
      print("\n===== GETTING FILTERED REFRIGERATOR ITEMS =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;

      
      final items = await _refrigeratorRepository.getFilteredItems(
        search: search,
        category: category,
        expiringSoon: expiringSoon,
        config: config,
      );

      notifyListeners();
      return items;
    } catch (e) {
      print("ERROR GETTING FILTERED REFRIGERATOR ITEMS: $e");
      _setError(e.toString());
      return [];
    }
  }

  Future<List<RefrigeratorItem>> getExpiringItems({bool forceRefresh = false}) async {
    try {
      print("\n===== GETTING EXPIRING ITEMS (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final items = await _refrigeratorRepository.getExpiringItems(config: config);

      notifyListeners();
      return items;
    } catch (e) {
      print("ERROR GETTING EXPIRING ITEMS: $e");
      _setError(e.toString());
      return [];
    }
  }


  Future<RefrigeratorStats> getRefrigeratorStats({bool forceRefresh = false}) async {
    try {
      print("\n===== GETTING REFRIGERATOR STATS (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final stats = await _refrigeratorRepository.getStats(config: config);

      notifyListeners();
      return stats;
    } catch (e) {
      print("ERROR GETTING REFRIGERATOR STATS: $e");
      _setError(e.toString());
      return RefrigeratorStats(totalItems: 0, expiringSoon: 0, expired: 0);
    }
  }

  Future<List<IngredientType>> getRefrigeratorCategories({bool forceRefresh = false}) async {
    
    if (!forceRefresh && _refrigeratorRepository.categories.isNotEmpty && !_needsUpdate(_lastRefrigeratorCategoriesUpdate)) {
      return _refrigeratorRepository.categories;
    }

    try {
      print("\n===== GETTING REFRIGERATOR CATEGORIES (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final categories = await _refrigeratorRepository.getCategories(config: config);

      
      _lastRefrigeratorCategoriesUpdate = DateTime.now();

      notifyListeners();
      return categories;
    } catch (e) {
      print("ERROR GETTING REFRIGERATOR CATEGORIES: $e");
      _setError(e.toString());
      return [];
    }
  }

  Future<RefrigeratorItem?> updateRefrigeratorItem({
    required int itemId,
    int? quantity,
    QuantityType? quantityType,
  }) async {
    try {
      print("\n===== UPDATING REFRIGERATOR ITEM =====");
      final item = await _refrigeratorRepository.updateItem(
        itemId: itemId,
        quantity: quantity,
        quantityType: quantityType,
      );

      
      _lastRefrigeratorUpdate = DateTime.now();

      notifyListeners();
      return item;
    } catch (e) {
      print("ERROR UPDATING REFRIGERATOR ITEM: $e");
      _setError(e.toString());
      return null;
    }
  }

  
  Future<List<Ingredient>> searchIngredients({
    required String query,
    int? typeId,
  }) async {
    try {
      return await _refrigeratorRepository.searchIngredients(
        query: query,
        typeId: typeId,
      );
    } catch (e) {
      print("ERROR SEARCHING INGREDIENTS: $e");
      _setError(e.toString());
      return [];
    }
  }


  
  Future<List<Recipe>> getRecipes({bool forceRefresh = false}) async {
    
    if (!forceRefresh && _recipeRepository.recipes.isNotEmpty && !_needsUpdate(_lastRecipesUpdate)) {
      return _recipeRepository.recipes;
    }

    _setLoading(true);
    try {
      print("\n===== GETTING RECIPES (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final recipes = await _recipeRepository.getAllRecipes(config: config);

      
      _lastRecipesUpdate = DateTime.now();

      notifyListeners();
      return recipes;
    } catch (e) {
      print("ERROR GETTING RECIPES: $e");
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  
  Future<List<Recipe>> getFavoriteRecipes({bool forceRefresh = false}) async {
    _setLoading(true);
    try {
      print("\n===== GETTING FAVORITE RECIPES (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final favoriteRecipes = await _recipeRepository.getFavoriteRecipes(config: config);

      notifyListeners();
      return favoriteRecipes;
    } catch (e) {
      print("ERROR GETTING FAVORITE RECIPES: $e");
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Recipe?> getRecipeDetails(int recipeId, {bool forceRefresh = false}) async {
    try {
      print("\n===== GETTING RECIPE DETAILS FOR ID: $recipeId (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      return await _recipeRepository.getRecipeDetails(recipeId, config: config);
    } catch (e) {
      print("ERROR GETTING RECIPE DETAILS: $e");
      _setError(e.toString());
      return null;
    }
  }


  
  Future<User?> getUserProfile({bool forceRefresh = false}) async {
    
    if (!forceRefresh && user != null && !_needsUpdate(_lastProfileUpdate)) {
      return user;
    }

    _isLoadingProfile = true;
    notifyListeners();

    try {
      print("\n===== GETTING USER PROFILE (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final userObj = await _userRepository.getUserProfile(config: config);

      
      if (userObj != null) {
        _lastProfileUpdate = DateTime.now();
      }

      notifyListeners();
      return userObj;
    } catch (e) {
      print("ERROR GETTING USER PROFILE: $e");
      _setError(e.toString());
      return null;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  
  Future<List<Equipment>> getEquipment({bool forceRefresh = false}) async {
    
    if (!forceRefresh && _equipmentRepository.equipment.isNotEmpty && !_needsUpdate(_lastEquipmentUpdate)) {
      
      if (user != null) {
        for (var equipment in _equipmentRepository.equipment) {
          equipment.isSelected = user!.equipmentIds.contains(equipment.id);
        }
      }
      return _equipmentRepository.equipment;
    }

    _isLoadingEquipment = true;
    notifyListeners();

    try {
      print("\n===== GETTING EQUIPMENT (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final equipmentList = await _equipmentRepository.getAllEquipment(config: config);

      
      if (user != null) {
        for (var equipment in equipmentList) {
          equipment.isSelected = user!.equipmentIds.contains(equipment.id);
        }
      }

      
      _lastEquipmentUpdate = DateTime.now();

      notifyListeners();
      return equipmentList;
    } catch (e) {
      print("ERROR GETTING EQUIPMENT: $e");
      _setError(e.toString());
      return [];
    } finally {
      _isLoadingEquipment = false;
      notifyListeners();
    }
  }

  
  Future<void> refreshUserData() async {
    _setLoading(true);
    try {
      print("\n===== REFRESHING USER DATA =====");

      
      if (_needsUpdate(_lastProfileUpdate)) {
        await _userRepository.getUserProfile(config: CacheConfig.refresh);
        _lastProfileUpdate = DateTime.now();
      }

      
      if (_needsUpdate(_lastAllergensUpdate)) {
        await refreshUserAllergens(silent: true);
        _lastAllergensUpdate = DateTime.now();
      } else {
        await _syncUserAllergens();
      }

      if (_needsUpdate(_lastEquipmentUpdate)) {
        await refreshUserEquipment(silent: true);
        _lastEquipmentUpdate = DateTime.now();
      } else {
        await _syncUserEquipment();
      }

      
      if (_needsUpdate(_lastRecipesUpdate)) {
        await getRecipes(forceRefresh: true);
        _lastRecipesUpdate = DateTime.now();
      }

      if (_needsUpdate(_lastRefrigeratorUpdate)) {
        await getRefrigeratorItems(forceRefresh: true);
        _lastRefrigeratorUpdate = DateTime.now();
      }

      
      if (_needsUpdate(_lastRefrigeratorCategoriesUpdate)) {
        await getRefrigeratorCategories(forceRefresh: true);
        _lastRefrigeratorCategoriesUpdate = DateTime.now();
      }

      print("===== USER DATA REFRESHED =====");
      notifyListeners();
    } catch (e) {
      print("ERROR REFRESHING USER DATA: $e");
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  
  Future<List<Allergen>> getAllAllergens({bool forceRefresh = false}) async {
    
    if (!forceRefresh && _allergenRepository.allergens.isNotEmpty && !_needsUpdate(_lastAllergensUpdate)) {
      
      if (user != null) {
        for (var allergen in _allergenRepository.allergens) {
          allergen.isSelected = user!.allergenIds.contains(allergen.id);
        }
      }
      return _allergenRepository.allergens;
    }

    _isLoadingAllergens = true;
    notifyListeners();

    try {
      print("\n===== GETTING ALL ALLERGENS (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;

      
      final allergensData = await _allergenRepository.getAllAllergens(config: config);

      
      if (user != null && user!.allergenIds.isNotEmpty) {
        for (var allergen in allergensData) {
          allergen.isSelected = user!.allergenIds.contains(allergen.id);
        }
      }

      
      _lastAllergensUpdate = DateTime.now();

      notifyListeners();
      return allergensData;
    } catch (e) {
      print("===== ERROR LOADING ALLERGENS: $e =====");
      _setError(e.toString());
      return [];
    } finally {
      _isLoadingAllergens = false;
      notifyListeners();
    }
  }

  
  Future<void> _syncUserAllergens() async {
    if (user == null || _allergenRepository.allergens.isEmpty) return;

    try {
      
      for (var allergen in _allergenRepository.allergens) {
        allergen.isSelected = user!.allergenIds.contains(allergen.id);
      }
    } catch (e) {
      print("ERROR SYNCING USER ALLERGENS: $e");
    }
  }

  
  Future<void> _syncUserEquipment() async {
    if (user == null || _equipmentRepository.equipment.isEmpty) return;

    try {
      
      for (var equipment in _equipmentRepository.equipment) {
        equipment.isSelected = user!.equipmentIds.contains(equipment.id);
      }
    } catch (e) {
      print("ERROR SYNCING USER EQUIPMENT: $e");
    }
  }

  
  Future<void> refreshUserAllergens({bool silent = false}) async {
    if (!silent) {
      _isLoadingAllergens = true;
      notifyListeners();
    }

    try {
      print("\n===== REFRESHING USER ALLERGENS =====");

      
      final allergenIds = await _userRepository.getUserAllergenIds(config: CacheConfig.refresh);

      
      if (user != null) {
        
        _userRepository.updateUserAllergensInMemory(allergenIds);

        
        for (var allergen in _allergenRepository.allergens) {
          allergen.isSelected = allergenIds.contains(allergen.id);
        }
      }

      
      _lastAllergensUpdate = DateTime.now();

      if (!silent) notifyListeners();
    } catch (e) {
      print("===== ERROR REFRESHING USER ALLERGENS: $e =====");
      if (!silent) _setError(e.toString());
    } finally {
      if (!silent) {
        _isLoadingAllergens = false;
        notifyListeners();
      }
    }
  }

  
  Future<void> refreshUserEquipment({bool silent = false}) async {
    if (!silent) {
      _isLoadingEquipment = true;
      notifyListeners();
    }

    try {
      print("\n===== REFRESHING USER EQUIPMENT =====");

      
      final equipmentIds = await _userRepository.getUserEquipmentIds(config: CacheConfig.refresh);

      
      if (user != null) {
        
        _userRepository.updateUserEquipmentInMemory(equipmentIds);

        
        for (var equipment in _equipmentRepository.equipment) {
          equipment.isSelected = equipmentIds.contains(equipment.id);
        }
      }

      
      _lastEquipmentUpdate = DateTime.now();

      if (!silent) notifyListeners();
    } catch (e) {
      print("===== ERROR REFRESHING USER EQUIPMENT: $e =====");
      if (!silent) _setError(e.toString());
    } finally {
      if (!silent) {
        _isLoadingEquipment = false;
        notifyListeners();
      }
    }
  }

  
  Future<bool> updateUserProfile(User updatedUser) async {
    _isLoadingProfile = true;
    notifyListeners();

    try {
      
      if (_userRepository.user != null) {
        _userRepository.updateUserAllergensInMemory(updatedUser.allergenIds);
        _userRepository.updateUserEquipmentInMemory(updatedUser.equipmentIds);

        
        for (var allergen in _allergenRepository.allergens) {
          allergen.isSelected = updatedUser.allergenIds.contains(allergen.id);
        }

        for (var equipment in _equipmentRepository.equipment) {
          equipment.isSelected = updatedUser.equipmentIds.contains(equipment.id);
        }

        
        notifyListeners();
      }

      
      final success = await _userRepository.updateUserProfile(updatedUser);

      if (success) {
        
        _lastProfileUpdate = DateTime.now();
        _lastAllergensUpdate = DateTime.now();
        _lastEquipmentUpdate = DateTime.now();

        
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Ошибка обновления профиля: $e';
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  
  Future<void> clearAllCache() async {
    await _userRepository.clearCache();
    await _allergenRepository.clearCache();
    await _equipmentRepository.clearCache();
    await _recipeRepository.clearCache();
    await _refrigeratorRepository.clearCache();

    
    _lastProfileUpdate = null;
    _lastAllergensUpdate = null;
    _lastEquipmentUpdate = null;
    _lastRecipesUpdate = null;
    _lastRefrigeratorUpdate = null;
    _lastRefrigeratorCategoriesUpdate = null;
  }
}