// lib/repositories/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cache_config.dart';

class CacheService {
  static const String _timestamp = '_timestamp';

  // Сохранение данных в кэш
  static Future<bool> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();

    // Выводим текущие данные до изменения
    final currentData = await _getWithoutChecks(key);
    _logCacheOperation('BEFORE SAVE', key, currentData);

    // Сохраняем данные в JSON-формате
    final jsonString = jsonEncode(data);
    final result = await prefs.setString(key, jsonString);

    // Сохраняем временную метку
    await prefs.setInt('$key$_timestamp', DateTime.now().millisecondsSinceEpoch);

    // Выводим данные после изменения
    _logCacheOperation('AFTER SAVE', key, data);

    return result;
  }

  // Получение данных из кэша без проверки срока годности
  static Future<dynamic> _getWithoutChecks(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      return null;
    }

    try {
      return jsonDecode(jsonString);
    } catch (e) {
      print('ERROR: Failed to decode cache for key $key: $e');
      return null;
    }
  }

  // Получение данных из кэша
  static Future<dynamic> get(String key, CacheConfig config) async {
    final prefs = await SharedPreferences.getInstance();

    // Если требуется принудительное обновление
    if (config.forceRefresh) {
      _logCacheOperation('GET (FORCE REFRESH)', key, null);
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
        _logCacheOperation('GET (EXPIRED)', key, null);
        return null;
      }
    }

    // Получаем данные
    final jsonString = prefs.getString(key);
    if (jsonString == null) {
      _logCacheOperation('GET (NOT FOUND)', key, null);
      return null;
    }

    try {
      final data = jsonDecode(jsonString);
      _logCacheOperation('GET (SUCCESS)', key, data);
      return data;
    } catch (e) {
      // Если произошла ошибка при декодировании, удаляем кэш
      await prefs.remove(key);
      _logCacheOperation('GET (DECODE ERROR)', key, null);
      return null;
    }
  }

  // Вывод информации о кэше в удобочитаемом формате
  static void _logCacheOperation(String operation, String key, dynamic data) {
    print('\n======= CACHE $operation: $key =======');

    if (data == null) {
      print('DATA: null');
    } else {
      // Форматируем JSON для удобного чтения
      final formattedJson = _formatJson(data);
      print('DATA: $formattedJson');
    }

    print('===============================================\n');
  }

  // Форматирование JSON для удобного чтения
  static String _formatJson(dynamic data) {
    try {
      if (data is List) {
        // Для списков
        if (data.isEmpty) {
          return '[]';
        }

        if (data.length > 100) {
          // Сокращаем большие списки
          return '[LIST with ${data.length} items. First 3: ${data.take(3).map((item) => _formatItem(item)).join(', ')} ...]';
        }

        return '[${data.map((item) => _formatItem(item)).join(', ')}]';
      } else if (data is Map) {
        // Для объектов
        if (data.isEmpty) {
          return '{}';
        }

        final entries = <String>[];
        for (var entry in data.entries) {
          entries.add('"${entry.key}": ${_formatItem(entry.value)}');
        }

        return '{${entries.join(', ')}}';
      } else {
        // Для примитивных типов
        return data.toString();
      }
    } catch (e) {
      return 'Error formatting JSON: $e';
    }
  }

  // Форматирование отдельного элемента
  static String _formatItem(dynamic item) {
    if (item is String) {
      return '"$item"';
    } else if (item is Map || item is List) {
      // Сокращаем вложенные структуры
      if (item is Map) {
        return '{...}';
      } else {
        return '[...]';
      }
    } else {
      return item.toString();
    }
  }

  // Очистка кэша
  static Future<bool> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();

    // Выводим текущие данные до удаления
    final currentData = await _getWithoutChecks(key);
    _logCacheOperation('BEFORE CLEAR', key, currentData);

    await prefs.remove('$key$_timestamp');
    final result = await prefs.remove(key);

    _logCacheOperation('AFTER CLEAR', key, null);

    return result;
  }

  // Проверка наличия кэша
  static Future<bool> exists(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final exists = prefs.containsKey(key);

    if (exists) {
      final data = await _getWithoutChecks(key);
      _logCacheOperation('EXISTS CHECK (TRUE)', key, data);
    } else {
      _logCacheOperation('EXISTS CHECK (FALSE)', key, null);
    }

    return exists;
  }

  // Вывод списка всех ключей в кэше
  static Future<void> listAllKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    print('\n======= CACHE ALL KEYS =======');
    print('Total keys: ${keys.length}');

    // Отфильтровываем временные метки
    final dataKeys = keys.where((key) => !key.endsWith(_timestamp)).toList();
    print('Data keys (${dataKeys.length}): $dataKeys');

    print('===============================================\n');
  }

  // Вывод полного содержимого кэша
  static Future<void> dumpCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    // Отфильтровываем временные метки
    final dataKeys = keys.where((key) => !key.endsWith(_timestamp)).toList();

    print('\n======= COMPLETE CACHE DUMP =======');
    print('Total keys: ${dataKeys.length}');

    for (var key in dataKeys) {
      final data = await _getWithoutChecks(key);
      print('\n--- KEY: $key ---');
      if (data != null) {
        final formattedJson = _formatJson(data);
        print('CONTENT: $formattedJson');
      } else {
        print('CONTENT: null');
      }
    }

    print('\n===============================================\n');
  }
}