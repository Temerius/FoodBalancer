
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/data_repository.dart';
import '../../repositories/services/cache_service.dart';
import '../../repositories/models/cache_config.dart';

class CacheDebugScreen extends StatefulWidget {
  const CacheDebugScreen({Key? key}) : super(key: key);

  @override
  State<CacheDebugScreen> createState() => _CacheDebugScreenState();
}

class _CacheDebugScreenState extends State<CacheDebugScreen> {
  final TextEditingController _logController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _userCache;
  List<dynamic>? _allergensCache;

  @override
  void initState() {
    super.initState();
    _refreshCacheData();
  }

  @override
  void dispose() {
    _logController.dispose();
    super.dispose();
  }

  
  Future<void> _refreshCacheData() async {
    setState(() {
      _isLoading = true;
      _logController.text = "Загрузка данных кэша...\n";
    });

    try {
      
      _userCache = await CacheService.get('user', CacheConfig.defaultConfig);
      _allergensCache = await CacheService.get('allergens', CacheConfig.defaultConfig);

      
      _appendLog("=== ДАННЫЕ КЭША ===\n");

      if (_userCache != null) {
        _appendLog("ПОЛЬЗОВАТЕЛЬ:\n");
        _appendLog("ID: ${_userCache!['usr_id']}\n");
        _appendLog("Имя: ${_userCache!['usr_name']}\n");
        _appendLog("Email: ${_userCache!['usr_mail']}\n");

        if (_userCache!.containsKey('allergenIds')) {
          _appendLog("Аллергены: ${_userCache!['allergenIds']}\n");
        } else {
          _appendLog("Аллергены: не найдены в кэше пользователя\n");
        }

        if (_userCache!.containsKey('equipmentIds')) {
          _appendLog("Оборудование: ${_userCache!['equipmentIds']}\n");
        }
      } else {
        _appendLog("ПОЛЬЗОВАТЕЛЬ: не найден в кэше\n");
      }

      _appendLog("\nАЛЛЕРГЕНЫ:\n");
      if (_allergensCache != null && _allergensCache!.isNotEmpty) {
        _appendLog("Всего аллергенов: ${_allergensCache!.length}\n");

        for (int i = 0; i < _allergensCache!.length && i < 10; i++) {
          final allergen = _allergensCache![i];
          _appendLog("${i + 1}. ID: ${allergen['alg_id']}, Название: ${allergen['alg_name']}\n");
        }

        if (_allergensCache!.length > 10) {
          _appendLog("... (показаны первые 10 из ${_allergensCache!.length})\n");
        }
      } else {
        _appendLog("Аллергены не найдены в кэше\n");
      }

      
      await _listAllCacheKeys();
    } catch (e) {
      _appendLog("\nОШИБКА: $e\n");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  
  Future<void> _listAllCacheKeys() async {
    try {
      _appendLog("\n=== ВСЕ КЛЮЧИ КЭША ===\n");
      
      await CacheService.listAllKeys();
      _appendLog("Список ключей выведен в консоль\n");
    } catch (e) {
      _appendLog("ОШИБКА ПОЛУЧЕНИЯ КЛЮЧЕЙ: $e\n");
    }
  }

  
  Future<void> _clearCache(String key) async {
    setState(() {
      _isLoading = true;
      _appendLog("\nОчистка кэша '$key'...\n");
    });

    try {
      await CacheService.clear(key);
      _appendLog("Кэш '$key' успешно очищен\n");

      
      await _refreshCacheData();
    } catch (e) {
      _appendLog("ОШИБКА ОЧИСТКИ КЭША: $e\n");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  
  Future<void> _forceRefreshAllData() async {
    setState(() {
      _isLoading = true;
      _appendLog("\nПринудительное обновление всех данных...\n");
    });

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      
      _appendLog("Обновление аллергенов...\n");
      await dataRepository.getAllAllergens(forceRefresh: true);

      
      _appendLog("Обновление данных пользователя...\n");
      await dataRepository.refreshUserData();

      _appendLog("Обновление данных завершено!\n");

      
      await _refreshCacheData();
    } catch (e) {
      _appendLog("ОШИБКА ОБНОВЛЕНИЯ ДАННЫХ: $e\n");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  
  Future<void> _dumpFullCache() async {
    setState(() {
      _isLoading = true;
      _appendLog("\nСоздание полного дампа кэша...\n");
    });

    try {
      await CacheService.dumpCache();
      _appendLog("Полный дамп кэша выведен в консоль\n");
    } catch (e) {
      _appendLog("ОШИБКА ДАМПА КЭША: $e\n");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  
  void _appendLog(String text) {
    setState(() {
      _logController.text += text;
      
      _logController.selection = TextSelection.fromPosition(
        TextPosition(offset: _logController.text.length),
      );
    });
  }

  
  void _clearLog() {
    setState(() {
      _logController.text = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отладка кэша'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshCacheData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Text(
              'Управление кэшем',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),

            
            if (_isLoading)
              LinearProgressIndicator(
                value: null,
                backgroundColor: Colors.grey[200],
              ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Обновить всё'),
                  onPressed: _isLoading ? null : _forceRefreshAllData,
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text('Очистить кэш пользователя'),
                  onPressed: _isLoading ? null : () => _clearCache('user'),
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text('Очистить кэш аллергенов'),
                  onPressed: _isLoading ? null : () => _clearCache('allergens'),
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text('Очистить кэш аллергенов пользователя'),
                  onPressed: _isLoading ? null : () => _clearCache('user_allergen_ids'),
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.list),
                  label: Text('Показать все ключи'),
                  onPressed: _isLoading ? null : _listAllCacheKeys,
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.description),
                  label: Text('Полный дамп кэша'),
                  onPressed: _isLoading ? null : _dumpFullCache,
                ),
              ],
            ),

            SizedBox(height: 16),

            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Журнал отладки',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: _clearLog,
                  tooltip: 'Очистить журнал',
                ),
              ],
            ),
            SizedBox(height: 8),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(8),
                child: TextField(
                  controller: _logController,
                  readOnly: true,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}