import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/profile/edit');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                        user?.gender != null
                            ? user!.gender == 'male' ? 'Мужской' : 'Женский'
                            : 'Не указан'
                    ),
                    _buildProfileInfoRow(
                      context,
                      'Дневная норма калорий',
                      user?.caloriesPerDay != null ? '${user!.caloriesPerDay} ккал' : 'Не указана',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Меню профиля
            _buildProfileMenuItem(
              context,
              'Редактировать профиль',
              Icons.edit,
                  () => Navigator.pushNamed(context, '/profile/edit'),
            ),

            _buildProfileMenuItem(
              context,
              'Управление аллергиями',
              Icons.health_and_safety,
                  () => Navigator.pushNamed(context, '/profile/allergies'),
            ),

            _buildProfileMenuItem(
              context,
              'Управление оборудованием',
              Icons.kitchen,
                  () => Navigator.pushNamed(context, '/profile/equipment'),
            ),

            const SizedBox(height: 24),

            // Кнопка выхода
            TextButton.icon(
              onPressed: () {
                authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
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

  Widget _buildProfileMenuItem(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}