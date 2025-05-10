// lib/services/refrigerator_service.dart
import 'dart:convert';
import '../models/refrigerator_item.dart';
import '../models/ingredient.dart';
import '../models/ingredient_type.dart';
import '../models/enums.dart';
import 'api_service.dart';

class RefrigeratorService {
  final ApiService _apiService;

  RefrigeratorService({required ApiService apiService})
      : _apiService = apiService;

  // Получить все продукты в холодильнике (без пагинации)
  Future<RefrigeratorResponse> getRefrigeratorItems({
    String? search,
    String? category,
    bool? expiringSoon,
  }) async {
    Map<String, String> params = {};

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }

    if (expiringSoon == true) {
      params['expiring_soon'] = 'true';
    }

    // Создаем query string
    String queryString = '';
    if (params.isNotEmpty) {
      queryString = '?' + params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    try {
      final response = await _apiService.get('/api/refrigerator/$queryString');

      // Возвращаем обработанный ответ
      return RefrigeratorResponse.fromJson(response);
    } catch (e) {
      print('Error in getRefrigeratorItems: $e');
      throw Exception('Ошибка при получении продуктов: $e');
    }
  }

  // Получить продукты с истекающим сроком годности
  Future<List<RefrigeratorItem>> getExpiringItems() async {
    try {
      final response = await _apiService.get('/api/refrigerator/expiring_soon/');

      // response может быть либо списком, либо объектом с ключом results
      List<dynamic> itemsJson;

      if (response is List) {
        itemsJson = response as List;
      } else if (response is Map<String, dynamic>) {
        itemsJson = response['results'] ?? response;
      } else {
        itemsJson = [];
      }

      return itemsJson.map((json) => RefrigeratorItem.fromJson(json)).toList();
    } catch (e) {
      print('Error in getExpiringItems: $e');
      throw Exception('Ошибка при получении истекающих продуктов: $e');
    }
  }

  // Получить статистику холодильника
  Future<RefrigeratorStats> getRefrigeratorStats() async {
    try {
      // Загружаем все продукты для получения статистики
      final response = await getRefrigeratorItems();
      return response.stats;
    } catch (e) {
      print('Error in getRefrigeratorStats: $e');
      throw Exception('Ошибка при получении статистики: $e');
    }
  }

  // Получить категории (типы) продуктов в холодильнике
  Future<List<IngredientType>> getRefrigeratorCategories() async {
    try {
      final response = await _apiService.get('/api/refrigerator/categories/');

      List<dynamic> categoriesJson;

      if (response is List) {
        categoriesJson = response as List;
      } else if (response is Map<String, dynamic>) {
        categoriesJson = response['results'] ?? response;
      } else {
        categoriesJson = [];
      }

      return categoriesJson.map((json) => IngredientType.fromJson(json)).toList();
    } catch (e) {
      print('Error in getRefrigeratorCategories: $e');
      throw Exception('Ошибка при получении категорий: $e');
    }
  }

  // Добавить продукт в холодильник
  // Добавить продукт в холодильник
  Future<RefrigeratorItem> addItem({
    required int ingredientId,
    required int quantity,
    required QuantityType quantityType,
  }) async {
    try {
      final response = await _apiService.post('/api/refrigerator/', {
        'mui_ing_id': ingredientId,
        'mui_quantity': quantity,
        'mui_quantity_type': quantityType.toString().split('.').last,
      });

      // Отладочный вывод
      print('API RESPONSE TYPE: ${response.runtimeType}');
      print('API RESPONSE CONTENT: $response');

      // Проверяем, что именно возвращает сервер
      if (response is Map<String, dynamic>) {
        print('mui_ing_id TYPE: ${response['mui_ing_id']?.runtimeType}');
        print('mui_ing_id VALUE: ${response['mui_ing_id']}');
      }

      return RefrigeratorItem.fromJson(response);
    } catch (e) {
      print('Error in addItem: $e');
      print('Error stackTrace: ${e is Error ? e.stackTrace : 'no stack trace'}');
      throw Exception('Ошибка при добавлении продукта: $e');
    }
  }

  // Добавить несколько продуктов одновременно
  Future<AddMultipleResponse> addMultipleItems(List<AddItemRequest> items) async {
    try {
      final itemsJson = items.map((item) => {
        'mui_ing_id': item.ingredientId,
        'mui_quantity': item.quantity,
        'mui_quantity_type': item.quantityType.toString().split('.').last,
      }).toList();

      final response = await _apiService.post('/api/refrigerator/add_multiple/', {
        'items': itemsJson,
      });

      return AddMultipleResponse.fromJson(response);
    } catch (e) {
      print('Error in addMultipleItems: $e');
      throw Exception('Ошибка при добавлении продуктов: $e');
    }
  }

