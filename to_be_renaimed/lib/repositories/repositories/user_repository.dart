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
        _user = User.fromJson(cachedData);
        return _user;
      }
    }

    // Загружаем из API
    try {
      final userData = await _apiService.get('/api/users/profile/');
      _user = User.fromJson(userData);

      // Сохраняем в кэш
      await CacheService.save(_cacheKey, userData);

      return _user;
    } catch (e) {
      if (_user != null) {
        return _user; // Возвращаем данные из памяти в случае ошибки
      }
      rethrow;
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
      await _apiService.post('/api/user-allergens/update/', {
        'allergen_ids': allergenIds,
      });

      // Обновляем пользователя в памяти
      _user = _user!.copyWith(allergenIds: allergenIds);

      // Обновляем кэш
      await CacheService.save(_cacheKey, _user!.toJson());
      await CacheService.save(_allergenIdsKey, allergenIds);

      return true;
    } catch (e) {
      return false;
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
        return List<int>.from(cachedData);
      }
    }

    // Загружаем из API
    try {
      final response = await _apiService.get('/api/user-allergens/?limit=1000');
      List<int> allergenIds = [];

      if (response.containsKey('results')) {
        final List<dynamic> userAllergensJson = response['results'];

        for (var item in userAllergensJson) {
          if (item.containsKey('mua_alg_id')) {
            allergenIds.add(item['mua_alg_id']);
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
      }

      return [];
    } catch (e) {
      if (_user != null) {
        return _user!.allergenIds; // Возвращаем данные из памяти в случае ошибки
      }
      return [];
    }
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

      // Обновляем аллергены, если они указаны
      if (updatedUser.allergenIds.isNotEmpty) {
        await updateUserAllergens(updatedUser.allergenIds);
      }

      // Обновляем оборудование, если оно указано
      if (updatedUser.equipmentIds.isNotEmpty) {
        await _apiService.post('/api/user-equipment/user_equipment/', {
          'equipment_ids': updatedUser.equipmentIds,
        });

        // Сохраняем ID оборудования в кэш
        await CacheService.save(_equipmentIdsKey, updatedUser.equipmentIds);
      }

      // Обновляем пользователя в памяти
      if (response.containsKey('usr_id')) {
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