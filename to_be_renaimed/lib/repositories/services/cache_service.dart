// lib/repositories/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cache_config.dart';

class CacheService {
  static const String _timestamp = '_timestamp';
  static const String _lastUpdateKey = 'last_update';
  static const String _expireTimeKey = 'expire_time';

  // Сохранение данных в кэш
  static Future<bool> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      bool result;
      // Сохраняем данные в правильном формате
      if (key == _lastUpdateKey || key.endsWith(_timestamp) || key.endsWith(_expireTimeKey)) {
        // Для временных меток сохраняем как int
        if (data is! int) {
          final intValue = data is String ? int.tryParse(data) ?? 0 : 0;
          result = await prefs.setInt(key, intValue);
        } else {
          result = await prefs.setInt(key, data);
        }
      } else if (data is bool) {
        // Для булевых значений
        result = await prefs.setBool(key, data);
      } else if (data is int) {
        // Для целых чисел
        result = await prefs.setInt(key, data);
      } else if (data is double) {
        // Для чисел с плавающей точкой
        result = await prefs.setDouble(key, data);
      } else if (data is String) {
        // Для строк
        result = await prefs.setString(key, data);
      } else {
        // Для объектов и массивов - сериализуем в JSON
        final jsonString = jsonEncode(data);
        result = await prefs.setString(key, jsonString);
      }

      // Сохраняем временную метку обновления, если это не сама временная метка
      if (key != _lastUpdateKey && !key.endsWith(_timestamp)) {
        await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      }

      return result;
    } catch (e) {
      return false;
    }
  }

  // Безопасное получение данных любого типа из SharedPreferences
  static Future<dynamic> getAnyType(String key) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Check if the key exists
      if (!prefs.containsKey(key)) {
        return null;
      }

      // Try to determine the type based on key naming or try different getters

      // For timestamp and expiry time keys, use getInt
      if (key == _lastUpdateKey || key.endsWith(_timestamp) || key.endsWith(_expireTimeKey)) {
        return prefs.getInt(key);
      }

      // Try as a bool
      if (prefs.containsKey(key)) {
        try {
          final boolValue = prefs.getBool(key);
          if (boolValue != null) {
            return boolValue;
          }
        } catch (_) {
          // Not a bool, try next type
        }
      }

      // Try as an int
      if (prefs.containsKey(key)) {
        try {
          final intValue = prefs.getInt(key);
          if (intValue != null) {
            return intValue;
          }
        } catch (_) {
          // Not an int, try next type
        }
      }

      // Try as a double
      if (prefs.containsKey(key)) {
        try {
          final doubleValue = prefs.getDouble(key);
          if (doubleValue != null) {
            return doubleValue;
          }
        } catch (_) {
          // Not a double, try next type
        }
      }

      // Try as a string and attempt to parse JSON
      if (prefs.containsKey(key)) {
        try {
          final stringValue = prefs.getString(key);
          if (stringValue != null) {
            try {
              // Try to parse as JSON
              return jsonDecode(stringValue);
            } catch (_) {
              // Not valid JSON, return as string
              return stringValue;
            }
          }
        } catch (_) {
          // Failed to get as string
        }
      }

      // If all attempts failed, return null
      return null;
    } catch (e) {
      return null;
    }
  }

  // Получение данных из кэша
  static Future<dynamic> get(String key, CacheConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Если требуется принудительное обновление
      if (config.forceRefresh) {
        return null;
      }

      // Проверяем срок действия кэша
      final timestampKey = '$key$_timestamp';
      int? timestamp;

      try {
        timestamp = prefs.getInt(timestampKey);
      } catch (_) {
        // Игнорируем ошибку
      }

      if (timestamp != null) {
        final lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();

        // Если кэш истек
        if (now.difference(lastUpdate) > config.expireTime) {
          return null;
        }
      }

      // Получаем данные с учетом типа
      final data = await getAnyType(key);

      return data;
    } catch (_) {
      return null;
    }
  }

  // Форматирование JSON для удобного чтения (используется только для DebugCacheScreen)
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

  // Форматирование отдельного элемента (используется только для DebugCacheScreen)
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

    try {
      // Удаление данных и временной метки
      await prefs.remove('$key$_timestamp');
      final result = await prefs.remove(key);

      return result;
    } catch (_) {
      return false;
    }
  }

  // Очистка всего кэша
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (_) {
      return false;
    }
  }

  // Проверка наличия кэша
  static Future<bool> exists(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (_) {
      return false;
    }
  }

  // Вывод полного содержимого кэша
  static Future<void> dumpCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Отфильтровываем временные метки для лучшей читаемости
      final dataKeys = keys.where((key) => !key.endsWith(_timestamp)).toList();

      print('\n======= COMPLETE CACHE DUMP =======');
      print('Total keys: ${dataKeys.length}');

      for (var key in dataKeys) {
        final data = await getAnyType(key);

        print('\n--- KEY: $key ---');
        print('TYPE: ${data?.runtimeType ?? 'null'}');

        if (data != null) {
          final formattedJson = _formatJson(data);
          print('CONTENT: $formattedJson');
        } else {
          print('CONTENT: null');
        }
      }

      print('\n===============================================\n');
    } catch (e) {
      print("ERROR DUMPING CACHE: $e");
    }
  }

  // Вывод списка всех ключей в кэше (используется только для DebugCacheScreen)
  static Future<List<String>> listAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().toList();
    } catch (_) {
      return [];
    }
  }

  // Получение всех данных кэша для отображения на экране отладки
  static Future<Map<String, dynamic>> getAllCacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      Map<String, dynamic> result = {};

      for (var key in keys) {
        final data = await getAnyType(key);
        result[key] = data;
      }

      return result;
    } catch (_) {
      return {};
    }
  }
}