  // Обновить продукт в холодильнике
  Future<RefrigeratorItem> updateItem({
    required int itemId,
    int? quantity,
    QuantityType? quantityType,
  }) async {
    try {
      Map<String, dynamic> data = {};

      if (quantity != null) {
        data['mui_quantity'] = quantity;
      }

      if (quantityType != null) {
        data['mui_quantity_type'] = quantityType.toString().split('.').last;
      }

      final response = await _apiService.put('/api/refrigerator/$itemId/', data);
      return RefrigeratorItem.fromJson(response);
    } catch (e) {
      print('Error in updateItem: $e');
      throw Exception('Ошибка при обновлении продукта: $e');
    }
  }

  // Удалить продукт из холодильника
  Future<void> removeItem(int itemId) async {
    try {
      await _apiService.delete('/api/refrigerator/$itemId/');
    } catch (e) {
      print('Error in removeItem: $e');
      throw Exception('Ошибка при удалении продукта: $e');
    }
  }

  // Поиск ингредиентов для добавления (без пагинации)
  Future<List<Ingredient>> searchIngredients({
    required String query,
    int? typeId,
  }) async {
    Map<String, String> params = {
      'search': query,
    };

    if (typeId != null) {
      params['type_id'] = typeId.toString();
    }

    // Создаем query string
    String queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    try {
      final response = await _apiService.get('/api/ingredients/?$queryString');

      List<dynamic> ingredientsJson;

      if (response['results'] != null) {
        ingredientsJson = response['results'];
      } else if (response is List) {
        ingredientsJson = response as List;
      } else {
        ingredientsJson = [];
      }

      return ingredientsJson.map((json) => Ingredient.fromJson(json)).toList();
    } catch (e) {
      print('Error in searchIngredients: $e');
      throw Exception('Ошибка при поиске ингредиентов: $e');
    }
  }
}

// Обновленные классы для ответов

class RefrigeratorResponse {
  final List<RefrigeratorItem> items;
  final int count;
  final RefrigeratorStats stats;

  RefrigeratorResponse({
    required this.items,
    required this.count,
    required this.stats,
  });

  factory RefrigeratorResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> resultsJson = json['results'] ?? [];
    List<RefrigeratorItem> items = resultsJson
        .map((itemJson) => RefrigeratorItem.fromJson(itemJson))
        .toList();

    RefrigeratorStats stats = RefrigeratorStats.fromJson(json['stats'] ?? {});

    return RefrigeratorResponse(
      items: items,
      count: json['count'] ?? items.length,
      stats: stats,
    );
  }
}

class AddItemRequest {
  final int ingredientId;
  final int quantity;
  final QuantityType quantityType;

  AddItemRequest({
    required this.ingredientId,
    required this.quantity,
    required this.quantityType,
  });
}

class AddMultipleResponse {
  final List<int> added;
  final List<AddError> errors;
  final AddSummary summary;

  AddMultipleResponse({
    required this.added,
    required this.errors,
    required this.summary,
  });

  factory AddMultipleResponse.fromJson(Map<String, dynamic> json) {
    List<int> added = [];
    if (json['added'] is List) {
      added = (json['added'] as List)
          .map((id) => id is int ? id : int.tryParse(id.toString()) ?? 0)
          .toList();
    }

    List<AddError> errors = [];
    if (json['errors'] is List) {
      errors = (json['errors'] as List)
          .map((error) => AddError.fromJson(error))
          .toList();
    }

    return AddMultipleResponse(
      added: added,
      errors: errors,
      summary: AddSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

class AddError {
  final int? ingredientId;
  final String error;

  AddError({
    this.ingredientId,
    required this.error,
  });

  factory AddError.fromJson(Map<String, dynamic> json) {
    return AddError(
      ingredientId: json['ingredient_id'],
      error: json['error'] ?? 'Неизвестная ошибка',
    );
  }
}

class AddSummary {
  final int total;
  final int added;
  final int failed;

  AddSummary({
    required this.total,
    required this.added,
    required this.failed,
  });

  factory AddSummary.fromJson(Map<String, dynamic> json) {
    return AddSummary(
      total: json['total'] ?? 0,
      added: json['added'] ?? 0,
      failed: json['failed'] ?? 0,
    );
  }
}