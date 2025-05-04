// lib/screens/profile/allergies_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/allergen.dart';

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

      // Если аллергенов нет в репозитории, пробуем их загрузить
      if (dataRepository.allergens.isEmpty) {
        // Здесь нужно вызвать метод для загрузки аллергенов
        await dataRepository.refreshAllData();
      }

      // Получаем все аллергены из репозитория
      _allergens = List.from(dataRepository.allergens);

      // Если аллергенов всё еще нет, создаём тестовые данные
      if (_allergens.isEmpty) {
        _allergens = [
          Allergen(id: 1, name: 'Глютен'),
          Allergen(id: 2, name: 'Лактоза'),
          Allergen(id: 3, name: 'Яйца'),
          Allergen(id: 4, name: 'Орехи'),
          Allergen(id: 5, name: 'Арахис'),
          Allergen(id: 6, name: 'Соя'),
          Allergen(id: 7, name: 'Рыба'),
          Allergen(id: 8, name: 'Морепродукты'),
          Allergen(id: 9, name: 'Цитрусовые'),
        ];
      }

      // Получаем выбранные аллергены текущего пользователя
      final user = dataRepository.user ??
          Provider.of<AuthProvider>(context, listen: false).currentUser;

      if (user != null) {
        _selectedAllergenIds = Set<int>.from(user.allergenIds);
      }
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

      // Создаем копию пользователя с обновленными аллергенами
      final updatedUser = user.copyWith(
        allergenIds: _selectedAllergenIds.toList(),
      );

      // Обновляем профиль в репозитории
      final success = await dataRepository.updateUserProfile(updatedUser);

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Аллергии успешно обновлены')),
          );
        }
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
          // Добавим кнопку обновления для случаев, когда данные не загрузились
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
          // Сообщение об ошибке (если есть)
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

          // Список всех аллергенов
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

          // Информация о выбранных аллергенах
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

          // Кнопка сохранения
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