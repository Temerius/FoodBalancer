
import 'package:flutter/foundation.dart';
import '../../models/ingredient.dart'; 
import '../../models/enums.dart';
import '../../models/ingredient_type.dart';
import '../../services/shopping_list_service.dart';
import '../services/cache_service.dart';
import '../models/cache_config.dart';

class ShoppingListRepository {
  static const String _cacheKey = 'shopping_list';
  static const String _itemsCacheKey = 'shopping_list_items';
  static const String _checkedItemsCacheKey = 'shopping_list_checked_items';
  static const String _idCacheKey = 'shopping_list_id';

  final ShoppingListService _shoppingListService;
  List<ShoppingListItem> _items = [];
  int _shoppingListId = 0;

  
  final Set<int> _checkedItemIds = {};

  ShoppingListRepository({required ShoppingListService shoppingListService})
      : _shoppingListService = shoppingListService;

  
  List<ShoppingListItem> get items => _items;
  int get shoppingListId => _shoppingListId;

  
  double get progress {
    if (_items.isEmpty) return 0.0;

    int checkedCount = 0;
    for (var item in _items) {
      if (_checkedItemIds.contains(item.id)) {
        checkedCount++;
      }
    }

    return checkedCount / _items.length;
  }

  
  Future<int> getShoppingListId({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING SHOPPING LIST ID (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    
    if (_shoppingListId > 0 && !cacheConfig.forceRefresh) {
      print("SHOPPING LIST ID ALREADY IN MEMORY: ID=$_shoppingListId");
      return _shoppingListId;
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_idCacheKey, cacheConfig);

      if (cachedData != null) {
        print("LOADING SHOPPING LIST ID FROM CACHE");
        try {
          _shoppingListId = cachedData;
          print("SHOPPING LIST ID LOADED FROM CACHE SUCCESSFULLY: ID=$_shoppingListId");
          return _shoppingListId;
        } catch (e) {
          print("ERROR PARSING SHOPPING LIST ID FROM CACHE: $e");
          
        }
      }
    }

    
    try {
      print("FETCHING SHOPPING LIST ID FROM API...");
      _shoppingListId = await _shoppingListService.getShoppingListId();

      
      print("SAVING SHOPPING LIST ID TO CACHE...");
      await CacheService.save(_idCacheKey, _shoppingListId);

      return _shoppingListId;
    } catch (e) {
      print("ERROR FETCHING SHOPPING LIST ID FROM API: $e");
      if (_shoppingListId > 0) {
        return _shoppingListId; 
      }
      rethrow;
    }
  }

  
  Future<void> _loadCheckedItems() async {
    final cachedData = await CacheService.get(_checkedItemsCacheKey, CacheConfig.defaultConfig);

    if (cachedData != null && cachedData is List) {
      _checkedItemIds.clear();
      for (var id in cachedData) {
        if (id is int) {
          _checkedItemIds.add(id);
        }
      }

      print("LOADED ${_checkedItemIds.length} CHECKED ITEMS FROM CACHE");
    }
  }

  
  Future<void> _saveCheckedItems() async {
    await CacheService.save(_checkedItemsCacheKey, _checkedItemIds.toList());
  }

  
  Future<List<ShoppingListItem>> getItems({bool onlyUnchecked = false, CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING SHOPPING LIST ITEMS (forceRefresh: ${cacheConfig.forceRefresh}, onlyUnchecked: $onlyUnchecked) =====");

    
    if (_shoppingListId <= 0) {
      await getShoppingListId();
    }

    
    await _loadCheckedItems();

    
    if (_items.isNotEmpty && !cacheConfig.forceRefresh) {
      print("SHOPPING LIST ITEMS ALREADY IN MEMORY: ${_items.length} items");

      
      for (var item in _items) {
        item.isChecked = _checkedItemIds.contains(item.id);
      }

      if (onlyUnchecked) {
        final uncheckedItems = _items.where((item) => !item.isChecked).toList();
        print("RETURNING ${uncheckedItems.length} UNCHECKED ITEMS FROM MEMORY");
        return uncheckedItems;
      }

      return _items;
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_itemsCacheKey, cacheConfig);

      if (cachedData != null) {
        print("LOADING SHOPPING LIST ITEMS FROM CACHE: ${cachedData.length} items");
        try {
          _items = [];
          for (var json in cachedData) {
            
            final item = ShoppingListItem(
              id: json['id'],
              shoppingListId: json['shoppingListId'],
              ingredientTypeId: json['ingredientTypeId'],
              quantity: json['quantity'],
              quantityType: QuantityType.fromString(json['quantityType']),
            );

            
            if (json['ingredientType'] != null) {
              item.ingredientType = IngredientType.fromJson(json['ingredientType']);
            }

            
            item.isChecked = _checkedItemIds.contains(item.id);

            _items.add(item);
          }

          print("SHOPPING LIST ITEMS LOADED FROM CACHE SUCCESSFULLY: ${_items.length} items");

          if (onlyUnchecked) {
            final uncheckedItems = _items.where((item) => !item.isChecked).toList();
            print("RETURNING ${uncheckedItems.length} UNCHECKED ITEMS FROM CACHE");
            return uncheckedItems;
          }

          return _items;
        } catch (e) {
          print("ERROR PARSING SHOPPING LIST ITEMS FROM CACHE: $e");
          
        }
      }
    }

    
    try {
      print("FETCHING SHOPPING LIST ITEMS FROM API...");
      _items = await _shoppingListService.getShoppingListItems();

      
      for (var item in _items) {
        item.isChecked = _checkedItemIds.contains(item.id);
      }

      
      print("SAVING ALL SHOPPING LIST ITEMS TO CACHE...");
      final List<Map<String, dynamic>> itemsJson = _items.map((item) => {
        'id': item.id,
        'shoppingListId': item.shoppingListId,
        'ingredientTypeId': item.ingredientTypeId,
        'quantity': item.quantity,
        'quantityType': item.quantityType.toString().split('.').last,
        if (item.ingredientType != null) 'ingredientType': {
          'igt_id': item.ingredientType!.id,
          'igt_name': item.ingredientType!.name,
          if (item.ingredientType!.imageUrl != null) 'igt_img_url': item.ingredientType!.imageUrl,
        },
      }).toList();

      await CacheService.save(_itemsCacheKey, itemsJson);

      print("SHOPPING LIST ITEMS LOADED FROM API: ${_items.length} items");

      if (onlyUnchecked) {
        final uncheckedItems = _items.where((item) => !item.isChecked).toList();
        return uncheckedItems;
      }

      return _items;
    } catch (e) {
      print("ERROR FETCHING SHOPPING LIST ITEMS FROM API: $e");
      if (_items.isNotEmpty) {
        print("RETURNING SHOPPING LIST ITEMS FROM MEMORY DUE TO ERROR: ${_items.length} items");

        if (onlyUnchecked) {
          final uncheckedItems = _items.where((item) => !item.isChecked).toList();
          return uncheckedItems;
        }

        return _items; 
      }
      rethrow;
    }
  }

  
  Future<ShoppingListItem> addItem({
    required int ingredientTypeId,
    required int quantity,
    required QuantityType quantityType,
  }) async {
    try {
      print("\n===== ADDING ITEM TO SHOPPING LIST =====");
      final newItem = await _shoppingListService.addItem(
        ingredientTypeId: ingredientTypeId,
        quantity: quantity,
        quantityType: quantityType,
      );

      
      if (_items.isNotEmpty) {
        _items.add(newItem);

        
        final List<Map<String, dynamic>> itemsJson = _items.map((item) => {
          'id': item.id,
          'shoppingListId': item.shoppingListId,
          'ingredientTypeId': item.ingredientTypeId,
          'quantity': item.quantity,
          'quantityType': item.quantityType.toString().split('.').last,
          if (item.ingredientType != null) 'ingredientType': {
            'igt_id': item.ingredientType!.id,
            'igt_name': item.ingredientType!.name,
            if (item.ingredientType!.imageUrl != null) 'igt_img_url': item.ingredientType!.imageUrl,
          },
        }).toList();

        await CacheService.save(_itemsCacheKey, itemsJson);
      }

      return newItem;
    } catch (e) {
      print("ERROR ADDING ITEM TO SHOPPING LIST: $e");
      rethrow;
    }
  }

  
  Future<ShoppingListItem> updateItem({
    required int itemId,
    int? quantity,
    QuantityType? quantityType,
    bool? isChecked,
  }) async {
    try {
      print("\n===== UPDATING SHOPPING LIST ITEM =====");

      
      final itemIndex = _items.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) {
        
        await getItems(config: CacheConfig.refresh);
        throw Exception('Элемент не найден в списке покупок');
      }

      final item = _items[itemIndex];

      
      if (isChecked != null && isChecked != item.isChecked) {
        if (isChecked) {
          _checkedItemIds.add(itemId);
        } else {
          _checkedItemIds.remove(itemId);
        }

        
        await _saveCheckedItems();

        
        item.isChecked = isChecked;

        
        if (quantity == null && quantityType == null) {
          return item;
        }
      }

      
      if (quantity != null || quantityType != null) {
        final updatedItem = await _shoppingListService.updateItem(
            itemId: itemId,
            shoppingListId: item.shoppingListId,
            ingredientTypeId: item.ingredientTypeId,
            quantity: quantity,
            quantityType: quantityType
        );

        
        updatedItem.isChecked = _checkedItemIds.contains(itemId);

        
        _items[itemIndex] = updatedItem;

        
        final List<Map<String, dynamic>> itemsJson = _items.map((item) => {
          'id': item.id,
          'shoppingListId': item.shoppingListId,
          'ingredientTypeId': item.ingredientTypeId,
          'quantity': item.quantity,
          'quantityType': item.quantityType.toString().split('.').last,
          if (item.ingredientType != null) 'ingredientType': {
            'igt_id': item.ingredientType!.id,
            'igt_name': item.ingredientType!.name,
            if (item.ingredientType!.imageUrl != null) 'igt_img_url': item.ingredientType!.imageUrl,
          },
        }).toList();

        await CacheService.save(_itemsCacheKey, itemsJson);

        return updatedItem;
      }

      return item;
    } catch (e) {
      print("ERROR UPDATING SHOPPING LIST ITEM: $e");
      rethrow;
    }
  }

  
  Future<void> removeItem(int itemId) async {
    try {
      print("\n===== REMOVING ITEM FROM SHOPPING LIST =====");

      
      final itemIndex = _items.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) {
        
        await getItems(config: CacheConfig.refresh);
        throw Exception('Элемент не найден в списке покупок');
      }

      final item = _items[itemIndex];

      
      await _shoppingListService.removeItem(itemId, item.shoppingListId);

      
      _items.removeAt(itemIndex);

      
      _checkedItemIds.remove(itemId);
      await _saveCheckedItems();

      
      final List<Map<String, dynamic>> itemsJson = _items.map((item) => {
        'id': item.id,
        'shoppingListId': item.shoppingListId,
        'ingredientTypeId': item.ingredientTypeId,
        'quantity': item.quantity,
        'quantityType': item.quantityType.toString().split('.').last,
        if (item.ingredientType != null) 'ingredientType': {
          'igt_id': item.ingredientType!.id,
          'igt_name': item.ingredientType!.name,
          if (item.ingredientType!.imageUrl != null) 'igt_img_url': item.ingredientType!.imageUrl,
        },
      }).toList();

      await CacheService.save(_itemsCacheKey, itemsJson);
    } catch (e) {
      print("ERROR REMOVING ITEM FROM SHOPPING LIST: $e");
      rethrow;
    }
  }

  
  Future<int> clearCheckedItems() async {
    try {
      print("\n===== CLEARING CHECKED ITEMS FROM SHOPPING LIST =====");

      
      
      final checkedItems = _items.where((item) => _checkedItemIds.contains(item.id)).toList();

      if (checkedItems.isEmpty) {
        return 0;
      }

      
      if (_shoppingListId <= 0) {
        await getShoppingListId();
      }

      int deletedCount = 0;
      for (var item in checkedItems) {
        try {
          await _shoppingListService.removeItem(item.id!, _shoppingListId);
          deletedCount++;
        } catch (e) {
          print("Error removing checked item ${item.id}: $e");
        }
      }

      
      _items.removeWhere((item) => _checkedItemIds.contains(item.id));

      
      _checkedItemIds.clear();
      await _saveCheckedItems();

      
      final List<Map<String, dynamic>> itemsJson = _items.map((item) => {
        'id': item.id,
        'shoppingListId': item.shoppingListId,
        'ingredientTypeId': item.ingredientTypeId,
        'quantity': item.quantity,
        'quantityType': item.quantityType.toString().split('.').last,
        if (item.ingredientType != null) 'ingredientType': {
          'igt_id': item.ingredientType!.id,
          'igt_name': item.ingredientType!.name,
          if (item.ingredientType!.imageUrl != null) 'igt_img_url': item.ingredientType!.imageUrl,
        },
      }).toList();

      await CacheService.save(_itemsCacheKey, itemsJson);

      return deletedCount;
    } catch (e) {
      print("ERROR CLEARING CHECKED ITEMS FROM SHOPPING LIST: $e");
      rethrow;
    }
  }

  
  Future<int> clearAllItems() async {
    try {
      print("\n===== CLEARING ALL ITEMS FROM SHOPPING LIST =====");

      
      if (_shoppingListId <= 0) {
        await getShoppingListId();
      }

      final deletedCount = await _shoppingListService.clearAllItems(_shoppingListId);

      
      _items.clear();

      
      _checkedItemIds.clear();
      await _saveCheckedItems();

      
      await CacheService.save(_itemsCacheKey, []);

      return deletedCount;
    } catch (e) {
      print("ERROR CLEARING ALL ITEMS FROM SHOPPING LIST: $e");
      rethrow;
    }
  }

  
  Future<void> clearCache() async {
    print("\n===== CLEARING SHOPPING LIST CACHE =====");
    await CacheService.clear(_idCacheKey);
    await CacheService.clear(_itemsCacheKey);
    await CacheService.clear(_checkedItemsCacheKey);
    print("SHOPPING LIST CACHE CLEARED");
  }
}