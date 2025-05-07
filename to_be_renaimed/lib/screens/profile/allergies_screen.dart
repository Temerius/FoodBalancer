// lib/screens/profile/allergies_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/allergen.dart';
import '../../repositories/models/cache_config.dart';

class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({Key? key}) : super(key: key);

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Allergen> _allergens = [];
  Set<int> _selectedAllergenIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      _allergens = await dataRepository.getAllAllergens(forceRefresh: true);

      // Получаем выбранные аллергены пользователя
      final user = dataRepository.user ??
          Provider.of<AuthProvider>(context, listen: false).currentUser;

      if (user != null) {
        _selectedAllergenIds = Set<int>.from(user.allergenIds);

        // Установка флажков "выбрано" для аллергенов
        for (var allergen in _allergens) {
          allergen.isSelected = _selectedAllergenIds.contains(allergen.id);
        }
      }

      // Если аллергены не загрузились, попробуем загрузить из кэша
      if (_allergens.isEmpty) {
        print("WARNING: Allergies list is empty, trying to load from cache");
        _allergens = await dataRepository.getAllAllergens(forceRefresh: false);

        for (var allergen in _allergens) {
          allergen.isSelected = _selectedAllergenIds.contains(allergen.id);
        }
      }

      // Отладочная информация
      print("Loaded ${_allergens.length} allergens");
      print("User has ${_selectedAllergenIds.length} selected allergens");

    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки данных: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAllergens() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final user = dataRepository.user ??
          Provider.of<AuthProvider>(context, listen: false).currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = 'Ошибка: пользователь не найден';
        });
        return;
      }

      // Создаем обновленного пользователя с новыми ID аллергенов
      final updatedUser = user.copyWith(
        allergenIds: _selectedAllergenIds.toList(),
      );

      // Обновляем профиль
      final success = await dataRepository.updateUserProfile(updatedUser);

      if (success) {
        // Обновляем кэш аллергенов
        await dataRepository.refreshUserAllergens();

        // Возвращаемся на предыдущий экран с сигналом успеха
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = dataRepository.error ?? 'Ошибка обновления аллергий';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аллергии'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Выберите продукты, на которые у вас аллергия, и мы исключим их из рекомендаций',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          // Индикатор количества аллергенов
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Всего аллергенов: ${_allergens.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'Выбрано: ${_selectedAllergenIds.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),

          Expanded(
            child: _allergens.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Нет доступных аллергенов',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: Icon(Icons.refresh),
                    label: Text('Обновить'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _allergens.length,
              itemBuilder: (context, index) {
                final allergen = _allergens[index];
                return CheckboxListTile(
                  title: Text(allergen.name),
                  value: _selectedAllergenIds.contains(allergen.id),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedAllergenIds.add(allergen.id);
                      } else {
                        _selectedAllergenIds.remove(allergen.id);
                      }
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            child: Text(
              'Выбрано: ${_selectedAllergenIds.length} из ${_allergens.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _saveAllergens,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Сохранить',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}