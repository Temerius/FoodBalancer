
import '../../models/refrigerator_item.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_type.dart';
import '../../models/enums.dart';
import '../../services/refrigerator_service.dart';
import '../services/cache_service.dart';
import '../models/cache_config.dart';

class RefrigeratorRepository {
  static const String _cacheKey = 'refrigerator_items';
  static const String _statsCacheKey = 'refrigerator_stats';
  static const String _categoriesCacheKey = 'refrigerator_categories';

  final RefrigeratorService _refrigeratorService;
  List<RefrigeratorItem> _items = [];
  RefrigeratorStats? _stats;
  List<IngredientType> _categories = [];

  RefrigeratorRepository({required RefrigeratorService refrigeratorService})
      : _refrigeratorService = refrigeratorService;

  
  List<RefrigeratorItem> get items => _items;
  RefrigeratorStats? get stats => _stats;
  List<IngredientType> get categories => _categories;

  
  Future<List<RefrigeratorItem>> getItems({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING REFRIGERATOR ITEMS (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    
    if (_items.isNotEmpty && !cacheConfig.forceRefresh) {
      print("REFRIGERATOR ITEMS ALREADY IN MEMORY: ${_items.length} items");
      return _items;
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        print("LOADING REFRIGERATOR ITEMS FROM CACHE: ${cachedData['items'].length} items");
        try {
          _items = (cachedData['items'] as List)
              .map((json) => RefrigeratorItem.fromJson(json))
              .toList();

          if (cachedData['stats'] != null) {
            _stats = RefrigeratorStats.fromJson(cachedData['stats']);
          }

          print("REFRIGERATOR ITEMS LOADED FROM CACHE SUCCESSFULLY: ${_items.length} items");
          return _items;
        } catch (e) {
          print("ERROR PARSING REFRIGERATOR ITEMS FROM CACHE: $e");
          
        }
      }
    }

    
    try {
      print("FETCHING REFRIGERATOR ITEMS FROM API...");
      final response = await _refrigeratorService.getRefrigeratorItems();

      _items = response.items;
      _stats = response.stats;

      
      print("SAVING REFRIGERATOR ITEMS TO CACHE...");
      await CacheService.save(_cacheKey, {
        'items': _items.map((item) => item.toJson()).toList(),
        'stats': _stats?.toJson(),
      });

      print("REFRIGERATOR ITEMS LOADED FROM API: ${_items.length} items");
      return _items;
    } catch (e) {
      print("ERROR FETCHING REFRIGERATOR ITEMS FROM API: $e");
      if (_items.isNotEmpty) {
        print("RETURNING REFRIGERATOR ITEMS FROM MEMORY DUE TO ERROR: ${_items.length} items");
        return _items; 
      }
      rethrow;
    }
  }

  
  Future<List<RefrigeratorItem>> getFilteredItems({
    String? search,
    String? category,
    bool? expiringSoon,
    CacheConfig? config,
  }) async {
    
    final allItems = await getItems(config: config);

    
    List<RefrigeratorItem> filtered = List.from(allItems);

    if (search != null && search.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = item.ingredient?.name?.toLowerCase() ?? '';
        final typeName = item.ingredient?.type?.name?.toLowerCase() ?? '';
        final searchLower = search.toLowerCase();
        return name.contains(searchLower) || typeName.contains(searchLower);
      }).toList();
    }

    if (category != null && category.isNotEmpty && category != 'Все') {
      filtered = filtered.where((item) {
        return item.ingredient?.type?.name == category;
      }).toList();
    }

