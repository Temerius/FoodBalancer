// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataRepository = Provider.of<DataRepository>(context);
    final user = dataRepository.user ?? authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/profile/edit').then((_) {
                // Обновляем состояние при возврате с экрана редактирования
                setState(() {});
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isLoading = true;
          });
          try {
            // Обновляем данные профиля с сервера
            await dataRepository.refreshUserData();
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Аватар и имя пользователя
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'П',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'Пользователь',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                user?.email ?? 'email@example.com',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 32),

              // Личная информация
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Личная информация',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildProfileInfoRow(
                          context,
                          'Рост',
                          user?.height != null ? '${user!.height} см' : 'Не указан'
                      ),
                      _buildProfileInfoRow(
                          context,
                          'Вес',
                          user?.weight != null ? '${user!.weight} кг' : 'Не указан'
                      ),
                      _buildProfileInfoRow(
                          context,
                          'Возраст',
                          user?.age != null ? '${user!.age} лет' : 'Не указан'
                      ),
                      _buildProfileInfoRow(
                          context,
                          'Пол',
                          user?.gender?.toDisplayString() ?? 'Не указан'
                      ),
                      _buildProfileInfoRow(
                        context,
                        'ИМТ',
                        user?.bmi != null
                            ? '${user!.bmi!.toStringAsFixed(1)} (${user.bmiCategory})'
                            : 'Не рассчитан',
                      ),
                      _buildProfileInfoRow(
                        context,
                        'Дневная норма калорий',
                        user?.caloriesPerDay != null
                            ? '${user!.caloriesPerDay} ккал'
                            : user?.height != null && user?.weight != null && user?.age != null && user?.gender != null
                            ? '${user!.calculateDailyCalories()} ккал (рекомендуемая)'
                            : 'Не указана',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Аллергии
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Аллергии',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.pushNamed(context, '/profile/allergies').then((_) {
                                setState(() {});
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (user?.allergens.isEmpty ?? true)
                        const Text('Аллергии не указаны')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user!.allergens.map((allergen) {
                            return Chip(
                              label: Text(allergen.name),
                              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Кухонное оборудование
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Кухонное оборудование',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.pushNamed(context, '/profile/equipment').then((_) {
                                setState(() {});
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (user?.equipment.isEmpty ?? true)
                        const Text('Оборудование не указано')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: user!.equipment.length,
                          itemBuilder: (context, index) {
                            final equipment = user.equipment[index];
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.kitchen,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(equipment.displayName),
                              subtitle: Text('${equipment.power} Вт, ${equipment.capacity} л'),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Кнопка выхода
              TextButton.icon(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    await authProvider.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(
      BuildContext context,
      String label,
      String value,
      {bool isLast = false}
      ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}