// lib/repositories/repositories/user_repository.dart
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

  // Геттер для пользователя
  User? get user => _user;

  // Загрузка профиля пользователя
  Future<User?> getUserProfile({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING USER PROFILE (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    // Если пользователь уже в памяти и не требуется обновление
    if (_user != null && !cacheConfig.forceRefresh) {
      print("USER ALREADY IN MEMORY: ID=${_user!.id}, Name=${_user!.name}");
      return _user;
    }

    // Пробуем загрузить из кэша
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        try {
          print("USER LOADED FROM CACHE: $cachedData");

          // Проверяем формат данных перед созданием User
          _ensureCorrectDataTypes(cachedData);

          _user = User.fromJson(cachedData);
          print("USER SUCCESSFULLY PARSED FROM CACHE: ID=${_user!.id}, Name=${_user!.name}");
          print("USER ALLERGEN IDS: ${_user!.allergenIds}");
          print("USER EQUIPMENT IDS: ${_user!.equipmentIds}");
          return _user;
        } catch (e) {
          print("ERROR PARSING USER FROM CACHE: $e");
          // Продолжаем и пытаемся получить из API
        }
      }
    }

    // Загружаем из API
    try {
      print("FETCHING USER FROM API...");
      final userData = await _apiService.get('/api/users/profile/');
      print("USER DATA FROM API: $userData");

      try {
        // Проверяем формат данных перед созданием User
        _ensureCorrectDataTypes(userData);

        _user = User.fromJson(userData);
        print("USER SUCCESSFULLY PARSED FROM API: ID=${_user!.id}, Name=${_user!.name}");
        print("USER ALLERGEN IDS: ${_user!.allergenIds}");
        print("USER EQUIPMENT IDS: ${_user!.equipmentIds}");

        // Сохраняем в кэш
        await CacheService.save(_cacheKey, userData);

        return _user;
      } catch (e) {
        print("ERROR PARSING USER FROM API: $e");
        throw Exception('Ошибка при обработке данных пользователя: $e');
      }
    } catch (e) {
      print("ERROR LOADING USER FROM API: $e");
      if (_user != null) {
        return _user; // Возвращаем данные из памяти в случае ошибки
      }
      rethrow;
    }
  }

  // Проверка и исправление типов данных в JSON
  void _ensureCorrectDataTypes(Map<String, dynamic> userData) {
    print("ENSURING CORRECT DATA TYPES FOR USER DATA");

    // Обрабатываем allergenIds
    if (userData.containsKey('allergenIds')) {
      print("ORIGINAL ALLERGEN IDS: ${userData['allergenIds']} (${userData['allergenIds'].runtimeType})");

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
            } else {
              print("WARNING: Could not parse allergen ID: $id");
            }
          } else {
            print("WARNING: Unexpected allergen ID type: ${id.runtimeType}");
          }
        }

        userData['allergenIds'] = convertedIds;
        print("CONVERTED ALLERGEN IDS: ${userData['allergenIds']}");
      } else {
        // Если allergenIds не список, создаем пустой список
        userData['allergenIds'] = <int>[];
        print("ALLERGEN IDS WAS NOT A LIST, INITIALIZED EMPTY LIST");
      }
    } else {
      // Если allergenIds отсутствует, создаем пустой список
      userData['allergenIds'] = <int>[];
      print("NO ALLERGEN IDS FIELD, INITIALIZED EMPTY LIST");
    }

    // Обрабатываем equipmentIds по аналогии
    if (userData.containsKey('equipmentIds')) {
      print("ORIGINAL EQUIPMENT IDS: ${userData['equipmentIds']} (${userData['equipmentIds'].runtimeType})");

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
            } else {
              print("WARNING: Could not parse equipment ID: $id");
            }
          } else {
            print("WARNING: Unexpected equipment ID type: ${id.runtimeType}");
          }
        }

        userData['equipmentIds'] = convertedIds;
        print("CONVERTED EQUIPMENT IDS: ${userData['equipmentIds']}");
      } else {
        // Если equipmentIds не список, создаем пустой список
        userData['equipmentIds'] = <int>[];
        print("EQUIPMENT IDS WAS NOT A LIST, INITIALIZED EMPTY LIST");
      }
    } else {
      // Если equipmentIds отсутствует, создаем пустой список
      userData['equipmentIds'] = <int>[];
      print("NO EQUIPMENT IDS FIELD, INITIALIZED EMPTY LIST");
    }
  }

  // Получение ID аллергенов пользователя
  Future<List<int>> getUserAllergenIds({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING USER ALLERGEN IDS (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    // Если пользователь уже в памяти
    if (_user != null && !cacheConfig.forceRefresh) {
      print("USER ALLERGEN IDS FROM MEMORY: ${_user!.allergenIds}");
      return _user!.allergenIds;
    }

    // Пробуем загрузить из кэша
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_allergenIdsKey, cacheConfig);

      if (cachedData != null) {
        try {
          print("RAW ALLERGEN IDS FROM CACHE: $cachedData (${cachedData.runtimeType})");
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

          print("CONVERTED ALLERGEN IDS FROM CACHE: $allergenIds");
          return allergenIds;
        } catch (e) {
          print("ERROR PARSING ALLERGEN IDS FROM CACHE: $e");
          // Если произошла ошибка, продолжаем загрузку из API
        }
      }
    }

    // Загружаем из API
    try {
      print("FETCHING USER ALLERGEN IDS FROM API...");

      // Получаем данные, теперь API может вернуть список напрямую
      final response = await _apiService.get('/api/user-allergens/');
      print("USER ALLERGENS RESPONSE FROM API: $response");

      List<int> allergenIds = [];

      // Проверяем, вернулся ли список в поле results или напрямую
      if (response.containsKey('results')) {
        final List<dynamic> userAllergensJson = response['results'];
        print("USER ALLERGENS JSON FROM API (results field): ${userAllergensJson.length} items");

        for (var item in userAllergensJson) {
          _extractAllergenId(item, allergenIds);
        }
      } else {
        // Если в ответе нет поля results, проверяем, может быть ответ сам по себе список
        final rawData = response['raw_data'] ?? response;

        if (rawData is List) {
          print("USER ALLERGENS JSON FROM API (direct list): ${rawData.length} items");
          for (var item in rawData) {
            _extractAllergenId(item, allergenIds);
          }
        }
      }

      print("EXTRACTED USER ALLERGEN IDS FROM API: $allergenIds");

      // Сохраняем в кэш
      await CacheService.save(_allergenIdsKey, allergenIds);

      // Обновляем пользователя в памяти, если он существует
      if (_user != null) {
        print("UPDATING USER ALLERGEN IDS IN MEMORY: ${_user!.allergenIds} -> $allergenIds");
        _user = _user!.copyWith(allergenIds: allergenIds);
        await CacheService.save(_cacheKey, _user!.toJson());
      }

      return allergenIds;
    } catch (e) {
      print("ERROR FETCHING USER ALLERGEN IDS: $e");
      if (_user != null) {
        return _user!.allergenIds; // Возвращаем данные из памяти в случае ошибки
      }
      return [];
    }
  }

  // Вспомогательный метод для извлечения ID аллергена из элемента JSON
  void _extractAllergenId(dynamic item, List<int> allergenIds) {
    if (item is Map<String, dynamic>) {
      // Проверяем разные возможные ключи для ID аллергена
      dynamic algId;

      if (item.containsKey('mua_alg_id')) {
        algId = item['mua_alg_id'];
      } else if (item.containsKey('alg_id')) {
        algId = item['alg_id'];
      } else if (item.containsKey('id')) {
        algId = item['id'];
      }

      // Если нашли ID, конвертируем его в int
      if (algId != null) {
        if (algId is int) {
          allergenIds.add(algId);
        } else if (algId is String) {
          int? parsedId = int.tryParse(algId);
          if (parsedId != null) {
            allergenIds.add(parsedId);
          } else {
            print("WARNING: Could not parse allergen ID: $algId");
          }
        } else {
          print("WARNING: Unexpected allergen ID type: ${algId.runtimeType} for value: $algId");
        }
      }
    } else if (item is int) {
      // Если элемент сам является числом, это может быть прямой ID
      allergenIds.add(item);
    } else if (item is String) {
      // Если элемент сам является строкой, пробуем преобразовать в число
      int? parsedId = int.tryParse(item);
      if (parsedId != null) {
        allergenIds.add(parsedId);
      } else {
        print("WARNING: Could not parse allergen ID string: $item");
      }
    }
  }

  // Получение ID оборудования пользователя
  Future<List<int>> getUserEquipmentIds({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;
    print("\n===== GETTING USER EQUIPMENT IDS (forceRefresh: ${cacheConfig.forceRefresh}) =====");

    // Если пользователь уже в памяти
    if (_user != null && !cacheConfig.forceRefresh) {
      print("USER EQUIPMENT IDS FROM MEMORY: ${_user!.equipmentIds}");
      return _user!.equipmentIds;
    }

    // Пробуем загрузить из кэша
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_equipmentIdsKey, cacheConfig);

      if (cachedData != null) {
        try {
          print("RAW EQUIPMENT IDS FROM CACHE: $cachedData (${cachedData.runtimeType})");
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

          print("CONVERTED EQUIPMENT IDS FROM CACHE: $equipmentIds");
          return equipmentIds;
        } catch (e) {
          print("ERROR PARSING EQUIPMENT IDS FROM CACHE: $e");
          // Если произошла ошибка, продолжаем загрузку из API
        }
      }
    }

    // Загружаем из API
    try {
      print("FETCHING USER EQUIPMENT IDS FROM API...");

      // Получаем данные, теперь API может вернуть список напрямую
      final response = await _apiService.get('/api/user-equipment/');
      print("USER EQUIPMENT RESPONSE FROM API: $response");

      List<int> equipmentIds = [];

      // Проверяем, вернулся ли список в поле results или напрямую
      if (response.containsKey('results')) {
        final List<dynamic> userEquipmentJson = response['results'];
        print("USER EQUIPMENT JSON FROM API (results field): ${userEquipmentJson.length} items");

        for (var item in userEquipmentJson) {
          _extractEquipmentId(item, equipmentIds);
        }
      } else {
        // Если в ответе нет поля results, проверяем, может быть ответ сам по себе список
        final rawData = response['raw_data'] ?? response;

        if (rawData is List) {
          print("USER EQUIPMENT JSON FROM API (direct list): ${rawData.length} items");
          for (var item in rawData) {
            _extractEquipmentId(item, equipmentIds);
          }
        }
      }

      print("EXTRACTED USER EQUIPMENT IDS FROM API: $equipmentIds");

      // Сохраняем в кэш
      await CacheService.save(_equipmentIdsKey, equipmentIds);

      // Обновляем пользователя в памяти, если он существует
      if (_user != null) {
        print("UPDATING USER EQUIPMENT IDS IN MEMORY: ${_user!.equipmentIds} -> $equipmentIds");
        _user = _user!.copyWith(equipmentIds: equipmentIds);
        await CacheService.save(_cacheKey, _user!.toJson());
      }

      return equipmentIds;
    } catch (e) {
      print("ERROR FETCHING USER EQUIPMENT IDS: $e");
      if (_user != null) {
        return _user!.equipmentIds; // Возвращаем данные из памяти в случае ошибки
      }
      return [];
    }
  }

  // Вспомогательный метод для извлечения ID оборудования из элемента JSON
  void _extractEquipmentId(dynamic item, List<int> equipmentIds) {
    if (item is Map<String, dynamic>) {
      // Проверяем разные возможные ключи для ID оборудования
      dynamic eqpId;

      if (item.containsKey('mue_eqp_id')) {
        eqpId = item['mue_eqp_id'];
      } else if (item.containsKey('eqp_id')) {
        eqpId = item['eqp_id'];
      } else if (item.containsKey('id')) {
        eqpId = item['id'];
      }

      // Если нашли ID, конвертируем его в int
      if (eqpId != null) {
        if (eqpId is int) {
          equipmentIds.add(eqpId);
        } else if (eqpId is String) {
          int? parsedId = int.tryParse(eqpId);
          if (parsedId != null) {
            equipmentIds.add(parsedId);
          } else {
            print("WARNING: Could not parse equipment ID: $eqpId");
          }
        } else {
          print("WARNING: Unexpected equipment ID type: ${eqpId.runtimeType} for value: $eqpId");
        }
      }
    } else if (item is int) {
      // Если элемент сам является числом, это может быть прямой ID
      equipmentIds.add(item);
    } else if (item is String) {
      // Если элемент сам является строкой, пробуем преобразовать в число
      int? parsedId = int.tryParse(item);
      if (parsedId != null) {
        equipmentIds.add(parsedId);
      } else {
        print("WARNING: Could not parse equipment ID string: $item");
      }
    }
  }

  // Обновление аллергенов пользователя
  Future<bool> updateUserAllergens(List<int> allergenIds) async {
    print("\n===== UPDATING USER ALLERGENS: $allergenIds =====");
    if (_user == null) {
      await getUserProfile();

      if (_user == null) {
        print("ERROR: No user found to update allergens");
        return false;
      }
    }

    try {
      // Отправляем запрос на сервер
      print("SENDING ALLERGEN UPDATE TO SERVER...");

      // Always send an object with an array, even if empty
      final requestData = {
        'allergen_ids': allergenIds,
      };

      print("REQUEST DATA: $requestData");
      await _apiService.post('/api/user-allergens/update/', requestData);

      // Обновляем пользователя в памяти
      updateUserAllergensInMemory(allergenIds);

      // Обновляем кэш
      final userJson = _user!.toJson();
      print("UPDATED USER JSON: $userJson");
      await CacheService.save(_cacheKey, userJson);
      await CacheService.save(_allergenIdsKey, allergenIds);

      print("USER ALLERGEN UPDATE SUCCESSFUL");
      return true;
    } catch (e) {
      print("ERROR UPDATING USER ALLERGENS: $e");
      return false;
    }
  }

  // Обновление аллергенов пользователя только в памяти (без запроса на сервер)
  void updateUserAllergensInMemory(List<int> allergenIds) {
    if (_user == null) {
      print("ERROR: Cannot update allergens in memory - user is null");
      return;
    }

    print("UPDATING USER ALLERGENS IN MEMORY: ${_user!.allergenIds} -> $allergenIds");
    _user = _user!.copyWith(allergenIds: allergenIds);
  }

  // Обновление оборудования пользователя
  Future<bool> updateUserEquipment(List<int> equipmentIds) async {
    print("\n===== UPDATING USER EQUIPMENT: $equipmentIds =====");
    if (_user == null) {
      await getUserProfile();

      if (_user == null) {
        print("ERROR: No user found to update equipment");
        return false;
      }
    }

    try {
      // Отправляем запрос на сервер
      print("SENDING EQUIPMENT UPDATE TO SERVER...");

      // Always send an object with an array, even if empty
      final requestData = {
        'equipment_ids': equipmentIds,
      };

      print("REQUEST DATA: $requestData");
      await _apiService.post('/api/user-equipment/update/', requestData);

      // Обновляем пользователя в памяти
      updateUserEquipmentInMemory(equipmentIds);

      // Обновляем кэш
      final userJson = _user!.toJson();
      print("UPDATED USER JSON: $userJson");
      await CacheService.save(_cacheKey, userJson);
      await CacheService.save(_equipmentIdsKey, equipmentIds);

      print("USER EQUIPMENT UPDATE SUCCESSFUL");
      return true;
    } catch (e) {
      print("ERROR UPDATING USER EQUIPMENT: $e");
      return false;
    }
  }

  // Обновление оборудования пользователя только в памяти (без запроса на сервер)
  void updateUserEquipmentInMemory(List<int> equipmentIds) {
    if (_user == null) {
      print("ERROR: Cannot update equipment in memory - user is null");
      return;
    }

    print("UPDATING USER EQUIPMENT IN MEMORY: ${_user!.equipmentIds} -> $equipmentIds");
    _user = _user!.copyWith(equipmentIds: equipmentIds);
  }

  // Обновление профиля пользователя
  Future<bool> updateUserProfile(User updatedUser) async {
    print("\n===== UPDATING USER PROFILE =====");
    print("UPDATED USER: ${updatedUser.toJson()}");

    try {
      // Формируем данные для запроса
      final Map<String, dynamic> userData = {
        'usr_name': updatedUser.name,
        'usr_height': updatedUser.height,
        'usr_weight': updatedUser.weight,
        'usr_age': updatedUser.age,
        'usr_cal_day': updatedUser.caloriesPerDay,
      };

      // Добавляем пол, если он указан
      if (updatedUser.gender != null) {
        userData['usr_gender'] = updatedUser.gender!.toPostgreSqlValue();
      }

      // Отправляем запрос на сервер
      print("SENDING USER UPDATE TO SERVER...");
      final response = await _apiService.put('/api/users/profile/', userData);

      print("SERVER RESPONSE: $response");

      // Обновляем аллергены
      print("UPDATING USER ALLERGENS: ${updatedUser.allergenIds}");
      await updateUserAllergens(updatedUser.allergenIds);

      // Обновляем оборудование
      print("UPDATING USER EQUIPMENT: ${updatedUser.equipmentIds}");
      await updateUserEquipment(updatedUser.equipmentIds);

      // Обновляем пользователя в памяти
      if (response.containsKey('usr_id')) {
        print("UPDATING USER FROM RESPONSE");

        // Проверяем и обрабатываем типы данных
        _ensureCorrectDataTypes(response);

        // Если в ответе нет аллергенов/оборудования, используем данные из переданного пользователя
        if (!response.containsKey('allergenIds') || (response['allergenIds'] as List).isEmpty) {
          response['allergenIds'] = updatedUser.allergenIds;
        }
        if (!response.containsKey('equipmentIds') || (response['equipmentIds'] as List).isEmpty) {
          response['equipmentIds'] = updatedUser.equipmentIds;
        }

        _user = User.fromJson(response);
      } else {
        print("UPDATING USER FROM INPUT DATA");
        _user = updatedUser;
      }

      // Обновляем кэш
      await CacheService.save(_cacheKey, _user!.toJson());

      print("USER PROFILE UPDATE SUCCESSFUL");
      return true;
    } catch (e) {
      print("ERROR UPDATING USER PROFILE: $e");
      return false;
    }
  }

  // Очистка кэша пользователя
  Future<void> clearCache() async {
    print("\n===== CLEARING USER CACHE =====");
    await CacheService.clear(_cacheKey);
    await CacheService.clear(_allergenIdsKey);
    await CacheService.clear(_equipmentIdsKey);
    print("USER CACHE CLEARED");
  }
}