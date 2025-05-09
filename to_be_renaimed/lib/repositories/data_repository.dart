// lib/repositories/data_repository.dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/allergen.dart';
import '../models/equipment.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import 'repositories/user_repository.dart';
import 'repositories/allergen_repository.dart';
import 'repositories/equipment_repository.dart';
import 'models/cache_config.dart';
import 'services/cache_service.dart';

class DataRepository with ChangeNotifier {
  final ApiService _apiService;

  // Репозитории
  late final UserRepository _userRepository;
  late final AllergenRepository _allergenRepository;
  late final EquipmentRepository _equipmentRepository;

  // Данные
  List<Recipe> _recipes = [];

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
  List<Recipe> get recipes => _recipes;

  DataRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    _userRepository = UserRepository(apiService: _apiService);
    _allergenRepository = AllergenRepository(apiService: _apiService);
    _equipmentRepository = EquipmentRepository(apiService: _apiService);

    // Инициализация тестовых рецептов для примера
    _initializeMockRecipes();
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
        try {
          if (isFavorite) {
            await _apiService.post('/api/favorites/', {'recipe_id': recipeId});
          } else {
            await _apiService.delete('/api/favorites/$recipeId/');
          }
        } catch (e) {
          // В случае ошибки API, все равно обновляем локальное состояние
          print('API error when toggling favorite: $e');
        }

