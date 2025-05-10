// lib/repositories/repositories/refrigerator_repository.dart
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

  // Геттеры
  List<RefrigeratorItem> get items => _items;
  RefrigeratorStats? get stats => _stats;
  List<IngredientType> get categories => _categories;

  // Получить все продукты в холодильнике
  Future<List<RefrigeratorItem>> getItems({
    String? search,
    String? category,
    bool? expiringSoon,
    CacheConfig? config,
  }) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING REFRIGERATOR ITEMS (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    // Формируем ключ кэша в зависимости от параметров фильтрации
    String cacheKey = _cacheKey;
    if (search != null || category != null || expiringSoon != null) {
      final filters = <String>[];
      if (search != null) filters.add('search_$search');
      if (category != null) filters.add('category_$category');
      if (expiringSoon == true) filters.add('expiring');
      cacheKey = '${_cacheKey}_${filters.join('_')}';
    }

    // Если нет фильтров и продукты уже в памяти и не требуется обновление
    if (search == null && category == null && expiringSoon == null &&
        _items.isNotEmpty && !cacheConfig.forceRefresh) {
      print("REFRIGERATOR ITEMS ALREADY IN MEMORY: ${_items.length} items");
      return _items;
    }

    // Пробуем загрузить из кэша если нет фильтров
    if (!cacheConfig.forceRefresh && search == null && category == null && expiringSoon == null) {
      final cachedData = await CacheService.get(cacheKey, cacheConfig);

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
          // Если произошла ошибка при парсинге, продолжаем загрузку из API
        }
      }
    }

    // Загружаем из API
    try {
      print("FETCHING REFRIGERATOR ITEMS FROM API...");
      final response = await _refrigeratorService.getRefrigeratorItems(
        search: search,
        category: category,
        expiringSoon: expiringSoon,
      );

      // Если нет фильтров, сохраняем в основной список
      if (search == null && category == null && expiringSoon == null) {
        _items = response.items;
        _stats = response.stats;

        // Сохраняем в кэш
        print("SAVING REFRIGERATOR ITEMS TO CACHE...");
        await CacheService.save(cacheKey, {
          'items': _items.map((item) => item.toJson()).toList(),
          'stats': _stats?.toJson(),
        });
      }

      print("REFRIGERATOR ITEMS LOADED FROM API: ${response.items.length} items");
      return response.items;
    } catch (e) {
      print("ERROR FETCHING REFRIGERATOR ITEMS FROM API: $e");
      if (_items.isNotEmpty) {
        print("RETURNING REFRIGERATOR ITEMS FROM MEMORY DUE TO ERROR: ${_items.length} items");
        return _items; // Возвращаем данные из памяти в случае ошибки
      }
      rethrow;
    }
  }

  // Получить продукты с истекающим сроком годности
  Future<List<RefrigeratorItem>> getExpiringItems({CacheConfig? config}) async {
    try {
      final items = await getItems(expiringSoon: true, config: config);
      return items;
    } catch (e) {
      print("ERROR GETTING EXPIRING ITEMS: $e");
      rethrow;
    }
  }

  // Получить статистику холодильника
  Future<RefrigeratorStats> getStats({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;

    // Если статистика уже в памяти и не требуется обновление
    if (_stats != null && !cacheConfig.forceRefresh) {
      return _stats!;
    }

    try {
      await getItems(config: config); // Это загружает и статистику
      if (_stats != null) {
        return _stats!;
      }

      // Если по какой-то причине статистика не загрузилась, загружаем отдельно
      _stats = await _refrigeratorService.getRefrigeratorStats();
      return _stats!;
    } catch (e) {
      print("ERROR GETTING REFRIGERATOR STATS: $e");
      if (_stats != null) {
        return _stats!;
      }
      rethrow;
    }
  }

  // Получить категории продуктов в холодильнике
  Future<List<IngredientType>> getCategories({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING REFRIGERATOR CATEGORIES (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    // Если категории уже в памяти и не требуется обновление
    if (_categories.isNotEmpty && !cacheConfig.forceRefresh) {
      print("REFRIGERATOR CATEGORIES ALREADY IN MEMORY: ${_categories.length} items");
      return _categories;
    }

    // Пробуем загрузить из кэша
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

    // Загружаем из API
    try {
      print("FETCHING REFRIGERATOR CATEGORIES FROM API...");
      _categories = await _refrigeratorService.getRefrigeratorCategories();

      // Сохраняем в кэш
      print("SAVING REFRIGERATOR CATEGORIES TO CACHE...");
      await CacheService.save(_categoriesCacheKey,
          _categories.map((cat) => cat.toJson()).toList());

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

  // Добавить продукт в холодильник
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

      // Добавляем новый продукт в список
      _items.add(newItem);

      // Обновляем статистику
      if (_stats != null) {
        _stats = RefrigeratorStats(
          totalItems: _stats!.totalItems + 1,
          expiringSoon: _stats!.expiringSoon,
          expired: _stats!.expired,
        );
      }

      // Очищаем кэш чтобы при следующей загрузке получить актуальные данные
      await _clearCache();

      return newItem;
    } catch (e) {
      print("ERROR ADDING ITEM TO REFRIGERATOR: $e");
      rethrow;
    }
  }

  // Добавить несколько продуктов одновременно
  Future<AddMultipleResponse> addMultipleItems(List<AddItemRequest> items) async {
    try {
      final response = await _refrigeratorService.addMultipleItems(items);

      // Очищаем кэш так как данные изменились
      await _clearCache();

      return response;
    } catch (e) {
      print("ERROR ADDING MULTIPLE ITEMS TO REFRIGERATOR: $e");
      rethrow;
    }
  }

  // Обновить продукт в холодильнике
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

      // Обновляем продукт в списке
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
      }

      // Очищаем кэш
      await _clearCache();

      return updatedItem;
    } catch (e) {
      print("ERROR UPDATING REFRIGERATOR ITEM: $e");
      rethrow;
    }
  }

  // Удалить продукт из холодильника
  Future<void> removeItem(int itemId) async {
    try {
      await _refrigeratorService.removeItem(itemId);

      // Удаляем продукт из списка
      _items.removeWhere((item) => item.id == itemId);

      // Обновляем статистику
      if (_stats != null) {
        _stats = RefrigeratorStats(
          totalItems: _stats!.totalItems - 1,
          expiringSoon: _stats!.expiringSoon,
          expired: _stats!.expired,
        );
      }

      // Очищаем кэш
      await _clearCache();
    } catch (e) {
      print("ERROR REMOVING REFRIGERATOR ITEM: $e");
      rethrow;
    }
  }

  // Поиск ингредиентов для добавления
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

  // Очистка кэша
  Future<void> _clearCache() async {
    await CacheService.clear(_cacheKey);
    await CacheService.clear(_statsCacheKey);
    await CacheService.clear(_categoriesCacheKey);
  }

  // Полная очистка кэша
  Future<void> clearCache() async {
    print("\n===== CLEARING REFRIGERATOR CACHE =====");
    await _clearCache();
    print("REFRIGERATOR CACHE CLEARED");
  }
}