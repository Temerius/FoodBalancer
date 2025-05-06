// lib/repositories/repositories/equipment_repository.dart
import '../../models/equipment.dart';
import '../services/cache_service.dart';
import '../models/cache_config.dart';
import '../../services/api_service.dart';

class EquipmentRepository {
  static const String _cacheKey = 'equipment';

  final ApiService _apiService;
  List<Equipment> _equipment = [];

  EquipmentRepository({required ApiService apiService})
      : _apiService = apiService;

  // Геттер для списка оборудования
  List<Equipment> get equipment => _equipment;

  // Загрузка всего оборудования
  Future<List<Equipment>> getAllEquipment({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;

    // Если оборудование уже в памяти и не требуется обновление
    if (_equipment.isNotEmpty && !cacheConfig.forceRefresh) {
      return _equipment;
    }

    // Пробуем загрузить из кэша
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        final List<dynamic> equipmentJson = cachedData;
        _equipment = equipmentJson.map((json) => Equipment.fromJson(json)).toList();
        return _equipment;
      }
    }

    // Загружаем из API
    try {
      final response = await _apiService.get('/api/equipment/?limit=1000');

      if (response.containsKey('results')) {
        final List<dynamic> equipmentJson = response['results'];
        _equipment = equipmentJson.map((json) => Equipment.fromJson(json)).toList();

        // Сохраняем в кэш
        await CacheService.save(_cacheKey, equipmentJson);

        return _equipment;
      } else {
        return [];
      }
    } catch (e) {
      if (_equipment.isNotEmpty) {
        return _equipment; // Возвращаем данные из памяти в случае ошибки
      }
      rethrow;
    }
  }

  // Фильтрация оборудования по ID
  List<Equipment> filterByIds(List<int> ids) {
    return _equipment.where((equipment) => ids.contains(equipment.id)).toList();
  }

  // Очистка кэша
  Future<void> clearCache() async {
    await CacheService.clear(_cacheKey);
  }
}