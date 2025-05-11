// lib/screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../repositories/data_repository.dart';
import '../repositories/models/cache_config.dart';
import 'auth/onboarding_screen.dart';
import 'home_layout.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _statusMessage = "Загрузка приложения...";
  double _progress = 0.0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  // В lib/screens/loading_screen.dart
// Обновить метод _initializeApp

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dataRepository = Provider.of<DataRepository>(context, listen: false);

    try {
      // Инициализация аутентификации
      setState(() {
        _statusMessage = "Проверка авторизации...";
        _progress = 0.1;
      });

      await authProvider.initialize();

      setState(() {
        _progress = 0.2;
      });

      if (authProvider.isAuthenticated) {
        // ИСПРАВЛЕНИЕ: Загружаем ВСЕ данные один раз здесь

        setState(() {
          _statusMessage = "Загрузка категорий...";
          _progress = 0.3;
        });

        // 1. Загружаем все категории (один раз)
        await dataRepository.getAllIngredientTypes();

        setState(() {
          _statusMessage = "Загрузка профиля пользователя...";
          _progress = 0.4;
        });

        // 2. Загружаем базовые данные пользователя
        await dataRepository.getUserProfile(forceRefresh: true);

        setState(() {
          _statusMessage = "Загрузка аллергенов...";
          _progress = 0.5;
        });

        // 3. Загружаем аллергены
        await dataRepository.getAllAllergens(forceRefresh: true);

        setState(() {
          _statusMessage = "Загрузка оборудования...";
          _progress = 0.6;
        });

        // 4. Загружаем оборудование
        await dataRepository.getEquipment(forceRefresh: true);

        setState(() {
          _statusMessage = "Загрузка продуктов холодильника...";
          _progress = 0.7;
        });

        // 5. ВАЖНО: Загружаем продукты холодильника
        // Это автоматически обновит:
        // - userRefrigeratorCategories
        // - expiringItems
        await dataRepository.getRefrigeratorItems(forceRefresh: true);

        setState(() {
          _statusMessage = "Загрузка рецептов...";
          _progress = 0.8;
        });

        // 6. Загружаем рецепты
        await dataRepository.getRecipes(forceRefresh: true);

        setState(() {
          _statusMessage = "Загрузка избранных рецептов...";
          _progress = 0.85;
        });

        // 7. Загружаем избранные рецепты
        await dataRepository.getFavoriteRecipes(forceRefresh: true);

        setState(() {
          _statusMessage = "Загрузка статистики...";
          _progress = 0.9;
        });

        // 8. Загружаем статистику
        await dataRepository.getRefrigeratorStats(forceRefresh: true);

        setState(() {
          _statusMessage = "Обновление данных пользователя...";
          _progress = 0.95;
        });

        // 9. Обновляем конкретные данные пользователя
        await dataRepository.refreshUserAllergens();
        await dataRepository.refreshUserEquipment();
      }

      setState(() {
        _progress = 1.0;
        _statusMessage = "Готово!";
      });

      // Небольшая задержка, чтобы пользователь увидел полный прогресс бар
      await Future.delayed(const Duration(milliseconds: 500));

      // Переход на соответствующий экран
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => authProvider.isAuthenticated
              ? const HomeLayout()
              : const OnboardingScreen(),
        ));
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _statusMessage = "Ошибка загрузки";
      });
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _progress = 0.0;
      _statusMessage = "Повторная загрузка...";
    });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Логотип
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),

              // Название приложения
              Text(
                'CookHelper',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                'Ваш умный помощник на кухне',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),

              const Spacer(flex: 1),

              // Индикатор прогресса и статус
              if (!_hasError) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ] else ...[
                // Отображение ошибки
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Произошла ошибка при загрузке данных',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _retry,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(flex: 3),

              // Полоса внизу для информации о версии
              Container(
                width: double.infinity,
                color: Colors.black12,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: const Text(
                  'Версия 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}