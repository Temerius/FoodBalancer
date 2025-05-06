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

    // Если аллергены уже в памяти и не требуется обновление
    if (_allergens.isNotEmpty && !cacheConfig.forceRefresh) {
      return _allergens;
    }

    // Пробуем загрузить из кэша
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        final List<dynamic> allergensJson = cachedData;
        _allergens = allergensJson.map((json) => Allergen.fromJson(json)).toList();
        return _allergens;
      }
    }

    // Загружаем из API
    try {
      final response = await _apiService.get('/api/allergens/?limit=1000');

      if (response.containsKey('results')) {
        final List<dynamic> allergensJson = response['results'];
        _allergens = allergensJson.map((json) => Allergen.fromJson(json)).toList();

        // Сохраняем в кэш
        await CacheService.save(_cacheKey, allergensJson);

        return _allergens;
      } else {
        return [];
      }
    } catch (e) {
      if (_allergens.isNotEmpty) {
        return _allergens; // Возвращаем данные из памяти в случае ошибки
      }
      rethrow;
    }
  }

  // Фильтрация аллергенов по ID
  List<Allergen> filterByIds(List<int> ids) {
    return _allergens.where((allergen) => ids.contains(allergen.id)).toList();
  }

  // Очистка кэша
  Future<void> clearCache() async {
    await CacheService.clear(_cacheKey);
  }
}