        // Уведомить подписчиков об изменении
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Получение рецептов
  Future<List<Recipe>> getRecipes({bool forceRefresh = false}) async {
    if (!forceRefresh && _recipes.isNotEmpty) {
      return _recipes;
    }

    _setLoading(true);
    try {
      // В реальном приложении здесь будет запрос к API
      // final response = await _apiService.get('/api/recipes/?limit=100');
      // _recipes = List<Map<String, dynamic>>.from(response['results'])
      //   .map((json) => Recipe.fromJson(json))
      //   .toList();

      // Пока используем моковые данные
      await Future.delayed(const Duration(milliseconds: 500)); // Симуляция задержки API
      _initializeMockRecipes();

      notifyListeners();
      return _recipes;
    } catch (e) {
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Получение избранных рецептов
  List<Recipe> getFavoriteRecipes() {
    return _recipes.where((recipe) => recipe.isFavorite).toList();
  }

  // Инициализация репозитория
  Future<void> initialize() async {
    _setLoading(true);
    try {
      print("\n===== INITIALIZING DATA REPOSITORY =====");
      // Проверяем состояние кэша
      print("CHECKING CACHE STATE...");
      await CacheService.listAllKeys();

      // Загрузка данных из кэша
      await _userRepository.getUserProfile();
      await _allergenRepository.getAllAllergens();
      await _equipmentRepository.getAllEquipment();
      await getRecipes();

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
  Future<User?> getUserProfile({CacheConfig? config}) async {
    _setLoading(true);
    try {
      print("\n===== GETTING USER PROFILE =====");
      final user = await _userRepository.getUserProfile(config: config);
      notifyListeners();
      return user;
    } catch (e) {
      print("ERROR GETTING USER PROFILE: $e");
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Получение оборудования
  Future<List<Equipment>> getEquipment({bool forceRefresh = false}) async {
    _setLoading(true);
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

      notifyListeners();
      return equipmentList;
    } catch (e) {
      print("ERROR GETTING EQUIPMENT: $e");
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Обновление пользователя и его данных
  Future<void> refreshUserData() async {
    _setLoading(true);
    try {
      print("\n===== REFRESHING USER DATA =====");

      // Загрузка пользователя с принудительным обновлением
      await _userRepository.getUserProfile(config: CacheConfig.refresh);

      // Обновляем аллергены и оборудование пользователя
      await refreshUserAllergens();
      await refreshUserEquipment();

      // Обновляем рецепты
      await getRecipes(forceRefresh: true);

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
    print("\n===== GETTING ALL ALLERGENS (forceRefresh: $forceRefresh) =====");
    try {
      final config = forceRefresh ? CacheConfig.refresh : CacheConfig.defaultConfig;

      // Выводим список всех ключей кэша
      await CacheService.listAllKeys();

      // Получаем аллергены
      final allergens = await _allergenRepository.getAllAllergens(config: config);

      print("===== ALLERGENS LOADED: ${allergens.length} items =====");

      // Если у пользователя есть аллергены, отмечаем их в списке
      if (user != null && user!.allergenIds.isNotEmpty) {
        for (var allergen in allergens) {
          allergen.isSelected = user!.allergenIds.contains(allergen.id);
        }
      }

      notifyListeners();
      return allergens;
    } catch (e) {
      print("===== ERROR LOADING ALLERGENS: $e =====");
      _setError(e.toString());
      return [];
    }
  }

  // Обновление аллергенов пользователя
  Future<void> refreshUserAllergens() async {
    print("\n===== REFRESHING USER ALLERGENS =====");
    try {
      // Выводим дамп кэша до обновления
      print("CACHE BEFORE REFRESH:");
      await CacheService.dumpCache();

      // Получаем ID аллергенов пользователя
      final allergenIds = await _userRepository.getUserAllergenIds(config: CacheConfig.refresh);

      print("USER ALLERGEN IDS FROM SERVER: $allergenIds");

      // Обновляем пользователя в памяти, если он существует
      if (user != null) {
        print("UPDATING USER ALLERGEN IDS IN MEMORY: ${user!.allergenIds} -> $allergenIds");

        // Обновляем список аллергенов в объекте пользователя
        _userRepository.updateUserAllergensInMemory(allergenIds);

        // Обновляем флаги "выбрано" в списке аллергенов
        for (var allergen in _allergenRepository.allergens) {
          allergen.isSelected = allergenIds.contains(allergen.id);
        }

        notifyListeners();
      }

      // Выводим дамп кэша после обновления
      print("CACHE AFTER REFRESH:");
      await CacheService.dumpCache();

      print("===== USER ALLERGENS REFRESH COMPLETED =====");
    } catch (e) {
      print("===== ERROR REFRESHING USER ALLERGENS: $e =====");
      _setError(e.toString());
    }
  }

  // Обновление оборудования пользователя
  Future<void> refreshUserEquipment() async {
    print("\n===== REFRESHING USER EQUIPMENT =====");
    try {
      // Выводим дамп кэша до обновления
      print("CACHE BEFORE REFRESH:");
      await CacheService.dumpCache();

      // Получаем ID оборудования пользователя
      final equipmentIds = await _userRepository.getUserEquipmentIds(config: CacheConfig.refresh);

      print("USER EQUIPMENT IDS FROM SERVER: $equipmentIds");

      // Обновляем пользователя в памяти, если он существует
      if (user != null) {
        print("UPDATING USER EQUIPMENT IDS IN MEMORY: ${user!.equipmentIds} -> $equipmentIds");

        // Обновляем список оборудования в объекте пользователя
        _userRepository.updateUserEquipmentInMemory(equipmentIds);

        // Обновляем флаги "выбрано" в списке оборудования
        for (var equipment in _equipmentRepository.equipment) {
          equipment.isSelected = equipmentIds.contains(equipment.id);
        }

        notifyListeners();
      }

      // Выводим дамп кэша после обновления
      print("CACHE AFTER REFRESH:");
      await CacheService.dumpCache();

      print("===== USER EQUIPMENT REFRESH COMPLETED =====");
    } catch (e) {
      print("===== ERROR REFRESHING USER EQUIPMENT: $e =====");
      _setError(e.toString());
    }
  }

  // Обновление профиля пользователя
  Future<bool> updateUserProfile(User updatedUser) async {
    try {
      final success = await _userRepository.updateUserProfile(updatedUser);

      if (success) {
        // Форсированное обновление кэша оборудования и аллергенов после обновления профиля
        await _userRepository.getUserAllergenIds(config: CacheConfig(forceRefresh: true));
        await _userRepository.getUserEquipmentIds(config: CacheConfig(forceRefresh: true));

        // Обновляем флаги выбора в списках аллергенов и оборудования
        for (var allergen in _allergenRepository.allergens) {
          allergen.isSelected = updatedUser.allergenIds.contains(allergen.id);
        }

        for (var equipment in _equipmentRepository.equipment) {
          equipment.isSelected = updatedUser.equipmentIds.contains(equipment.id);
        }

        // Обновляем все, что зависит от профиля пользователя
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Ошибка обновления профиля: $e';
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