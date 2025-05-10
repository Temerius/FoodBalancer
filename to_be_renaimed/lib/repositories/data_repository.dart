// lib/repositories/data_repository.dart
import 'package:flutter/foundation.dart';
import 'package:to_be_renaimed/repositories/repositories/refrigerator_repository.dart';
import '../models/refrigerator_item.dart';
import '../models/user.dart';
import '../models/allergen.dart';
import '../models/equipment.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/refrigerator_service.dart';
import 'repositories/user_repository.dart';
import 'repositories/allergen_repository.dart';
import 'repositories/equipment_repository.dart';
import 'repositories/recipe_repository.dart';


import 'models/cache_config.dart';
import 'services/cache_service.dart';


class DataRepository with ChangeNotifier {
  final ApiService _apiService;

  // Репозитории
  late final UserRepository _userRepository;
  late final AllergenRepository _allergenRepository;
  late final EquipmentRepository _equipmentRepository;
  late final RecipeRepository _recipeRepository;
  late final RefrigeratorRepository _refrigeratorRepository;

  // Данные
  List<Recipe> _recipes = [];

  // Время последнего обновления
  DateTime? _lastProfileUpdate;
  DateTime? _lastAllergensUpdate;
  DateTime? _lastEquipmentUpdate;
  DateTime? _lastRecipesUpdate;

  // Интервал обновления (по умолчанию 5 минут)
  final Duration _updateInterval = const Duration(minutes: 5);

  // Состояние загрузки
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _isLoadingProfile = false;
  bool _isLoadingAllergens = false;
  bool _isLoadingEquipment = false;

  // Геттеры
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  User? get user => _userRepository.user;
  List<Allergen> get allergens => _allergenRepository.allergens;
  List<Equipment> get equipment => _equipmentRepository.equipment;
  List<Recipe> get recipes => _recipeRepository.recipes;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isLoadingAllergens => _isLoadingAllergens;
  bool get isLoadingEquipment => _isLoadingEquipment;

  List<RefrigeratorItem> get refrigeratorItems => _refrigeratorRepository.items;
  RefrigeratorStats? get refrigeratorStats => _refrigeratorRepository.stats;

  ApiService get apiService => _apiService;

  DataRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    _userRepository = UserRepository(apiService: _apiService);
    _allergenRepository = AllergenRepository(apiService: _apiService);
    _equipmentRepository = EquipmentRepository(apiService: _apiService);
    _recipeRepository = RecipeRepository(apiService: _apiService);

