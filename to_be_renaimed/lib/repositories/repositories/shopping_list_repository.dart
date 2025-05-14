// lib/repositories/repositories/shopping_list_repository.dart
import 'package:flutter/foundation.dart';
import '../../models/ingredient.dart'; // Using the existing model
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

  // Since the server doesn't store checked items, we'll maintain this locally
  final Set<int> _checkedItemIds = {};

  ShoppingListRepository({required ShoppingListService shoppingListService})
      : _shoppingListService = shoppingListService;

  // Getters
  List<ShoppingListItem> get items => _items;
  int get shoppingListId => _shoppingListId;

  // Get progress percentage
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

  // Get shopping list ID
  Future<int> getShoppingListId({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING SHOPPING LIST ID (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    // If ID already in memory and no refresh required
    if (_shoppingListId > 0 && !cacheConfig.forceRefresh) {
      print("SHOPPING LIST ID ALREADY IN MEMORY: ID=$_shoppingListId");
      return _shoppingListId;
    }

    // Try to load from cache
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
          // If parsing error occurs, continue to load from API
        }
      }
    }

    // Load from API
    try {
      print("FETCHING SHOPPING LIST ID FROM API...");
      _shoppingListId = await _shoppingListService.getShoppingListId();

      // Save to cache
      print("SAVING SHOPPING LIST ID TO CACHE...");
      await CacheService.save(_idCacheKey, _shoppingListId);

      return _shoppingListId;
    } catch (e) {
      print("ERROR FETCHING SHOPPING LIST ID FROM API: $e");
      if (_shoppingListId > 0) {
        return _shoppingListId; // Return data from memory in case of error
      }
      rethrow;
    }
  }

  // Load checked items from cache
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

  // Save checked items to cache
  Future<void> _saveCheckedItems() async {
    await CacheService.save(_checkedItemsCacheKey, _checkedItemIds.toList());
  }

  // Get shopping list items
  Future<List<ShoppingListItem>> getItems({bool onlyUnchecked = false, CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING SHOPPING LIST ITEMS (forceRefresh: ${cacheConfig.forceRefresh}, onlyUnchecked: $onlyUnchecked) =====");

    // Ensure we have a shopping list ID
    if (_shoppingListId <= 0) {
      await getShoppingListId();
    }

    // Load checked items from cache
    await _loadCheckedItems();

    // If items already in memory and no refresh required
    if (_items.isNotEmpty && !cacheConfig.forceRefresh) {
      print("SHOPPING LIST ITEMS ALREADY IN MEMORY: ${_items.length} items");

      // Update checked status
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

    // Try to load from cache
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_itemsCacheKey, cacheConfig);

      if (cachedData != null) {
        print("LOADING SHOPPING LIST ITEMS FROM CACHE: ${cachedData.length} items");
        try {
          _items = [];
          for (var json in cachedData) {
            // Reconstructing ShoppingListItem
            final item = ShoppingListItem(
              id: json['id'],
              shoppingListId: json['shoppingListId'],
              ingredientTypeId: json['ingredientTypeId'],
              quantity: json['quantity'],
              quantityType: QuantityType.fromString(json['quantityType']),
            );

            // Parse ingredient type if available
            if (json['ingredientType'] != null) {
              item.ingredientType = IngredientType.fromJson(json['ingredientType']);
            }

            // Set checked status from our cached checked items set
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
          // If parsing error occurs, continue to load from API
        }
      }
    }

    // Load from API
    try {
      print("FETCHING SHOPPING LIST ITEMS FROM API...");
      _items = await _shoppingListService.getShoppingListItems();

      // Update checked status for existing items
      for (var item in _items) {
        item.isChecked = _checkedItemIds.contains(item.id);
      }

      // Save to cache - we need to convert to a format that can be saved
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

        return _items; // Return data from memory in case of error
      }
      rethrow;
    }
  }

  // Add an item to the shopping list
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

      // Add the new item to the in-memory list if we have items loaded
      if (_items.isNotEmpty) {
        _items.add(newItem);

        // Update the cache
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

  // Update an item in the shopping list
  Future<ShoppingListItem> updateItem({
    required int itemId,
    int? quantity,
    QuantityType? quantityType,
    bool? isChecked,
  }) async {
    try {
      print("\n===== UPDATING SHOPPING LIST ITEM =====");

      // Find the item in our list to get its data
      final itemIndex = _items.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) {
        // Item not found in local list, try to reload items
        await getItems(config: CacheConfig.refresh);
        throw Exception('Элемент не найден в списке покупок');
      }

      final item = _items[itemIndex];

      // Handle checked status client-side since server doesn't support it
      if (isChecked != null && isChecked != item.isChecked) {
        if (isChecked) {
          _checkedItemIds.add(itemId);
        } else {
          _checkedItemIds.remove(itemId);
        }

        // Save checked items to cache
        await _saveCheckedItems();

        // Update item in memory
        item.isChecked = isChecked;

        // If only updating checked status, we don't need to call the API
        if (quantity == null && quantityType == null) {
          return item;
        }
      }

      // If updating quantity or quantity type, call the API
      if (quantity != null || quantityType != null) {
        final updatedItem = await _shoppingListService.updateItem(
            itemId: itemId,
            shoppingListId: item.shoppingListId,
            ingredientTypeId: item.ingredientTypeId,
            quantity: quantity,
            quantityType: quantityType
        );

        // Set checked status from our local state
        updatedItem.isChecked = _checkedItemIds.contains(itemId);

        // Update the item in the in-memory list
        _items[itemIndex] = updatedItem;

        // Update the cache
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

  // Remove an item from the shopping list
  Future<void> removeItem(int itemId) async {
    try {
      print("\n===== REMOVING ITEM FROM SHOPPING LIST =====");

      // Find the item in our list to get its data
      final itemIndex = _items.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) {
        // Item not found in local list, try to reload items
        await getItems(config: CacheConfig.refresh);
        throw Exception('Элемент не найден в списке покупок');
      }

      final item = _items[itemIndex];

      // Remove the item from the API
      await _shoppingListService.removeItem(itemId, item.shoppingListId);

      // Remove the item from the in-memory list
      _items.removeAt(itemIndex);

      // Remove from checked items if it was checked
      _checkedItemIds.remove(itemId);
      await _saveCheckedItems();

      // Update the cache
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

  // Clear checked items from the shopping list
  Future<int> clearCheckedItems() async {
    try {
      print("\n===== CLEARING CHECKED ITEMS FROM SHOPPING LIST =====");

      // Since server doesn't support clearing by checked status,
      // we'll manually remove each checked item
      final checkedItems = _items.where((item) => _checkedItemIds.contains(item.id)).toList();

      if (checkedItems.isEmpty) {
        return 0;
      }

      // Ensure we have a shopping list ID
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

      // Remove checked items from the in-memory list
      _items.removeWhere((item) => _checkedItemIds.contains(item.id));

      // Clear checked item IDs
      _checkedItemIds.clear();
      await _saveCheckedItems();

      // Update the cache
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

  // Clear all items from the shopping list
  Future<int> clearAllItems() async {
    try {
      print("\n===== CLEARING ALL ITEMS FROM SHOPPING LIST =====");

      // Ensure we have a shopping list ID
      if (_shoppingListId <= 0) {
        await getShoppingListId();
      }

      final deletedCount = await _shoppingListService.clearAllItems(_shoppingListId);

      // Clear the in-memory list
      _items.clear();

      // Clear checked item IDs
      _checkedItemIds.clear();
      await _saveCheckedItems();

      // Update the cache
      await CacheService.save(_itemsCacheKey, []);

      return deletedCount;
    } catch (e) {
      print("ERROR CLEARING ALL ITEMS FROM SHOPPING LIST: $e");
      rethrow;
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    print("\n===== CLEARING SHOPPING LIST CACHE =====");
    await CacheService.clear(_idCacheKey);
    await CacheService.clear(_itemsCacheKey);
    await CacheService.clear(_checkedItemsCacheKey);
    print("SHOPPING LIST CACHE CLEARED");
  }
}