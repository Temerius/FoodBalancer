
import '../../models/user.dart';
import '../services/cache_service.dart';
import '../models/cache_config.dart';
import '../../services/api_service.dart';

class UserRepository {
  static const String _cacheKey = 'user';
  static const String _allergenIdsKey = 'user_allergen_ids';
  static const String _equipmentIdsKey = 'user_equipment_ids';

  final ApiService _apiService;
  User? _user;

  UserRepository({required ApiService apiService})
      : _apiService = apiService;

  
  User? get user => _user;

  
  Future<User?> getUserProfile({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;

    
    if (_user != null && !cacheConfig.forceRefresh) {
      return _user;
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        try {
          
          _ensureCorrectDataTypes(cachedData);
          _user = User.fromJson(cachedData);
          return _user;
        } catch (e) {
          
        }
      }
    }

    
    try {
      final userData = await _apiService.get('/api/users/profile/');

      try {
        
        _ensureCorrectDataTypes(userData);
        _user = User.fromJson(userData);

        
        await CacheService.save(_cacheKey, userData);

        return _user;
      } catch (e) {
        throw Exception('Ошибка при обработке данных пользователя: $e');
      }
    } catch (e) {
      if (_user != null) {
        return _user; 
      }
      rethrow;
    }
  }

  
  void _ensureCorrectDataTypes(Map<String, dynamic> userData) {
    
    if (userData.containsKey('allergenIds')) {
      if (userData['allergenIds'] is List) {
        List<dynamic> rawIds = userData['allergenIds'];
        List<int> convertedIds = [];

        for (var id in rawIds) {
          if (id is int) {
            convertedIds.add(id);
          } else if (id is String) {
            int? parsedId = int.tryParse(id);
            if (parsedId != null) {
              convertedIds.add(parsedId);
            }
          }
        }

        userData['allergenIds'] = convertedIds;
      } else {
        
        userData['allergenIds'] = <int>[];
      }
    } else {
      
      userData['allergenIds'] = <int>[];
    }

    
    if (userData.containsKey('equipmentIds')) {
      if (userData['equipmentIds'] is List) {
        List<dynamic> rawIds = userData['equipmentIds'];
        List<int> convertedIds = [];

        for (var id in rawIds) {
          if (id is int) {
            convertedIds.add(id);
          } else if (id is String) {
            int? parsedId = int.tryParse(id);
            if (parsedId != null) {
              convertedIds.add(parsedId);
            }
          }
        }

        userData['equipmentIds'] = convertedIds;
      } else {
        
        userData['equipmentIds'] = <int>[];
      }
    } else {
      
      userData['equipmentIds'] = <int>[];
    }
  }

  
  Future<List<int>> getUserAllergenIds({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;

    
    if (_user != null && !cacheConfig.forceRefresh) {
      return _user!.allergenIds;
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_allergenIdsKey, cacheConfig);

      if (cachedData != null) {
        try {
          List<int> allergenIds = [];

          if (cachedData is List) {
            for (var id in cachedData) {
              if (id is int) {
                allergenIds.add(id);
              } else if (id is String) {
                int? parsedId = int.tryParse(id);
                if (parsedId != null) {
                  allergenIds.add(parsedId);
                }
              }
            }
          }

          return allergenIds;
        } catch (e) {
          
        }
      }
    }

    
    try {
      
      final response = await _apiService.get('/api/user-allergens/');
      List<int> allergenIds = [];

      
      if (response.containsKey('results')) {
        final List<dynamic> userAllergensJson = response['results'];

        for (var item in userAllergensJson) {
          _extractAllergenId(item, allergenIds);
        }
      } else {
        
        final rawData = response['raw_data'] ?? response;

        if (rawData is List) {
          for (var item in rawData) {
            _extractAllergenId(item, allergenIds);
          }
        }
      }

      
      await CacheService.save(_allergenIdsKey, allergenIds);

      
      if (_user != null) {
        _user = _user!.copyWith(allergenIds: allergenIds);
        await CacheService.save(_cacheKey, _user!.toJson());
      }

      return allergenIds;
    } catch (e) {
      if (_user != null) {
        return _user!.allergenIds; 
      }
      return [];
    }
  }

  
  void _extractAllergenId(dynamic item, List<int> allergenIds) {
    if (item is Map<String, dynamic>) {
      
      dynamic algId;

      if (item.containsKey('mua_alg_id')) {
        algId = item['mua_alg_id'];
      } else if (item.containsKey('alg_id')) {
        algId = item['alg_id'];
      } else if (item.containsKey('id')) {
        algId = item['id'];
      }

      
      if (algId != null) {
        if (algId is int) {
          allergenIds.add(algId);
        } else if (algId is String) {
          int? parsedId = int.tryParse(algId);
          if (parsedId != null) {
            allergenIds.add(parsedId);
          }
        }
      }
    } else if (item is int) {
      
      allergenIds.add(item);
    } else if (item is String) {
      
      int? parsedId = int.tryParse(item);
      if (parsedId != null) {
        allergenIds.add(parsedId);
      }
    }
  }

  
  Future<List<int>> getUserEquipmentIds({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;

    
    if (_user != null && !cacheConfig.forceRefresh) {
      return _user!.equipmentIds;
    }

    
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_equipmentIdsKey, cacheConfig);

      if (cachedData != null) {
        try {
          List<int> equipmentIds = [];

          if (cachedData is List) {
            for (var id in cachedData) {
              if (id is int) {
                equipmentIds.add(id);
              } else if (id is String) {
                int? parsedId = int.tryParse(id);
                if (parsedId != null) {
                  equipmentIds.add(parsedId);
                }
              }
            }
          }

          return equipmentIds;
        } catch (e) {
          
        }
      }
    }

    
    try {
      
      final response = await _apiService.get('/api/user-equipment/');
      List<int> equipmentIds = [];

      
      if (response.containsKey('results')) {
        final List<dynamic> userEquipmentJson = response['results'];

        for (var item in userEquipmentJson) {
          _extractEquipmentId(item, equipmentIds);
        }
      } else {
        
        final rawData = response['raw_data'] ?? response;

        if (rawData is List) {
          for (var item in rawData) {
            _extractEquipmentId(item, equipmentIds);
          }
        }
      }

      
      await CacheService.save(_equipmentIdsKey, equipmentIds);

      
      if (_user != null) {
        _user = _user!.copyWith(equipmentIds: equipmentIds);
        await CacheService.save(_cacheKey, _user!.toJson());
      }

      return equipmentIds;
    } catch (e) {
      if (_user != null) {
        return _user!.equipmentIds; 
      }
      return [];
    }
  }

  
  void _extractEquipmentId(dynamic item, List<int> equipmentIds) {
    if (item is Map<String, dynamic>) {
      
      dynamic eqpId;

      if (item.containsKey('mue_eqp_id')) {
        eqpId = item['mue_eqp_id'];
      } else if (item.containsKey('eqp_id')) {
        eqpId = item['eqp_id'];
      } else if (item.containsKey('id')) {
        eqpId = item['id'];
      }

      
      if (eqpId != null) {
        if (eqpId is int) {
          equipmentIds.add(eqpId);
        } else if (eqpId is String) {
          int? parsedId = int.tryParse(eqpId);
          if (parsedId != null) {
            equipmentIds.add(parsedId);
          }
        }
      }
    } else if (item is int) {
      
      equipmentIds.add(item);
    } else if (item is String) {
      
      int? parsedId = int.tryParse(item);
      if (parsedId != null) {
        equipmentIds.add(parsedId);
      }
    }
  }

  
  Future<bool> updateUserAllergens(List<int> allergenIds) async {
    if (_user == null) {
      await getUserProfile();

      if (_user == null) {
        return false;
      }
    }

    try {
      
      final requestData = {
        'allergen_ids': allergenIds,
      };

      await _apiService.post('/api/user-allergens/update/', requestData);

      
      updateUserAllergensInMemory(allergenIds);

      
      final userJson = _user!.toJson();
      await CacheService.save(_cacheKey, userJson);
      await CacheService.save(_allergenIdsKey, allergenIds);

      return true;
    } catch (e) {
      return false;
    }
  }

  
  void updateUserAllergensInMemory(List<int> allergenIds) {
    if (_user == null) {
      return;
    }

    _user = _user!.copyWith(allergenIds: allergenIds);
  }

  
  Future<bool> updateUserEquipment(List<int> equipmentIds) async {
    if (_user == null) {
      await getUserProfile();

      if (_user == null) {
        return false;
      }
    }

    try {
      
      final requestData = {
        'equipment_ids': equipmentIds,
      };

      await _apiService.post('/api/user-equipment/update/', requestData);

      
      updateUserEquipmentInMemory(equipmentIds);

      
      final userJson = _user!.toJson();
      await CacheService.save(_cacheKey, userJson);
      await CacheService.save(_equipmentIdsKey, equipmentIds);

      return true;
    } catch (e) {
      return false;
    }
  }

  
  void updateUserEquipmentInMemory(List<int> equipmentIds) {
    if (_user == null) {
      return;
    }

    _user = _user!.copyWith(equipmentIds: equipmentIds);
  }

  
  Future<bool> updateUserProfile(User updatedUser) async {
    try {
      
      final Map<String, dynamic> userData = {
        'usr_name': updatedUser.name,
        'usr_height': updatedUser.height,
        'usr_weight': updatedUser.weight,
        'usr_age': updatedUser.age,
        'usr_cal_day': updatedUser.caloriesPerDay,
      };

      
      if (updatedUser.gender != null) {
        userData['usr_gender'] = updatedUser.gender!.toPostgreSqlValue();
      }

      
      final response = await _apiService.put('/api/users/profile/', userData);

      
      await updateUserAllergens(updatedUser.allergenIds);

      
      await updateUserEquipment(updatedUser.equipmentIds);

      
      if (response.containsKey('usr_id')) {
        
        _ensureCorrectDataTypes(response);

        
        if (!response.containsKey('allergenIds') || (response['allergenIds'] as List).isEmpty) {
          response['allergenIds'] = updatedUser.allergenIds;
        }
        if (!response.containsKey('equipmentIds') || (response['equipmentIds'] as List).isEmpty) {
          response['equipmentIds'] = updatedUser.equipmentIds;
        }

        _user = User.fromJson(response);
      } else {
        _user = updatedUser;
      }

      
      await CacheService.save(_cacheKey, _user!.toJson());

      return true;
    } catch (e) {
      return false;
    }
  }

  
  Future<void> clearCache() async {
    await CacheService.clear(_cacheKey);
    await CacheService.clear(_allergenIdsKey);
    await CacheService.clear(_equipmentIdsKey);
  }
}