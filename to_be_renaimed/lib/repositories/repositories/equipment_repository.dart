
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

  
  List<Equipment> get equipment => _equipment;

  
  Future<List<Equipment>> getAllEquipment({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING ALL EQUIPMENT (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    
    if (_equipment.isNotEmpty && !cacheConfig.forceRefresh) {
      print("EQUIPMENT ALREADY IN MEMORY: ${_equipment.length} items");
      for (int i = 0; i < _equipment.length && i < 10; i++) {
        print("${i + 1}. ID: ${_equipment[i].id}, Type: ${_equipment[i].type}");
      }
      if (_equipment.length > 10) {
        print("... and ${_equipment.length - 10} more.");
      }
      return _equipment;
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        print("LOADING EQUIPMENT FROM CACHE: ${cachedData.length} items");
        final List<dynamic> equipmentJson = cachedData;

        try {
          _equipment = equipmentJson.map((json) => Equipment.fromJson(json)).toList();
          print("EQUIPMENT LOADED FROM CACHE SUCCESSFULLY: ${_equipment.length} items");
          for (int i = 0; i < _equipment.length && i < 10; i++) {
            print("${i + 1}. ID: ${_equipment[i].id}, Type: ${_equipment[i].type}");
          }
          if (_equipment.length > 10) {
            print("... and ${_equipment.length - 10} more.");
          }
          return _equipment;
        } catch (e) {
          print("ERROR PARSING EQUIPMENT FROM CACHE: $e");
          
        }
      }
    }

    
    try {
      print("FETCHING ALL EQUIPMENT FROM API USING PAGINATION...");

      
      _equipment.clear();

      
      final allResults = await _apiService.getAllPaginatedResults('/api/equipment/?limit=1000');
      print("ALL PAGES FETCHED, TOTAL EQUIPMENT: ${allResults.length}");

      try {
        _equipment = allResults.map((json) => Equipment.fromJson(json)).toList();

        
        print("EQUIPMENT LOADED FROM API: ${_equipment.length} items");
        for (int i = 0; i < _equipment.length && i < 10; i++) {
          print("${i + 1}. ID: ${_equipment[i].id}, Type: ${_equipment[i].type}");
        }
        if (_equipment.length > 10) {
          print("... and ${_equipment.length - 10} more.");
        }

        
        print("SAVING EQUIPMENT TO CACHE...");
        await CacheService.save(_cacheKey, allResults);

        return _equipment;
      } catch (e) {
        print("ERROR PARSING EQUIPMENT FROM API: $e");
        throw Exception('Ошибка при обработке данных оборудования: $e');
      }
    } catch (e) {
      print("ERROR FETCHING EQUIPMENT FROM API: $e");
      if (_equipment.isNotEmpty) {
        print("RETURNING EQUIPMENT FROM MEMORY DUE TO ERROR: ${_equipment.length} items");
        return _equipment; 
      }
      rethrow;
    }
  }

  
  List<Equipment> filterByIds(List<int> ids) {
    print("\n===== FILTERING EQUIPMENT BY IDS: $ids =====");
    final filteredEquipment = _equipment.where((equipment) => ids.contains(equipment.id)).toList();

    print("FOUND ${filteredEquipment.length} MATCHING EQUIPMENT:");
    for (int i = 0; i < filteredEquipment.length && i < 10; i++) {
      print("${i + 1}. ID: ${filteredEquipment[i].id}, Type: ${filteredEquipment[i].type}");
    }
    if (filteredEquipment.length > 10) {
      print("... and ${filteredEquipment.length - 10} more.");
    }

    return filteredEquipment;
  }

  
  Future<void> clearCache() async {
    print("\n===== CLEARING EQUIPMENT CACHE =====");
    await CacheService.clear(_cacheKey);
    print("EQUIPMENT CACHE CLEARED");
  }
}