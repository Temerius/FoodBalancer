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

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите ваше имя';
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final height = int.tryParse(value);
                      if (height == null || height <= 0 || height > 300) {
                        return 'Пожалуйста, введите корректное значение роста';
                      }
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final weight = int.tryParse(value);
                      if (weight == null || weight <= 0 || weight > 500) {
                        return 'Пожалуйста, введите корректное значение веса';
                      }
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final age = int.tryParse(value);
                      if (age == null || age <= 0 || age > 120) {
                        return 'Пожалуйста, введите корректное значение возраста';
                      }
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final calories = int.tryParse(value);
                      if (calories == null || calories <= 0 || calories > 10000) {
                        return 'Пожалуйста, введите корректное значение калорий';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Кнопка сохранения
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Create updated user object
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: пользователь не найден')),
        );
        return;
      }

      final updatedUser = User(
        id: currentUser.id,
        name: _nameController.text,
        email: currentUser.email,
        height: _heightController.text.isEmpty ? null : int.tryParse(_heightController.text),
        weight: _weightController.text.isEmpty ? null : int.tryParse(_weightController.text),
        age: _ageController.text.isEmpty ? null : int.tryParse(_ageController.text),
        gender: _gender,
        caloriesPerDay: _caloriesController.text.isEmpty ? null : int.tryParse(_caloriesController.text),
        allergenIds: currentUser.allergenIds,
        equipmentIds: currentUser.equipmentIds,
      );

      // Save profile
      final success = await dataRepository.updateUserProfile(updatedUser);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dataRepository.error ?? 'Ошибка обновления профиля')),
        );
      }
    }
  }
}