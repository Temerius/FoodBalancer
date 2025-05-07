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
      print("USER ALREADY IN MEMORY: $_user");
      return _user;
    }

    // Пробуем загрузить из кэша
    if (!cacheConfig.forceRefresh) {
      final cachedData = await CacheService.get(_cacheKey, cacheConfig);

      if (cachedData != null) {
        print("USER LOADED FROM CACHE:");
        print("Allergen IDs: ${cachedData['allergenIds'] ?? []}");
        _user = User.fromJson(cachedData);
        return _user;
      }
    }

    // Загружаем из API
    try {
      print("FETCHING USER FROM API...");
      final userData = await _apiService.get('/api/users/profile/');

      print("USER DATA FROM API:");
      print("Allergen IDs: ${userData['allergenIds'] ?? []}");

      _user = User.fromJson(userData);

      // Сохраняем в кэш
      await CacheService.save(_cacheKey, userData);

      return _user;
    } catch (e) {
      print("ERROR LOADING USER FROM API: $e");
      if (_user != null) {
        return _user; // Возвращаем данные из памяти в случае ошибки
      }
      rethrow;
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
      await _apiService.post('/api/user-allergens/update/', {
        'allergen_ids': allergenIds,
      });

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
        final allergenIds = List<int>.from(cachedData);
        print("USER ALLERGEN IDS FROM CACHE: $allergenIds");
        return allergenIds;
      }
    }

    // Загружаем из API
    try {
      print("FETCHING USER ALLERGEN IDS FROM API...");
      final response = await _apiService.get('/api/user-allergens/?limit=1000');
      List<int> allergenIds = [];

      if (response.containsKey('results')) {
        final List<dynamic> userAllergensJson = response['results'];

        for (var item in userAllergensJson) {
          if (item.containsKey('mua_alg_id')) {
            allergenIds.add(item['mua_alg_id']);
          }
        }

        print("USER ALLERGEN IDS FROM API: $allergenIds");

        // Сохраняем в кэш
        await CacheService.save(_allergenIdsKey, allergenIds);

        // Обновляем пользователя в памяти, если он существует
        if (_user != null) {
          print("UPDATING USER ALLERGEN IDS IN MEMORY");
          _user = _user!.copyWith(allergenIds: allergenIds);
          await CacheService.save(_cacheKey, _user!.toJson());
        }

        return allergenIds;
      }

      print("NO ALLERGEN IDS FOUND IN API RESPONSE");
      return [];
    } catch (e) {
      print("ERROR FETCHING USER ALLERGEN IDS: $e");
      if (_user != null) {
        return _user!.allergenIds; // Возвращаем данные из памяти в случае ошибки
      }
      return [];
    }
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

      // Обновляем аллергены, если они указаны
      if (updatedUser.allergenIds.isNotEmpty) {
        print("UPDATING USER ALLERGENS: ${updatedUser.allergenIds}");
        await updateUserAllergens(updatedUser.allergenIds);
      }

      // Обновляем оборудование, если оно указано
      if (updatedUser.equipmentIds.isNotEmpty) {
        print("UPDATING USER EQUIPMENT: ${updatedUser.equipmentIds}");
        await _apiService.post('/api/user-equipment/user_equipment/', {
          'equipment_ids': updatedUser.equipmentIds,
        });

        // Сохраняем ID оборудования в кэш
        await CacheService.save(_equipmentIdsKey, updatedUser.equipmentIds);
      }

      // Обновляем пользователя в памяти
      if (response.containsKey('usr_id')) {
        print("UPDATING USER FROM RESPONSE");
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