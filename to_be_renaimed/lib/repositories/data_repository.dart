// lib/repositories/data_repository.dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/allergen.dart';
import '../models/equipment.dart';
import '../services/api_service.dart';
import 'repositories/user_repository.dart';
import 'repositories/allergen_repository.dart';
import 'repositories/equipment_repository.dart';
import 'models/cache_config.dart';

class DataRepository with ChangeNotifier {
  final ApiService _apiService;

  // Репозитории
  late final UserRepository _userRepository;
  late final AllergenRepository _allergenRepository;
  late final EquipmentRepository _equipmentRepository;

  // Состояние загрузки
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Геттеры
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  User? get user => _userRepository.user;
  List<Allergen> get allergens => _allergenRepository.allergens;
  List<Equipment> get equipment => _equipmentRepository.equipment;

  DataRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    _userRepository = UserRepository(apiService: _apiService);
    _allergenRepository = AllergenRepository(apiService: _apiService);
    _equipmentRepository = EquipmentRepository(apiService: _apiService);
  }

  // Добавить в класс DataRepository

// Метод для переключения статуса "избранное" у рецепта
  Future<void> toggleFavoriteRecipe(int recipeId) async {
    try {
      // Найти рецепт по ID
      final recipeIndex = _recipes.indexWhere((recipe) => recipe.id == recipeId);

      if (recipeIndex != -1) {
        // Изменить статус избранного
        final recipe = _recipes[recipeIndex];
        final isFavorite = !recipe.isFavorite;

        // Обновить рецепт в памяти
        _recipes[recipeIndex] = recipe.copyWith(isFavorite: isFavorite);

        // Отправить запрос на сервер
        if (isFavorite) {
          await _apiService.post('/api/favorites/', {'recipe_id': recipeId});
        } else {
          await _apiService.delete('/api/favorites/$recipeId/');
        }

        // Уведомить подписчиков об изменении
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Инициализация репозитория
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Загрузка данных из кэша
      await _userRepository.getUserProfile();
      await _allergenRepository.getAllAllergens();
      await _equipmentRepository.getAllEquipment();

      _isInitialized = true;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Обновление пользователя и его данных
  Future<void> refreshUserData() async {
    _setLoading(true);
    try {
      // Загрузка пользователя с принудительным обновлением
      await _userRepository.getUserProfile(config: CacheConfig.refresh);
      await _allergenRepository.getAllAllergens();
      await _equipmentRepository.getAllEquipment();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Получение всех аллергенов
  Future<List<Allergen>> getAllAllergens({bool forceRefresh = false}) async {
    try {
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      return await _allergenRepository.getAllAllergens(config: config);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  // Обновление аллергенов пользователя
  Future<void> refreshUserAllergens() async {
    try {
      final allergenIds = await _userRepository.getUserAllergenIds(config: CacheConfig.refresh);
      if (user != null) {
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Обновление профиля пользователя
  Future<bool> updateUserProfile(User updatedUser) async {
    _setLoading(true);
    try {
      final success = await _userRepository.updateUserProfile(updatedUser);

      if (success) {
        notifyListeners();
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Вспомогательные методы
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Очистка всего кэша
  Future<void> clearAllCache() async {
    await _userRepository.clearCache();
    await _allergenRepository.clearCache();
    await _equipmentRepository.clearCache();
  }


}