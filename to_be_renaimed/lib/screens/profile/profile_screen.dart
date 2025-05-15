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
  bool _isManuallyRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Легкая синхронизация данных при создании экрана (не делаем тяжелых запросов)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncData();
    });
  }

  // Легкая синхронизация - только локальные данные, без запросов к серверу
  void _syncData() {
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    // Этот метод синхронизирует только локальные данные без обращения к серверу
    dataRepository.refreshUserData();
  }

  // Полное обновление данных с сервера
  Future<void> _refreshData() async {
    setState(() {
      _isManuallyRefreshing = true;
    });

    try {
      // Обновляем данные через репозиторий с форсированной загрузкой с сервера
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      // Загружаем профиль пользователя с сервера
      await dataRepository.getUserProfile(forceRefresh: true);

      // Обновляем аллергены и оборудование
      await dataRepository.refreshUserAllergens();
      await dataRepository.refreshUserEquipment();

      // Показываем успешное обновление
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные успешно обновлены'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Показываем ошибку
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления данных: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isManuallyRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataRepository = Provider.of<DataRepository>(context);
    final user = dataRepository.user ?? authProvider.currentUser;

    final bool isLoading = dataRepository.isLoading ||
        dataRepository.isLoadingProfile ||
        _isManuallyRefreshing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/profile/edit').then((_) {
                // После редактирования только синхронизируем локальные данные
                _syncData();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Индикатор загрузки, если идёт обновление профиля
              if (isLoading)
                const LinearProgressIndicator(),

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
                          Row(
                            children: [
                              if (dataRepository.isLoadingAllergens)
                                Container(
                                  width: 16,
                                  height: 16,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(context, '/profile/allergies');
                                  if (result == true && mounted) {
                                    // После редактирования только синхронизируем локальные данные
                                    _syncData();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Отображение аллергенов пользователя
                      _buildAllergensSection(context, user, dataRepository),
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
                          Row(
                            children: [
                              if (dataRepository.isLoadingEquipment)
                                Container(
                                  width: 16,
                                  height: 16,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/profile/equipment').then((_) {
                                    // После редактирования только синхронизируем локальные данные
                                    _syncData();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildEquipmentSection(context, user, dataRepository),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Кнопка выхода
              TextButton.icon(
                onPressed: () async {
                  setState(() {
                    _isManuallyRefreshing = true;
                  });
                  try {
                    await authProvider.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  } finally {
                    setState(() {
                      _isManuallyRefreshing = false;
                    });
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(color: Colors.red),
                ),
              ),

              // Отладочный блок
              // const SizedBox(height: 8),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              //   color: Colors.grey[200],
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Text(
              //         'Отладка',
              //         style: TextStyle(
              //           fontSize: 12,
              //           color: Colors.grey[600],
              //         ),
              //       ),
              //       const SizedBox(width: 8),
              //       Icon(Icons.bug_report, size: 14, color: Colors.grey[600]),
              //       Expanded(
              //         child: GestureDetector(
              //           onTap: () {
              //             Navigator.pushNamed(context, '/debug/cache');
              //           },
              //           child: Container(
              //             alignment: Alignment.center,
              //             padding: const EdgeInsets.symmetric(vertical: 4.0),
              //             child: Text(
              //               'Просмотр кэша',
              //               style: TextStyle(
              //                 fontSize: 12,
              //                 color: Theme.of(context).colorScheme.primary,
              //                 decoration: TextDecoration.underline,
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // Виджет для отображения аллергенов
  Widget _buildAllergensSection(BuildContext context, User? user, DataRepository dataRepository) {
    // Получаем все аллергены из репозитория
    final allAllergens = dataRepository.allergens;

    // Получаем ID аллергенов пользователя
    final userAllergenIds = user?.allergenIds ?? [];

    // Если у пользователя нет аллергенов или список аллергенов пуст
    if (userAllergenIds.isEmpty) {
      return const Text('Аллергии не указаны');
    }

    // Находим аллергены пользователя по ID
    final userAllergens = allAllergens.where(
            (allergen) => userAllergenIds.contains(allergen.id)
    ).toList();

    // Если у пользователя нет аллергенов после фильтрации
    if (userAllergens.isEmpty) {
      return const Text('Аллергии не указаны (проверьте настройки)');
    }

    // Отображаем аллергены
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: userAllergens.map((allergen) {
        return Chip(
          label: Text(allergen.name),
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        );
      }).toList(),
    );
  }

  // Виджет для отображения оборудования
  Widget _buildEquipmentSection(BuildContext context, User? user, DataRepository dataRepository) {
    final allEquipment = dataRepository.equipment;
    final userEquipmentIds = user?.equipmentIds ?? [];

    if (userEquipmentIds.isEmpty) {
      return const Text('Оборудование не указано');
    }

    final userEquipment = allEquipment.where(
            (item) => userEquipmentIds.contains(item.id)
    ).toList();

    if (userEquipment.isEmpty) {
      return const Text('Оборудование не указано (проверьте настройки)');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userEquipment.length,
      itemBuilder: (context, index) {
        final equipment = userEquipment[index];
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