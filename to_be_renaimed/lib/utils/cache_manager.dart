import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  
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

  
  static const int _defaultCacheLifetime = 24 * 60 * 60 * 1000;

  
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  
  static Future<bool> saveData(String key, dynamic data, {int? expiryTimeMs}) async {
    final prefs = await _prefs;

    
    final jsonString = jsonEncode(data);
    final result = await prefs.setString(key, jsonString);

    
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

    
    if (expiryTimeMs != null) {
      await prefs.setInt(key + _expireTimeKey, expiryTimeMs);
    }

    return result;
  }

  
  static Future<dynamic> getData(String key, {bool checkExpiry = true}) async {
    final prefs = await _prefs;

    
    if (checkExpiry && await isExpired(key)) {
      return null;
    }

    
    final jsonString = prefs.getString(key);
    if (jsonString == null) {
      return null;
    }

    try {
      return jsonDecode(jsonString);
    } catch (e) {
      
      await prefs.remove(key);
      return null;
    }
  }

  
  static Future<bool> isExpired(String key) async {
    final prefs = await _prefs;

    
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;

    
    final expireTime = prefs.getInt(key + _expireTimeKey) ?? _defaultCacheLifetime;

    
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastUpdate) > expireTime;
  }

  
  static Future<bool> removeData(String key) async {
    final prefs = await _prefs;
    final result = await prefs.remove(key);

    
    await prefs.remove(key + _expireTimeKey);

    return result;
  }

  
  static Future<bool> clearAll() async {
    final prefs = await _prefs;
    final result = await prefs.clear();
    return result;
  }

  
  static Future<void> touchCache() async {
    final prefs = await _prefs;
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  
  static Future<bool> isAllCacheExpired({int customExpiry = _defaultCacheLifetime}) async {
    final prefs = await _prefs;
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastUpdate) > customExpiry;
  }

  

  
  static Future<bool> saveUser(Map<String, dynamic> userData) async {
    return saveData(_userKey, userData);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final data = await getData(_userKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  
  static Future<bool> saveAllergens(List<Map<String, dynamic>> allergensData) async {
    final result = await saveData(_allergensKey, allergensData);
    if (result) {
      await saveUpdateTime(_allergensKey);
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>?> getAllergens({bool checkExpiry = true, Duration lifetime = const Duration(hours: 24)}) async {
    if (checkExpiry && await isCacheStale(_allergensKey, lifetime: lifetime)) {
      return null;
    }

    final data = await getData(_allergensKey, checkExpiry: false);
    if (data == null) return null;

    return List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item))
    );
  }

  
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

  
  static Future<bool> saveRecipeDetails(Map<String, dynamic> detailsMap) async {
    return saveData(_recipesDetailsKey, detailsMap);
  }

  static Future<Map<String, dynamic>?> getRecipeDetails() async {
    final data = await getData(_recipesDetailsKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  
  static Future<bool> saveMealPlan(Map<String, dynamic> mealPlanData) async {
    return saveData(_mealPlanKey, mealPlanData);
  }

  static Future<Map<String, dynamic>?> getMealPlan() async {
    final data = await getData(_mealPlanKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  
  static Future<bool> saveShoppingList(Map<String, dynamic> shoppingListData) async {
    return saveData(_shoppingListKey, shoppingListData);
  }

  static Future<Map<String, dynamic>?> getShoppingList() async {
    final data = await getData(_shoppingListKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }


  static Future<DateTime?> getLastUpdateTime(String key) async {
    final prefs = await _prefs;
    final timestamp = prefs.getInt('${key}_timestamp');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  static Future<void> saveUpdateTime(String key) async {
    final prefs = await _prefs;
    await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> isCacheStale(String key, {Duration lifetime = const Duration(hours: 24)}) async {
    final lastUpdate = await getLastUpdateTime(key);
    if (lastUpdate == null) {
      return true;
    }
    return DateTime.now().difference(lastUpdate) > lifetime;
  }


}