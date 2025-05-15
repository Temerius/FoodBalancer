
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cache_config.dart';

class CacheService {
  static const String _timestamp = '_timestamp';
  static const String _lastUpdateKey = 'last_update';
  static const String _expireTimeKey = 'expire_time';

  
  static Future<bool> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      bool result;
      
      if (key == _lastUpdateKey || key.endsWith(_timestamp) || key.endsWith(_expireTimeKey)) {
        
        if (data is! int) {
          final intValue = data is String ? int.tryParse(data) ?? 0 : 0;
          result = await prefs.setInt(key, intValue);
        } else {
          result = await prefs.setInt(key, data);
        }
      } else if (data is bool) {
        
        result = await prefs.setBool(key, data);
      } else if (data is int) {
        
        result = await prefs.setInt(key, data);
      } else if (data is double) {
        
        result = await prefs.setDouble(key, data);
      } else if (data is String) {
        
        result = await prefs.setString(key, data);
      } else {
        
        final jsonString = jsonEncode(data);
        result = await prefs.setString(key, jsonString);
      }

      
      if (key != _lastUpdateKey && !key.endsWith(_timestamp)) {
        await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      }

      return result;
    } catch (e) {
      return false;
    }
  }

  
  static Future<dynamic> getAnyType(String key) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      
      if (!prefs.containsKey(key)) {
        return null;
      }

      

      
      if (key == _lastUpdateKey || key.endsWith(_timestamp) || key.endsWith(_expireTimeKey)) {
        return prefs.getInt(key);
      }

      
      if (prefs.containsKey(key)) {
        try {
          final boolValue = prefs.getBool(key);
          if (boolValue != null) {
            return boolValue;
          }
        } catch (_) {
          
        }
      }

      
      if (prefs.containsKey(key)) {
        try {
          final intValue = prefs.getInt(key);
          if (intValue != null) {
            return intValue;
          }
        } catch (_) {
          
        }
      }

      
      if (prefs.containsKey(key)) {
        try {
          final doubleValue = prefs.getDouble(key);
          if (doubleValue != null) {
            return doubleValue;
          }
        } catch (_) {
          
        }
      }

      
      if (prefs.containsKey(key)) {
        try {
          final stringValue = prefs.getString(key);
          if (stringValue != null) {
            try {
              
              return jsonDecode(stringValue);
            } catch (_) {
              
              return stringValue;
            }
          }
        } catch (_) {
          
        }
      }

      
      return null;
    } catch (e) {
      return null;
    }
  }

  
  static Future<dynamic> get(String key, CacheConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      
      if (config.forceRefresh) {
        return null;
      }

      
      final timestampKey = '$key$_timestamp';
      int? timestamp;

      try {
        timestamp = prefs.getInt(timestampKey);
      } catch (_) {
        
      }

      if (timestamp != null) {
        final lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();

        
        if (now.difference(lastUpdate) > config.expireTime) {
          return null;
        }
      }

      
      final data = await getAnyType(key);

      return data;
    } catch (_) {
      return null;
    }
  }

  
  static String _formatJson(dynamic data) {
    try {
      if (data is List) {
        
        if (data.isEmpty) {
          return '[]';
        }

        if (data.length > 100) {
          
          return '[LIST with ${data.length} items. First 3: ${data.take(3).map((item) => _formatItem(item)).join(', ')} ...]';
        }

        return '[${data.map((item) => _formatItem(item)).join(', ')}]';
      } else if (data is Map) {
        
        if (data.isEmpty) {
          return '{}';
        }

        final entries = <String>[];
        for (var entry in data.entries) {
          entries.add('"${entry.key}": ${_formatItem(entry.value)}');
        }

        return '{${entries.join(', ')}}';
      } else {
        
        return data.toString();
      }
    } catch (e) {
      return 'Error formatting JSON: $e';
    }
  }

  
  static String _formatItem(dynamic item) {
    if (item is String) {
      return '"$item"';
    } else if (item is Map || item is List) {
      
      if (item is Map) {
        return '{...}';
      } else {
        return '[...]';
      }
    } else {
      return item.toString();
    }
  }

  
  static Future<bool> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      
      await prefs.remove('$key$_timestamp');
      final result = await prefs.remove(key);

      return result;
    } catch (_) {
      return false;
    }
  }

  
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (_) {
      return false;
    }
  }

  
  static Future<bool> exists(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (_) {
      return false;
    }
  }

  
  static Future<void> dumpCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      
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

  
  static Future<List<String>> listAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().toList();
    } catch (_) {
      return [];
    }
  }

  
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