    if (expiringSoon == true) {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 3));
      filtered = filtered.where((item) {
        final expiryDate = item.ingredient?.expiryDate;
        if (expiryDate == null) return false;
        return !expiryDate.isBefore(now) && !expiryDate.isAfter(future);
      }).toList();
    }

    return filtered;
  }

  
  Future<List<RefrigeratorItem>> getExpiringItems({CacheConfig? config}) async {
    return getFilteredItems(expiringSoon: true, config: config);
  }

  
  Future<RefrigeratorStats> getStats({CacheConfig? config}) async {
    
    await getItems(config: config);

    if (_stats != null) {
      return _stats!;
    }

    
    return RefrigeratorStats(totalItems: 0, expiringSoon: 0, expired: 0);
  }

  
  Future<List<IngredientType>> getCategories({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING REFRIGERATOR CATEGORIES (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    
    if (_categories.isNotEmpty && !cacheConfig.forceRefresh) {
      print("REFRIGERATOR CATEGORIES ALREADY IN MEMORY: ${_categories.length} items");
      return _categories;
    }

    
    if (_items.isNotEmpty && !cacheConfig.forceRefresh) {
      _extractCategoriesFromItems();
      if (_categories.isNotEmpty) {
        print("CATEGORIES EXTRACTED FROM ITEMS: ${_categories.length} items");
        await _saveCategoriesToCache();
        return _categories;
      }
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_categoriesCacheKey, cacheConfig);

      if (cachedData != null) {
        print("LOADING REFRIGERATOR CATEGORIES FROM CACHE: ${cachedData.length} items");
        try {
          _categories = (cachedData as List)
              .map((json) => IngredientType.fromJson(json))
              .toList();
          print("REFRIGERATOR CATEGORIES LOADED FROM CACHE SUCCESSFULLY: ${_categories.length} items");
          return _categories;
        } catch (e) {
          print("ERROR PARSING REFRIGERATOR CATEGORIES FROM CACHE: $e");
        }
      }
    }

    
    try {
      print("FETCHING REFRIGERATOR CATEGORIES FROM API...");
      _categories = await _refrigeratorService.getRefrigeratorCategories();

      
      await _saveCategoriesToCache();

      print("REFRIGERATOR CATEGORIES LOADED FROM API: ${_categories.length} items");
      return _categories;
    } catch (e) {
      print("ERROR FETCHING REFRIGERATOR CATEGORIES FROM API: $e");
      if (_categories.isNotEmpty) {
        print("RETURNING REFRIGERATOR CATEGORIES FROM MEMORY DUE TO ERROR: ${_categories.length} items");
        return _categories;
      }
      rethrow;
    }
  }

  
  void _extractCategoriesFromItems() {
    final uniqueCategories = <int, IngredientType>{};

    for (var item in _items) {
      if (item.ingredient?.type != null) {
        uniqueCategories[item.ingredient!.type!.id] = item.ingredient!.type!;
      }
    }

    _categories = uniqueCategories.values.toList();
  }

  
  Future<void> _saveCategoriesToCache() async {
    print("SAVING REFRIGERATOR CATEGORIES TO CACHE...");
    await CacheService.save(_categoriesCacheKey,
        _categories.map((cat) => cat.toJson()).toList());
  }

  
  Future<RefrigeratorItem> addItem({
    required int ingredientId,
    required int quantity,
    required QuantityType quantityType,
  }) async {
    try {
      final newItem = await _refrigeratorService.addItem(
        ingredientId: ingredientId,
        quantity: quantity,
        quantityType: quantityType,
      );

      
      _items.add(newItem);

      
      if (_stats != null) {
        _stats = RefrigeratorStats(
          totalItems: _stats!.totalItems + 1,
          expiringSoon: _stats!.expiringSoon,
          expired: _stats!.expired,
        );
      }

      
      if (newItem.ingredient?.type != null) {
        final hasCategory = _categories.any((cat) => cat.id == newItem.ingredient!.type!.id);
        if (!hasCategory) {
          _categories.add(newItem.ingredient!.type!);
          await _saveCategoriesToCache();
        }
      }

      
      await _updateCache();

      return newItem;
    } catch (e) {
      print("ERROR ADDING ITEM TO REFRIGERATOR: $e");
      rethrow;
    }
  }

  
  Future<AddMultipleResponse> addMultipleItems(List<AddItemRequest> items) async {
    try {
      final response = await _refrigeratorService.addMultipleItems(items);

      
      await _clearCache();

      return response;
    } catch (e) {
      print("ERROR ADDING MULTIPLE ITEMS TO REFRIGERATOR: $e");
      rethrow;
    }
  }

  
  Future<RefrigeratorItem> updateItem({
    required int itemId,
    int? quantity,
    QuantityType? quantityType,
  }) async {
    try {
      final updatedItem = await _refrigeratorService.updateItem(
        itemId: itemId,
        quantity: quantity,
        quantityType: quantityType,
      );

      
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
      }

      
      await _updateCache();

      return updatedItem;
    } catch (e) {
      print("ERROR UPDATING REFRIGERATOR ITEM: $e");
      rethrow;
    }
  }

  
  Future<void> removeItem(int itemId) async {
    try {
      await _refrigeratorService.removeItem(itemId);

      
      final removedItem = _items.firstWhere((item) => item.id == itemId, orElse: () => throw Exception());
      final removedType = removedItem.ingredient?.type;

      
      _items.removeWhere((item) => item.id == itemId);

      
      if (_stats != null) {
        _stats = RefrigeratorStats(
          totalItems: _stats!.totalItems - 1,
          expiringSoon: _stats!.expiringSoon,
          expired: _stats!.expired,
        );
      }

      
      if (removedType != null) {
        final hasItemsOfThisType = _items.any((item) =>
        item.ingredient?.type?.id == removedType.id);

        if (!hasItemsOfThisType) {
          
          _categories.removeWhere((cat) => cat.id == removedType.id);
          await _saveCategoriesToCache();
        }
      }

      
      await _updateCache();
    } catch (e) {
      print("ERROR REMOVING REFRIGERATOR ITEM: $e");
      rethrow;
    }
  }

  
  Future<List<Ingredient>> searchIngredients({
    required String query,
    int? typeId,
  }) async {
    try {
      return await _refrigeratorService.searchIngredients(
        query: query,
        typeId: typeId,
      );
    } catch (e) {
      print("ERROR SEARCHING INGREDIENTS: $e");
      rethrow;
    }
  }

  
  Future<void> _updateCache() async {
    await CacheService.save(_cacheKey, {
      'items': _items.map((item) => item.toJson()).toList(),
      'stats': _stats?.toJson(),
    });
  }

  
  Future<void> _clearCache() async {
    await CacheService.clear(_cacheKey);
    await CacheService.clear(_statsCacheKey);
    await CacheService.clear(_categoriesCacheKey);
  }

  
  Future<void> clearCache() async {
    print("\n===== CLEARING REFRIGERATOR CACHE =====");
    await _clearCache();
    print("REFRIGERATOR CACHE CLEARED");
  }
}