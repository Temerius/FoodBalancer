// lib/services/shopping_list_service.dart
import 'dart:convert';
import '../models/ingredient.dart'; // Using the existing model
import '../models/enums.dart';
import '../models/ingredient_type.dart';
import 'api_service.dart';

class ShoppingListService {
  final ApiService _apiService;

  ShoppingListService({required ApiService apiService})
      : _apiService = apiService;

  // Get the shopping list items
  Future<List<ShoppingListItem>> getShoppingListItems() async {
    try {
      // Get the shopping list ID
      final shoppingListId = await getShoppingListId();

      // Get the shopping list items
      final response = await _apiService.get('/api/shopping-list/$shoppingListId/items/');

      List<ShoppingListItem> items = [];
      if (response['results'] != null) {
        for (var itemJson in response['results']) {
          // Extract ingredient type from API response
          IngredientType? ingredientType;
          if (itemJson['ingredient_type'] != null && itemJson['ingredient_type'] is Map<String, dynamic>) {
            ingredientType = IngredientType.fromJson(itemJson['ingredient_type']);
          }

          // Create a shopping list item
          final item = ShoppingListItem(
            id: itemJson['mis_id'],
            shoppingListId: shoppingListId,
            ingredientTypeId: itemJson['ingredient_type']['igt_id'] ?? 0,
            quantity: itemJson['mis_quantity'] ?? 0,
            quantityType: QuantityType.fromString(itemJson['mis_quantity_type'] ?? 'grams'),
            ingredientType: ingredientType,
          );

          // Since we don't have is_checked field on server, all items are unchecked by default
          item.isChecked = false;

          items.add(item);
        }
      }

      return items;
    } catch (e) {
      print('Error in getShoppingListItems: $e');
      throw Exception('Ошибка при получении элементов списка покупок: $e');
    }
  }

  // Add a new item to the shopping list
  Future<ShoppingListItem> addItem({
    required int ingredientTypeId,
    required int quantity,
    required QuantityType quantityType,
  }) async {
    try {
      // Get the shopping list ID
      final shoppingListId = await getShoppingListId();

      // Add the item to the shopping list
      final response = await _apiService.post(
        '/api/shopping-list/$shoppingListId/add_item/',
        {
          'mis_igt_id': ingredientTypeId,
          'mis_quantity': quantity,
          'mis_quantity_type': quantityType.toString().split('.').last,
        },
      );

      // Extract ingredient type
      IngredientType? ingredientType;
      if (response['ingredient_type'] != null && response['ingredient_type'] is Map<String, dynamic>) {
        ingredientType = IngredientType.fromJson(response['ingredient_type']);
      }

      // Create the shopping list item
      final item = ShoppingListItem(
        id: response['mis_id'],
        shoppingListId: shoppingListId,
        ingredientTypeId: response['ingredient_type']['igt_id'] ?? ingredientTypeId,
        quantity: response['mis_quantity'] ?? quantity,
        quantityType: QuantityType.fromString(response['mis_quantity_type'] ?? quantityType.toString().split('.').last),
        ingredientType: ingredientType,
      );

      // All new items are unchecked by default
      item.isChecked = false;

      return item;
    } catch (e) {
      print('Error in addItem: $e');
      throw Exception('Ошибка при добавлении элемента в список покупок: $e');
    }
  }

  // Update an item in the shopping list
  Future<ShoppingListItem> updateItem({
    required int itemId,
    required int shoppingListId,
    required int ingredientTypeId,
    int? quantity,
    QuantityType? quantityType,
    bool? isChecked,
  }) async {
    try {
      // Prepare the data to update
      Map<String, dynamic> data = {
        'item_id': itemId,
      };

      if (quantity != null) {
        data['mis_quantity'] = quantity;
      }

      if (quantityType != null) {
        data['mis_quantity_type'] = quantityType.toString().split('.').last;
      }

      // Note: is_checked is not stored on the server, so we only handle it client-side

      // Update the item
      final response = await _apiService.post(
        '/api/shopping-list/$shoppingListId/update_item/',
        data,
      );

      // Extract ingredient type
      IngredientType? ingredientType;
      if (response['ingredient_type'] != null && response['ingredient_type'] is Map<String, dynamic>) {
        ingredientType = IngredientType.fromJson(response['ingredient_type']);
      }

      // Create the updated item
      final updatedItem = ShoppingListItem(
        id: response['mis_id'],
        shoppingListId: shoppingListId,
        ingredientTypeId: response['ingredient_type']['igt_id'] ?? ingredientTypeId,
        quantity: response['mis_quantity'] ?? 0,
        quantityType: QuantityType.fromString(response['mis_quantity_type'] ?? 'grams'),
        ingredientType: ingredientType,
      );

      // Set checked status if provided (client-side only)
      if (isChecked != null) {
        updatedItem.isChecked = isChecked;
      }

      return updatedItem;
    } catch (e) {
      print('Error in updateItem: $e');
      throw Exception('Ошибка при обновлении элемента списка покупок: $e');
    }
  }

  // Remove an item from the shopping list
  Future<void> removeItem(int itemId, int shoppingListId) async {
    try {
      // Remove the item
      await _apiService.post(
        '/api/shopping-list/$shoppingListId/remove_item/',
        {
          'item_id': itemId,
        },
      );
    } catch (e) {
      print('Error in removeItem: $e');
      throw Exception('Ошибка при удалении элемента из списка покупок: $e');
    }
  }

  // Clear all items from the shopping list
  Future<int> clearAllItems(int shoppingListId) async {
    try {
      // Clear all items
      final response = await _apiService.post(
        '/api/shopping-list/$shoppingListId/clear_all/',
        {},
      );

      return response['deleted_count'] ?? 0;
    } catch (e) {
      print('Error in clearAllItems: $e');
      throw Exception('Ошибка при очистке списка покупок: $e');
    }
  }

  // Get the shopping list ID
  Future<int> getShoppingListId() async {
    try {
      final response = await _apiService.get('/api/shopping-list/');
      return response['spl_id'] ?? 0;
    } catch (e) {
      print('Error in getShoppingListId: $e');
      throw Exception('Ошибка при получении ID списка покупок: $e');
    }
  }
}