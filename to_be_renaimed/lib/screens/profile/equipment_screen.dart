// lib/screens/profile/equipment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/equipment.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({Key? key}) : super(key: key);

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Equipment> _equipment = [];
  List<int> _selectedEquipmentIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      // Получаем все оборудование из репозитория
      _equipment = await dataRepository.getEquipment(forceRefresh: true);

      // Получаем оборудование текущего пользователя
      final user = dataRepository.user ??
          Provider.of<AuthProvider>(context, listen: false).currentUser;

      if (user != null) {
        _selectedEquipmentIds = List<int>.from(user.equipmentIds);

        // Обновляем статусы выбора в списке оборудования
        for (var equip in _equipment) {
          equip.isSelected = _selectedEquipmentIds.contains(equip.id);
        }
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

  Future<void> _saveEquipment() async {
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

      // Создаем копию пользователя с обновленным оборудованием
      final updatedUser = user.copyWith(
        equipmentIds: _selectedEquipmentIds,
      );

      // Обновляем профиль в репозитории
      final success = await dataRepository.updateUserProfile(updatedUser);

      if (success) {
        // Обновляем кэш оборудования
        await dataRepository.getEquipment(forceRefresh: true);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Оборудование успешно обновлено')),
          );
        }
      } else {
        setState(() {
          _errorMessage = dataRepository.error ?? 'Ошибка обновления оборудования';
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
        title: const Text('Кухонное оборудование'),
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
              'Добавьте оборудование, которое у вас есть на кухне, и мы подберем подходящие рецепты',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          // Список оборудования с индикатором загрузки
          Expanded(
            child: _equipment.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.kitchen_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет доступного оборудования',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _equipment.length,
              itemBuilder: (context, index) {
                final equip = _equipment[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      equip.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Тип: ${equip.type}\nМощность: ${equip.power} Вт, Объем: ${equip.capacity} л',
                    ),
                    value: _selectedEquipmentIds.contains(equip.id),
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() {
                          if (value) {
                            if (!_selectedEquipmentIds.contains(equip.id)) {
                              _selectedEquipmentIds.add(equip.id);
                            }
                          } else {
                            _selectedEquipmentIds.remove(equip.id);
                          }
                        });
                      }
                    },
                    secondary: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.kitchen,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ),

          // Информация о выбранных позициях
          if (_equipment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Выбрано: ${_selectedEquipmentIds.length} из ${_equipment.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

          // Кнопка сохранения
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveEquipment,
                child: const Text('Сохранить'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}