    final refrigeratorService = RefrigeratorService(apiService: _apiService);
    _refrigeratorRepository = RefrigeratorRepository(refrigeratorService: refrigeratorService);
  }

  // Инициализация тестовых рецептов (пока API не готов)
  void _initializeMockRecipes() {
    _recipes = List.generate(
      10,
          (index) => Recipe(
        id: index + 1,
        title: 'Рецепт ${index + 1}',
        description: 'Описание рецепта ${index + 1}. Вкусное и полезное блюдо для всей семьи.',
        calories: 250 + (index * 50),
        portionCount: 2 + (index % 4),
        isFavorite: index % 3 == 0, // Каждый третий рецепт в избранном
      ),
    );
  }

  // Метод для переключения статуса "избранное" у рецепта
  Future<bool> toggleFavoriteRecipe(int recipeId) async {
    try {
      print("\n===== TOGGLING FAVORITE STATUS FOR RECIPE ID: $recipeId =====");
      final success = await _recipeRepository.toggleFavoriteRecipe(recipeId);

      if (success) {
        notifyListeners();
      }

      return success;
    } catch (e) {
      print("ERROR TOGGLING FAVORITE: $e");
      _setError(e.toString());
      return false;
    }
  }

  // Проверка необходимости обновления данных по временной метке
  bool _needsUpdate(DateTime? lastUpdate) {
    if (lastUpdate == null) return true;
    return DateTime.now().difference(lastUpdate) > _updateInterval;
  }

  // Получение рецептов
  Future<List<Recipe>> getRecipes({bool forceRefresh = false}) async {
    // Check if we need to update data
    if (!forceRefresh && _recipeRepository.recipes.isNotEmpty && !_needsUpdate(_lastRecipesUpdate)) {
      return _recipeRepository.recipes;
    }

    _setLoading(true);
    try {
      print("\n===== GETTING RECIPES (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final recipes = await _recipeRepository.getAllRecipes(config: config);

      // Update last update time
      _lastRecipesUpdate = DateTime.now();

      notifyListeners();
      return recipes;
    } catch (e) {
      print("ERROR GETTING RECIPES: $e");
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Получение избранных рецептов
  Future<List<Recipe>> getFavoriteRecipes({bool forceRefresh = false}) async {
    _setLoading(true);
    try {
      print("\n===== GETTING FAVORITE RECIPES (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final favoriteRecipes = await _recipeRepository.getFavoriteRecipes(config: config);

      notifyListeners();
      return favoriteRecipes;
    } catch (e) {
      print("ERROR GETTING FAVORITE RECIPES: $e");
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Recipe?> getRecipeDetails(int recipeId, {bool forceRefresh = false}) async {
    try {
      print("\n===== GETTING RECIPE DETAILS FOR ID: $recipeId (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      return await _recipeRepository.getRecipeDetails(recipeId, config: config);
    } catch (e) {
      print("ERROR GETTING RECIPE DETAILS: $e");
      _setError(e.toString());
      return null;
    }
  }

  // Инициализация репозитория
  Future<void> initialize() async {
    _setLoading(true);
    try {
      print("\n===== INITIALIZING DATA REPOSITORY =====");
      // Проверяем состояние кэша
      print("CHECKING CACHE STATE...");
      await CacheService.listAllKeys();

      // Загрузка данных из кэша без принудительного обновления
      await _userRepository.getUserProfile();
      await _allergenRepository.getAllAllergens();
      await _equipmentRepository.getAllEquipment();
      await getRecipes();

      // Устанавливаем время последнего обновления
      _lastProfileUpdate = DateTime.now();
      _lastAllergensUpdate = DateTime.now();
      _lastEquipmentUpdate = DateTime.now();
      _lastRecipesUpdate = DateTime.now();

      _isInitialized = true;
      print("===== DATA REPOSITORY INITIALIZED =====");
    } catch (e) {
      print("ERROR DURING REPOSITORY INITIALIZATION: $e");
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Получение профиля пользователя
  Future<User?> getUserProfile({bool forceRefresh = false}) async {
    // Проверяем, нужно ли обновлять данные
    if (!forceRefresh && user != null && !_needsUpdate(_lastProfileUpdate)) {
      return user;
    }

    _isLoadingProfile = true;
    notifyListeners();

    try {
      print("\n===== GETTING USER PROFILE (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final userObj = await _userRepository.getUserProfile(config: config);

      // Обновляем время последнего обновления
      if (userObj != null) {
        _lastProfileUpdate = DateTime.now();
      }

      notifyListeners();
      return userObj;
    } catch (e) {
      print("ERROR GETTING USER PROFILE: $e");
      _setError(e.toString());
      return null;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // Получение оборудования
  Future<List<Equipment>> getEquipment({bool forceRefresh = false}) async {
    // Проверяем, нужно ли обновлять данные
    if (!forceRefresh && _equipmentRepository.equipment.isNotEmpty && !_needsUpdate(_lastEquipmentUpdate)) {
      // Обновляем флаги isSelected для имеющихся данных
      if (user != null) {
        for (var equipment in _equipmentRepository.equipment) {
          equipment.isSelected = user!.equipmentIds.contains(equipment.id);
        }
      }
      return _equipmentRepository.equipment;
    }

    _isLoadingEquipment = true;
    notifyListeners();

    try {
      print("\n===== GETTING EQUIPMENT (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;
      final equipmentList = await _equipmentRepository.getAllEquipment(config: config);

      // Если у пользователя есть оборудование, отмечаем его в списке
      if (user != null) {
        for (var equipment in equipmentList) {
          equipment.isSelected = user!.equipmentIds.contains(equipment.id);
        }
      }

      // Обновляем время последнего обновления
      _lastEquipmentUpdate = DateTime.now();

      notifyListeners();
      return equipmentList;
    } catch (e) {
      print("ERROR GETTING EQUIPMENT: $e");
      _setError(e.toString());
      return [];
    } finally {
      _isLoadingEquipment = false;
      notifyListeners();
    }
  }

  // Обновление пользователя и его данных
  Future<void> refreshUserData() async {
    _setLoading(true);
    try {
      print("\n===== REFRESHING USER DATA =====");

      // Загрузка пользователя с принудительным обновлением только если прошло достаточно времени
      if (_needsUpdate(_lastProfileUpdate)) {
        await _userRepository.getUserProfile(config: CacheConfig.refresh);
        _lastProfileUpdate = DateTime.now();
      }

      // Обновляем аллергены и оборудование пользователя только если нужно
      if (_needsUpdate(_lastAllergensUpdate)) {
        await refreshUserAllergens(silent: true);
        _lastAllergensUpdate = DateTime.now();
      } else {
        await _syncUserAllergens();
      }

      if (_needsUpdate(_lastEquipmentUpdate)) {
        await refreshUserEquipment(silent: true);
        _lastEquipmentUpdate = DateTime.now();
      } else {
        await _syncUserEquipment();
      }

      // Обновляем рецепты только если нужно
      if (_needsUpdate(_lastRecipesUpdate)) {
        await getRecipes(forceRefresh: true);
        _lastRecipesUpdate = DateTime.now();
      }

      print("===== USER DATA REFRESHED =====");
      notifyListeners();
    } catch (e) {
      print("ERROR REFRESHING USER DATA: $e");
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Получение всех аллергенов
  Future<List<Allergen>> getAllAllergens({bool forceRefresh = false}) async {
    // Проверяем, нужно ли обновлять данные
    if (!forceRefresh && _allergenRepository.allergens.isNotEmpty && !_needsUpdate(_lastAllergensUpdate)) {
      // Обновляем флаги isSelected для имеющихся данных
      if (user != null) {
        for (var allergen in _allergenRepository.allergens) {
          allergen.isSelected = user!.allergenIds.contains(allergen.id);
        }
      }
      return _allergenRepository.allergens;
    }

    _isLoadingAllergens = true;
    notifyListeners();

    try {
      print("\n===== GETTING ALL ALLERGENS (forceRefresh: $forceRefresh) =====");
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;

      // Получаем аллергены
      final allergensData = await _allergenRepository.getAllAllergens(config: config);

      // Если у пользователя есть аллергены, отмечаем их в списке
      if (user != null && user!.allergenIds.isNotEmpty) {
        for (var allergen in allergensData) {
          allergen.isSelected = user!.allergenIds.contains(allergen.id);
        }
      }

      // Обновляем время последнего обновления
      _lastAllergensUpdate = DateTime.now();

      notifyListeners();
      return allergensData;
    } catch (e) {
      print("===== ERROR LOADING ALLERGENS: $e =====");
      _setError(e.toString());
      return [];
    } finally {
      _isLoadingAllergens = false;
      notifyListeners();
    }
  }

  // Синхронизация аллергенов пользователя с локальными данными (без загрузки с сервера)
  Future<void> _syncUserAllergens() async {
    if (user == null || _allergenRepository.allergens.isEmpty) return;

    try {
      // Обновляем флаги "выбрано" в списке аллергенов
      for (var allergen in _allergenRepository.allergens) {
        allergen.isSelected = user!.allergenIds.contains(allergen.id);
      }
    } catch (e) {
      print("ERROR SYNCING USER ALLERGENS: $e");
    }
  }

  // Синхронизация оборудования пользователя с локальными данными (без загрузки с сервера)
  Future<void> _syncUserEquipment() async {
    if (user == null || _equipmentRepository.equipment.isEmpty) return;

    try {
      // Обновляем флаги "выбрано" в списке оборудования
      for (var equipment in _equipmentRepository.equipment) {
        equipment.isSelected = user!.equipmentIds.contains(equipment.id);
      }
    } catch (e) {
      print("ERROR SYNCING USER EQUIPMENT: $e");
    }
  }

  // Обновление аллергенов пользователя
  Future<void> refreshUserAllergens({bool silent = false}) async {
    if (!silent) {
      _isLoadingAllergens = true;
      notifyListeners();
    }

    try {
      print("\n===== REFRESHING USER ALLERGENS =====");

      // Получаем ID аллергенов пользователя с пометкой принудительного обновления
      final allergenIds = await _userRepository.getUserAllergenIds(config: CacheConfig.refresh);

      // Обновляем пользователя в памяти, если он существует
      if (user != null) {
        // Обновляем список аллергенов в объекте пользователя
        _userRepository.updateUserAllergensInMemory(allergenIds);

        // Обновляем флаги "выбрано" в списке аллергенов
        for (var allergen in _allergenRepository.allergens) {
          allergen.isSelected = allergenIds.contains(allergen.id);
        }
      }

      // Обновляем время последнего обновления
      _lastAllergensUpdate = DateTime.now();

      if (!silent) notifyListeners();
    } catch (e) {
      print("===== ERROR REFRESHING USER ALLERGENS: $e =====");
      if (!silent) _setError(e.toString());
    } finally {
      if (!silent) {
        _isLoadingAllergens = false;
        notifyListeners();
      }
    }
  }

  // Обновление оборудования пользователя
  Future<void> refreshUserEquipment({bool silent = false}) async {
    if (!silent) {
      _isLoadingEquipment = true;
      notifyListeners();
    }

    try {
      print("\n===== REFRESHING USER EQUIPMENT =====");

      // Получаем ID оборудования пользователя с пометкой принудительного обновления
      final equipmentIds = await _userRepository.getUserEquipmentIds(config: CacheConfig.refresh);

      // Обновляем пользователя в памяти, если он существует
      if (user != null) {
        // Обновляем список оборудования в объекте пользователя
        _userRepository.updateUserEquipmentInMemory(equipmentIds);

        // Обновляем флаги "выбрано" в списке оборудования
        for (var equipment in _equipmentRepository.equipment) {
          equipment.isSelected = equipmentIds.contains(equipment.id);
        }
      }

      // Обновляем время последнего обновления
      _lastEquipmentUpdate = DateTime.now();

      if (!silent) notifyListeners();
    } catch (e) {
      print("===== ERROR REFRESHING USER EQUIPMENT: $e =====");
      if (!silent) _setError(e.toString());
    } finally {
      if (!silent) {
        _isLoadingEquipment = false;
        notifyListeners();
      }
    }
  }

  // Обновление профиля пользователя
  Future<bool> updateUserProfile(User updatedUser) async {
    _isLoadingProfile = true;
    notifyListeners();

    try {
      // Сначала устанавливаем данные локально, чтобы UI обновился быстрее
      if (_userRepository.user != null) {
        _userRepository.updateUserAllergensInMemory(updatedUser.allergenIds);
        _userRepository.updateUserEquipmentInMemory(updatedUser.equipmentIds);

        // Обновляем флаги выбора в списках аллергенов и оборудования
        for (var allergen in _allergenRepository.allergens) {
          allergen.isSelected = updatedUser.allergenIds.contains(allergen.id);
        }

        for (var equipment in _equipmentRepository.equipment) {
          equipment.isSelected = updatedUser.equipmentIds.contains(equipment.id);
        }

        // Уведомляем об изменении, чтобы UI обновился
        notifyListeners();
      }

      // Затем отправляем данные на сервер
      final success = await _userRepository.updateUserProfile(updatedUser);

      if (success) {
        // Обновляем время последнего обновления
        _lastProfileUpdate = DateTime.now();
        _lastAllergensUpdate = DateTime.now();
        _lastEquipmentUpdate = DateTime.now();

        // Уведомляем об изменении
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Ошибка обновления профиля: $e';
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
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
    await _recipeRepository.clearCache();
    await _refrigeratorRepository.clearCache();

    // Сбрасываем временные метки
    _lastProfileUpdate = null;
    _lastAllergensUpdate = null;
    _lastEquipmentUpdate = null;
    _lastRecipesUpdate = null;
  }
}