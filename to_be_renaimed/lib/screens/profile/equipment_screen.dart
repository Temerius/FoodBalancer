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
  List<int> _userEquipmentIds = [];

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
      _equipment = dataRepository.equipment;

      // Получаем оборудование текущего пользователя
      final user = dataRepository.user ??
          Provider.of<AuthProvider>(context, listen: false).currentUser;

      if (user != null) {
        _userEquipmentIds = List<int>.from(user.equipmentIds);

        // Обновляем статусы выбора в списке оборудования
        for (var equip in _equipment) {
          equip.isSelected = _userEquipmentIds.contains(equip.id);
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
        equipmentIds: _userEquipmentIds,
      );

      // Обновляем профиль в репозитории
      final success = await dataRepository.updateUserProfile(updatedUser);

      if (success) {
        if (mounted) {
          Navigator.pop(context);
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
                    value: equip.isSelected,
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() {
                          equip.isSelected = value;

                          if (value) {
                            if (!_userEquipmentIds.contains(equip.id)) {
                              _userEquipmentIds.add(equip.id);
                            }
                          } else {
                            _userEquipmentIds.remove(equip.id);
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
                'Выбрано: ${_userEquipmentIds.length} из ${_equipment.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

          // Кнопка добавления нового оборудования
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: OutlinedButton.icon(
              onPressed: () {
                _showAddEquipmentDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить свое оборудование'),
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

  void _showAddEquipmentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final powerController = TextEditingController(text: '800');
    final capacityController = TextEditingController(text: '5');
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Добавить оборудование'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Сообщение об ошибке (если есть)
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        helperText: 'Обязательное поле',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(
                        labelText: 'Тип',
                        helperText: 'Например: Плита, Микроволновка и т.д.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: powerController,
                      decoration: const InputDecoration(labelText: 'Мощность (Вт)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: capacityController,
                      decoration: const InputDecoration(labelText: 'Объем (л)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    // Валидация
                    if (nameController.text.isEmpty) {
                      setDialogState(() {
                        errorMessage = 'Пожалуйста, введите название оборудования';
                      });
                      return;
                    }

                    final power = int.tryParse(powerController.text) ?? 0;
                    final capacity = int.tryParse(capacityController.text) ?? 0;

                    if (power < 0 || power > 10000) {
                      setDialogState(() {
                        errorMessage = 'Мощность должна быть в диапазоне 0-10000 Вт';
                      });
                      return;
                    }

                    if (capacity < 0 || capacity > 1000) {
                      setDialogState(() {
                        errorMessage = 'Объем должен быть в диапазоне 0-1000 л';
                      });
                      return;
                    }

                    // Создаем новое оборудование
                    final dataRepository = Provider.of<DataRepository>(context, listen: false);
                    final maxId = _equipment.isEmpty ? 0 : _equipment.map((e) => e.id).reduce((a, b) => a > b ? a : b);

                    final newEquipment = Equipment(
                      id: maxId + 1, // Временный ID (должен быть заменен сервером)
                      type: typeController.text.isNotEmpty ? typeController.text : 'Не указан',
                      power: power,
                      capacity: capacity,
                      customName: nameController.text,
                      isSelected: true, // Автоматически выбираем новое оборудование
                    );

                    setState(() {
                      _equipment.add(newEquipment);
                      _userEquipmentIds.add(newEquipment.id);
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Оборудование добавлено')),
                    );
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          }
      ),
    );
  }
}