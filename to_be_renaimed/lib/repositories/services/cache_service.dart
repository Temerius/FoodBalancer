// lib/repositories/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cache_config.dart';

class CacheService {
  static const String _timestamp = '_timestamp';

  // Сохранение данных в кэш
  static Future<bool> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();

    // Сохраняем данные в JSON-формате
    final jsonString = jsonEncode(data);
    final result = await prefs.setString(key, jsonString);

    // Сохраняем временную метку
    await prefs.setInt('$key$_timestamp', DateTime.now().millisecondsSinceEpoch);

    return result;
  }

  // Получение данных из кэша
  static Future<dynamic> get(String key, CacheConfig config) async {
    final prefs = await SharedPreferences.getInstance();

    // Если требуется принудительное обновление
    if (config.forceRefresh) {
      return null;
    }

    // Проверяем срок действия кэша
    final timestampKey = '$key$_timestamp';
    final timestamp = prefs.getInt(timestampKey);

    if (timestamp != null) {
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      // Если кэш истек
      if (now.difference(lastUpdate) > config.expireTime) {
        return null;
      }
    }

    // Получаем данные
    final jsonString = prefs.getString(key);
    if (jsonString == null) {
      return null;
    }

    try {
      return jsonDecode(jsonString);
    } catch (e) {
      // Если произошла ошибка при декодировании, удаляем кэш
      await prefs.remove(key);
      return null;
    }
  }

  // Очистка кэша
  static Future<bool> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$key$_timestamp');
    return await prefs.remove(key);
  }

  // Проверка наличия кэша
  static Future<bool> exists(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }
}