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

    // Если пользователь уже в памяти и не требуется обновление
    if (_user != null && !cacheConfig.forceRefresh) {
      return _user;
    }

    // Пробуем загрузить из кэша
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        try {
          // Проверяем формат данных перед созданием User
          _ensureCorrectDataTypes(cachedData);
          _user = User.fromJson(cachedData);
          return _user;
        } catch (e) {
          // Продолжаем и пытаемся получить из API
        }
      }
    }

    // Загружаем из API
    try {
      final userData = await _apiService.get('/api/users/profile/');

      try {
        // Проверяем формат данных перед созданием User
        _ensureCorrectDataTypes(userData);
        _user = User.fromJson(userData);

        // Сохраняем в кэш
        await CacheService.save(_cacheKey, userData);

        return _user;
      } catch (e) {
        throw Exception('Ошибка при обработке данных пользователя: $e');
      }
    } catch (e) {
      if (_user != null) {
        return _user; // Возвращаем данные из памяти в случае ошибки
      }
      rethrow;
    }
  }

  // Проверка и исправление типов данных в JSON
  void _ensureCorrectDataTypes(Map<String, dynamic> userData) {
    // Обрабатываем allergenIds
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
        // Если allergenIds не список, создаем пустой список
        userData['allergenIds'] = <int>[];
      }
    } else {
      // Если allergenIds отсутствует, создаем пустой список
      userData['allergenIds'] = <int>[];
    }

    // Обрабатываем equipmentIds по аналогии
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
        // Если equipmentIds не список, создаем пустой список
        userData['equipmentIds'] = <int>[];
      }
    } else {
      // Если equipmentIds отсутствует, создаем пустой список
      userData['equipmentIds'] = <int>[];
    }
  }

  // Получение ID аллергенов пользователя
  Future<List<int>> getUserAllergenIds({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;

    // Если пользователь уже в памяти
    if (_user != null && !cacheConfig.forceRefresh) {
      return _user!.allergenIds;
    }

    // Пробуем загрузить из кэша
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
          // Если произошла ошибка, продолжаем загрузку из API
        }
      }
    }

    // Загружаем из API
    try {
      // Получаем данные, теперь API может вернуть список напрямую
      final response = await _apiService.get('/api/user-allergens/');
      List<int> allergenIds = [];

      // Проверяем, вернулся ли список в поле results или напрямую
      if (response.containsKey('results')) {
        final List<dynamic> userAllergensJson = response['results'];

        for (var item in userAllergensJson) {
          _extractAllergenId(item, allergenIds);
        }
      } else {
        // Если в ответе нет поля results, проверяем, может быть ответ сам по себе список
        final rawData = response['raw_data'] ?? response;

        if (rawData is List) {
          for (var item in rawData) {
            _extractAllergenId(item, allergenIds);
          }
        }
      }

      // Сохраняем в кэш
      await CacheService.save(_allergenIdsKey, allergenIds);

      // Обновляем пользователя в памяти, если он существует
      if (_user != null) {
        _user = _user!.copyWith(allergenIds: allergenIds);
        await CacheService.save(_cacheKey, _user!.toJson());
      }

      return allergenIds;
    } catch (e) {
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
          }
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
      }
    }
  }

  // Получение ID оборудования пользователя
  Future<List<int>> getUserEquipmentIds({CacheConfig? config}) async {
    final cacheConfig = config ?? CacheConfig.defaultConfig;

    // Если пользователь уже в памяти
    if (_user != null && !cacheConfig.forceRefresh) {
      return _user!.equipmentIds;
    }

    // Пробуем загрузить из кэша
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
          // Если произошла ошибка, продолжаем загрузку из API
        }
      }
    }

    // Загружаем из API
    try {
      // Получаем данные, теперь API может вернуть список напрямую
      final response = await _apiService.get('/api/user-equipment/');
      List<int> equipmentIds = [];

      // Проверяем, вернулся ли список в поле results или напрямую
      if (response.containsKey('results')) {
        final List<dynamic> userEquipmentJson = response['results'];

        for (var item in userEquipmentJson) {
          _extractEquipmentId(item, equipmentIds);
        }
      } else {
        // Если в ответе нет поля results, проверяем, может быть ответ сам по себе список
        final rawData = response['raw_data'] ?? response;

        if (rawData is List) {
          for (var item in rawData) {
            _extractEquipmentId(item, equipmentIds);
          }
        }
      }

      // Сохраняем в кэш
      await CacheService.save(_equipmentIdsKey, equipmentIds);

      // Обновляем пользователя в памяти, если он существует
      if (_user != null) {
        _user = _user!.copyWith(equipmentIds: equipmentIds);
        await CacheService.save(_cacheKey, _user!.toJson());
      }

      return equipmentIds;
    } catch (e) {
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
          }
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
      }
    }
  }

  // Обновление аллергенов пользователя
  Future<bool> updateUserAllergens(List<int> allergenIds) async {
    if (_user == null) {
      await getUserProfile();

      if (_user == null) {
        return false;
      }
    }

    try {
      // Отправляем запрос на сервер
      final requestData = {
        'allergen_ids': allergenIds,
      };

      await _apiService.post('/api/user-allergens/update/', requestData);

      // Обновляем пользователя в памяти
      updateUserAllergensInMemory(allergenIds);

      // Обновляем кэш
      final userJson = _user!.toJson();
      await CacheService.save(_cacheKey, userJson);
      await CacheService.save(_allergenIdsKey, allergenIds);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Обновление аллергенов пользователя только в памяти (без запроса на сервер)
  void updateUserAllergensInMemory(List<int> allergenIds) {
    if (_user == null) {
      return;
    }

    _user = _user!.copyWith(allergenIds: allergenIds);
  }

  // Обновление оборудования пользователя
  Future<bool> updateUserEquipment(List<int> equipmentIds) async {
    if (_user == null) {
      await getUserProfile();

      if (_user == null) {
        return false;
      }
    }

    try {
      // Отправляем запрос на сервер
      final requestData = {
        'equipment_ids': equipmentIds,
      };

      await _apiService.post('/api/user-equipment/update/', requestData);

      // Обновляем пользователя в памяти
      updateUserEquipmentInMemory(equipmentIds);

      // Обновляем кэш
      final userJson = _user!.toJson();
      await CacheService.save(_cacheKey, userJson);
      await CacheService.save(_equipmentIdsKey, equipmentIds);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Обновление оборудования пользователя только в памяти (без запроса на сервер)
  void updateUserEquipmentInMemory(List<int> equipmentIds) {
    if (_user == null) {
      return;
    }

    _user = _user!.copyWith(equipmentIds: equipmentIds);
  }

  // Обновление профиля пользователя
  Future<bool> updateUserProfile(User updatedUser) async {
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
      final response = await _apiService.put('/api/users/profile/', userData);

      // Обновляем аллергены
      await updateUserAllergens(updatedUser.allergenIds);

      // Обновляем оборудование
      await updateUserEquipment(updatedUser.equipmentIds);

      // Обновляем пользователя в памяти
      if (response.containsKey('usr_id')) {
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
        _user = updatedUser;
      }

      // Обновляем кэш
      await CacheService.save(_cacheKey, _user!.toJson());

      return true;
    } catch (e) {
      return false;
    }
  }

  // Очистка кэша пользователя
  Future<void> clearCache() async {
    await CacheService.clear(_cacheKey);
    await CacheService.clear(_allergenIdsKey);
    await CacheService.clear(_equipmentIdsKey);
  }
}