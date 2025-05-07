// lib/repositories/repositories/allergen_repository.dart
import '../../models/allergen.dart';
import '../services/cache_service.dart';
import '../models/cache_config.dart';
import '../../services/api_service.dart';

class AllergenRepository {
  static const String _cacheKey = 'allergens';

  final ApiService _apiService;
  List<Allergen> _allergens = [];

  AllergenRepository({required ApiService apiService})
      : _apiService = apiService;

  // Геттер для списка аллергенов
  List<Allergen> get allergens => _allergens;

  // Загрузка всех аллергенов
  Future<List<Allergen>> getAllAllergens({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING ALL ALLERGENS (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    // Если аллергены уже в памяти и не требуется обновление
    if (_allergens.isNotEmpty && !cacheConfig.forceRefresh) {
      print("ALLERGENS ALREADY IN MEMORY: ${_allergens.length} items");
      for (int i = 0; i < _allergens.length; i++) {
        print("${i + 1}. ID: ${_allergens[i].id}, Name: ${_allergens[i].name}");
      }
      return _allergens;
    }

    // Пробуем загрузить из кэша
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        print("LOADING ALLERGENS FROM CACHE: ${cachedData.length} items");
        final List<dynamic> allergensJson = cachedData;

        try {
          _allergens = allergensJson.map((json) => Allergen.fromJson(json)).toList();
          print("ALLERGENS LOADED FROM CACHE SUCCESSFULLY: ${_allergens.length} items");
          for (int i = 0; i < _allergens.length; i++) {
            print("${i + 1}. ID: ${_allergens[i].id}, Name: ${_allergens[i].name}");
          }
          return _allergens;
        } catch (e) {
          print("ERROR PARSING ALLERGENS FROM CACHE: $e");
          // Если произошла ошибка при парсинге, продолжаем загрузку из API
        }
      }
    }

    // Загружаем из API
    try {
      print("FETCHING ALLERGENS FROM API...");
      final response = await _apiService.get('/api/allergens/?limit=1000');
      print("API RESPONSE FOR ALLERGENS: $response");

      if (response.containsKey('results')) {
        final List<dynamic> allergensJson = response['results'];
        print("ALLERGENS JSON FROM API: ${allergensJson.length} items");

        try {
          _allergens = allergensJson.map((json) => Allergen.fromJson(json)).toList();

          // Выводим список загруженных аллергенов
          print("ALLERGENS LOADED FROM API: ${_allergens.length} items");
          for (int i = 0; i < _allergens.length; i++) {
            print("${i + 1}. ID: ${_allergens[i].id}, Name: ${_allergens[i].name}");
          }

          // Сохраняем в кэш
          print("SAVING ALLERGENS TO CACHE...");
          await CacheService.save(_cacheKey, allergensJson);

          return _allergens;
        } catch (e) {
          print("ERROR PARSING ALLERGENS FROM API: $e");
          throw Exception('Ошибка при обработке данных аллергенов: $e');
        }
      } else {
        print("NO RESULTS FIELD IN API RESPONSE");
        return [];
      }
    } catch (e) {
      print("ERROR FETCHING ALLERGENS FROM API: $e");
      if (_allergens.isNotEmpty) {
        print("RETURNING ALLERGENS FROM MEMORY DUE TO ERROR: ${_allergens.length} items");
        return _allergens; // Возвращаем данные из памяти в случае ошибки
      }
      rethrow;
    }
  }

  // Фильтрация аллергенов по ID
  List<Allergen> filterByIds(List<int> ids) {
    print("\n===== FILTERING ALLERGENS BY IDS: $ids =====");
    final filteredAllergens = _allergens.where((allergen) => ids.contains(allergen.id)).toList();

    print("FOUND ${filteredAllergens.length} MATCHING ALLERGENS:");
    for (int i = 0; i < filteredAllergens.length; i++) {
      print("${i + 1}. ID: ${filteredAllergens[i].id}, Name: ${filteredAllergens[i].name}");
    }

    return filteredAllergens;
  }

  // Поиск аллергена по ID
  Allergen? findById(int id) {
    print("\n===== FINDING ALLERGEN BY ID: $id =====");
    for (var allergen in _allergens) {
      if (allergen.id == id) {
        print("FOUND ALLERGEN: ID: ${allergen.id}, Name: ${allergen.name}");
        return allergen;
      }
    }
    print("ALLERGEN WITH ID $id NOT FOUND");
    return null;
  }

  // Очистка кэша
  Future<void> clearCache() async {
    print("\n===== CLEARING ALLERGENS CACHE =====");
    await CacheService.clear(_cacheKey);
    print("ALLERGENS CACHE CLEARED");
  }
}