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

  
  List<Allergen> get allergens => _allergens;

  
  Future<List<Allergen>> getAllAllergens({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\nё (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    
    if (_allergens.isNotEmpty && !cacheConfig.forceRefresh) {
      print("ALLERGENS ALREADY IN MEMORY: ${_allergens.length} items");
      return _allergens;
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        print("LOADING ALLERGENS FROM CACHE: ${cachedData.length} items");
        final List<dynamic> allergensJson = cachedData;

        try {
          _allergens = allergensJson.map((json) => Allergen.fromJson(json)).toList();
          print("ALLERGENS LOADED FROM CACHE SUCCESSFULLY: ${_allergens.length} items");
          return _allergens;
        } catch (e) {
          print("ERROR PARSING ALLERGENS FROM CACHE: $e");
          
        }
      }
    }

    
    try {
      print("FETCHING ALLERGENS FROM API...");
      final response = await _apiService.get('/api/allergens/?limit=1000');
      print("API RESPONSE FOR ALLERGENS: $response");

      if (response.containsKey('results')) {
        final List<dynamic> allergensJson = response['results'];
        print("ALLERGENS JSON FROM API: ${allergensJson.length} items");

        _allergens = allergensJson.map((json) => Allergen.fromJson(json)).toList();

        
        print("ALLERGENS LOADED FROM API: ${_allergens.length} items");

        
        print("SAVING ALLERGENS TO CACHE...");
        await CacheService.save(_cacheKey, allergensJson);

        return _allergens;
      } else {
        print("NO RESULTS FIELD IN API RESPONSE");
        return [];
      }
    } catch (e) {
      print("ERROR FETCHING ALLERGENS FROM API: $e");
      if (_allergens.isNotEmpty) {
        print("RETURNING ALLERGENS FROM MEMORY DUE TO ERROR: ${_allergens.length} items");
        return _allergens; 
      }
      rethrow;
    }
  }

  
  List<Allergen> filterByIds(List<int> ids) {
    print("\n===== FILTERING ALLERGENS BY IDS: $ids =====");
    final filteredAllergens = _allergens.where((allergen) => ids.contains(allergen.id)).toList();
    print("FOUND ${filteredAllergens.length} MATCHING ALLERGENS");
    return filteredAllergens;
  }

  
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

  
  Future<void> clearCache() async {
    print("\n===== CLEARING ALLERGENS CACHE =====");
    await CacheService.clear(_cacheKey);
    print("ALLERGENS CACHE CLEARED");
  }
}
