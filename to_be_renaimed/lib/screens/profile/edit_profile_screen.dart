// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/enums.dart';
import '../../models/user.dart';
import '../../repositories/data_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;
  late TextEditingController _caloriesController;
  Gender? _gender;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<DataRepository>(context, listen: false).user ??
        Provider.of<AuthProvider>(context, listen: false).currentUser;

    _nameController = TextEditingController(text: user?.name);
    _heightController = TextEditingController(text: user?.height?.toString() ?? '');
    _weightController = TextEditingController(text: user?.weight?.toString() ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _caloriesController = TextEditingController(text: user?.caloriesPerDay?.toString() ?? '');
    _gender = user?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    // Проверка обязательного поля
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Имя пользователя обязательно для заполнения';
      });
      return false;
    }

    // Проверка роста
    if (_heightController.text.isNotEmpty) {
      final height = int.tryParse(_heightController.text);
      if (height == null || height <= 0 || height > 300) {
        setState(() {
          _errorMessage = 'Пожалуйста, введите корректное значение роста (1-300 см)';
        });
        return false;
      }
    }

    // Проверка веса
    if (_weightController.text.isNotEmpty) {
      final weight = int.tryParse(_weightController.text);
      if (weight == null || weight <= 0 || weight > 500) {
        setState(() {
          _errorMessage = 'Пожалуйста, введите корректное значение веса (1-500 кг)';
        });
        return false;
      }
    }

    // Проверка возраста
    if (_ageController.text.isNotEmpty) {
      final age = int.tryParse(_ageController.text);
      if (age == null || age <= 0 || age > 120) {
        setState(() {
          _errorMessage = 'Пожалуйста, введите корректное значение возраста (1-120 лет)';
        });
        return false;
      }
    }

    // Проверка калорий
    if (_caloriesController.text.isNotEmpty) {
      final calories = int.tryParse(_caloriesController.text);
      if (calories == null || calories <= 0 || calories > 10000) {
        setState(() {
          _errorMessage = 'Пожалуйста, введите корректное значение калорий (1-10000 ккал)';
        });
        return false;
      }
    }

    // Если все проверки пройдены, очищаем сообщение об ошибке
    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  Future<void> _saveProfile() async {
    // Скрываем клавиатуру
    FocusScope.of(context).unfocus();

    if (!_validateFields()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Получаем текущего пользователя из репозитория
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final currentUser = dataRepository.user ??
          Provider.of<AuthProvider>(context, listen: false).currentUser;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Ошибка: пользователь не найден';
          _isLoading = false;
        });
        return;
      }

      // Создаем обновленный объект пользователя
      final updatedUser = User(
        id: currentUser.id,
        name: _nameController.text.trim(),
        email: currentUser.email,
        height: _heightController.text.isEmpty ? null : int.tryParse(_heightController.text),
        weight: _weightController.text.isEmpty ? null : int.tryParse(_weightController.text),
        age: _ageController.text.isEmpty ? null : int.tryParse(_ageController.text),
        gender: _gender,
        caloriesPerDay: _caloriesController.text.isEmpty ? null : int.tryParse(_caloriesController.text),
        allergenIds: currentUser.allergenIds,
        equipmentIds: currentUser.equipmentIds,
      );

      // Сохраняем профиль в репозитории
      final success = await dataRepository.updateUserProfile(updatedUser);

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Профиль успешно обновлен')),
          );
        }
      } else {
        setState(() {
          _errorMessage = dataRepository.error ?? 'Ошибка обновления профиля';
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
        title: const Text('Редактирование профиля'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Сообщение об ошибке (если есть)
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],

                Text(
                  'Основная информация',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // Имя пользователя
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    prefixIcon: Icon(Icons.person),
                    helperText: 'Обязательное поле',
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Физические параметры',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // Рост
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Рост (см)',
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Вес
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Вес (кг)',
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Возраст
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Возраст (лет)',
                    prefixIcon: Icon(Icons.date_range),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Пол
                Text('Пол', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<Gender>(
                        title: const Text('Мужской'),
                        value: Gender.male,
                        groupValue: _gender,
                        onChanged: (Gender? value) {
                          if (value != null) {
                            setState(() {
                              _gender = value;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<Gender>(
                        title: const Text('Женский'),
                        value: Gender.female,
                        groupValue: _gender,
                        onChanged: (Gender? value) {
                          if (value != null) {
                            setState(() {
                              _gender = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Дневная норма калорий
                TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Дневная норма калорий',
                    prefixIcon: Icon(Icons.local_fire_department),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 24),

                // Кнопка автоматического расчета калорий
                if (_heightController.text.isNotEmpty &&
                    _weightController.text.isNotEmpty &&
                    _ageController.text.isNotEmpty &&
                    _gender != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final height = int.tryParse(_heightController.text) ?? 0;
                        final weight = int.tryParse(_weightController.text) ?? 0;
                        final age = int.tryParse(_ageController.text) ?? 0;

                        if (height > 0 && weight > 0 && age > 0) {
                          // Создаем временный объект пользователя для расчета
                          final tempUser = User(
                            id: 0,
                            name: 'temp',
                            email: 'temp',
                            height: height,
                            weight: weight,
                            age: age,
                            gender: _gender,
                          );

                          // Рассчитываем калории и обновляем контроллер
                          final calories = tempUser.calculateDailyCalories();
                          setState(() {
                            _caloriesController.text = calories.toString();
                          });
                        }
                      },
                      icon: const Icon(Icons.calculate),
                      label: const Text('Рассчитать калории'),
                    ),
                  ),

                // Кнопка сохранения
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Сохранить'),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}