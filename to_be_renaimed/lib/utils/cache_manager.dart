import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  // Ключи для хранения данных
  static const String _userKey = 'user_data';
  static const String _allergensKey = 'allergens_data';
  static const String _equipmentKey = 'equipment_data';
  static const String _ingredientTypesKey = 'ingredient_types_data';
  static const String _ingredientsKey = 'ingredients_data';
  static const String _recipesKey = 'recipes_data';
  static const String _recipesDetailsKey = 'recipes_details_data';
  static const String _mealPlanKey = 'meal_plan_data';
  static const String _shoppingListKey = 'shopping_list_data';
  static const String _lastUpdateKey = 'last_update';
  static const String _expireTimeKey = 'expire_time';

  // Время жизни кэша в миллисекундах (по умолчанию 24 часа)
  static const int _defaultCacheLifetime = 24 * 60 * 60 * 1000;

  // Получение SharedPreferences
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Сохранение данных в кэш
  static Future<bool> saveData(String key, dynamic data, {int? expiryTimeMs}) async {
    final prefs = await _prefs;

    // Сохраняем данные в формате JSON
    final jsonString = jsonEncode(data);
    final result = await prefs.setString(key, jsonString);

    // Обновляем время последнего обновления
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

    // Если указано время истечения кэша, сохраняем его
    if (expiryTimeMs != null) {
      await prefs.setInt(key + _expireTimeKey, expiryTimeMs);
    }

    return result;
  }

  // Получение данных из кэша
  static Future<dynamic> getData(String key, {bool checkExpiry = true}) async {
    final prefs = await _prefs;

    // Проверяем, истек ли срок действия кэша
    if (checkExpiry && await isExpired(key)) {
      return null;
    }

    // Получаем данные
    final jsonString = prefs.getString(key);
    if (jsonString == null) {
      return null;
    }

    try {
      return jsonDecode(jsonString);
    } catch (e) {
      // Если произошла ошибка при декодировании, удаляем поврежденные данные
      await prefs.remove(key);
      return null;
    }
  }

  // Проверка, истек ли срок действия кэша
  static Future<bool> isExpired(String key) async {
    final prefs = await _prefs;

    // Получаем время последнего обновления
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;

    // Получаем указанное время жизни кэша для данного ключа или используем значение по умолчанию
    final expireTime = prefs.getInt(key + _expireTimeKey) ?? _defaultCacheLifetime;

    // Вычисляем, истек ли срок действия
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastUpdate) > expireTime;
  }

  // Удаление конкретного кэша
  static Future<bool> removeData(String key) async {
    final prefs = await _prefs;
    final result = await prefs.remove(key);

    // Удаляем также метаданные кэша
    await prefs.remove(key + _expireTimeKey);

    return result;
  }

  // Очистка всего кэша
  static Future<bool> clearAll() async {
    final prefs = await _prefs;
    final result = await prefs.clear();
    return result;
  }

  // Принудительное обновление времени кэша
  static Future<void> touchCache() async {
    final prefs = await _prefs;
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Проверка, просрочен ли весь кэш
  static Future<bool> isAllCacheExpired({int customExpiry = _defaultCacheLifetime}) async {
    final prefs = await _prefs;
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastUpdate) > customExpiry;
  }

  // Методы для работы с конкретными типами данных

  // Пользователь
  static Future<bool> saveUser(Map<String, dynamic> userData) async {
    return saveData(_userKey, userData);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final data = await getData(_userKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  // Аллергены
  static Future<bool> saveAllergens(List<Map<String, dynamic>> allergensData) async {
    return saveData(_allergensKey, allergensData);
  }

  static Future<List<Map<String, dynamic>>?> getAllergens() async {
    final data = await getData(_allergensKey);
    if (data == null) return null;

    return List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item))
    );
  }

  // Оборудование
  static Future<bool> saveEquipment(List<Map<String, dynamic>> equipmentData) async {
    return saveData(_equipmentKey, equipmentData);
  }

  static Future<List<Map<String, dynamic>>?> getEquipment() async {
    final data = await getData(_equipmentKey);
    if (data == null) return null;

    return List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item))
    );
  }

  // Типы ингредиентов
  static Future<bool> saveIngredientTypes(List<Map<String, dynamic>> typesData) async {
    return saveData(_ingredientTypesKey, typesData);
  }

  static Future<List<Map<String, dynamic>>?> getIngredientTypes() async {
    final data = await getData(_ingredientTypesKey);
    if (data == null) return null;

    return List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item))
    );
  }

  // Рецепты
  static Future<bool> saveRecipes(List<Map<String, dynamic>> recipesData) async {
    return saveData(_recipesKey, recipesData);
  }

  static Future<List<Map<String, dynamic>>?> getRecipes() async {
    final data = await getData(_recipesKey);
    if (data == null) return null;

    return List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item))
    );
  }

  // Детали рецептов
  static Future<bool> saveRecipeDetails(Map<String, dynamic> detailsMap) async {
    return saveData(_recipesDetailsKey, detailsMap);
  }

  static Future<Map<String, dynamic>?> getRecipeDetails() async {
    final data = await getData(_recipesDetailsKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  // План питания
  static Future<bool> saveMealPlan(Map<String, dynamic> mealPlanData) async {
    return saveData(_mealPlanKey, mealPlanData);
  }

  static Future<Map<String, dynamic>?> getMealPlan() async {
    final data = await getData(_mealPlanKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  // Список покупок
  static Future<bool> saveShoppingList(Map<String, dynamic> shoppingListData) async {
    return saveData(_shoppingListKey, shoppingListData);
  }

  static Future<Map<String, dynamic>?> getShoppingList() async {
    final data = await getData(_shoppingListKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
}