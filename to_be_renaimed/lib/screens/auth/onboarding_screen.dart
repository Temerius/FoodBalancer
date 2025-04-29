import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/logo_widget.dart';
import '../../config/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Добро пожаловать в CookHelper',
      description: 'Ваш персональный помощник на кухне, который поможет вам готовить вкусно и с удовольствием',
      icon: Icons.restaurant_menu,
    ),
    OnboardingPage(
      title: 'Рецепты на любой вкус',
      description: 'Тысячи рецептов, подобранных специально под ваши предпочтения и имеющиеся продукты',
      icon: Icons.menu_book,
    ),
    OnboardingPage(
      title: 'Управление продуктами',
      description: 'Следите за сроками годности, сканируйте штрих-коды и никогда не выбрасывайте еду',
      icon: Icons.kitchen,
    ),
    OnboardingPage(
      title: 'Планирование питания',
      description: 'Составляйте план питания на неделю, считайте калории и следите за своим здоровьем',
      icon: Icons.calendar_today,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Кнопка пропустить
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    // Очищаем ошибки перед навигацией
                    Provider.of<AuthProvider>(context, listen: false).clearError();
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  child: Text(
                    'Пропустить',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Основной контент
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Индикаторы страниц
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                      (index) => _buildDotIndicator(index),
                ),
              ),
            ),

            // Кнопки навигации
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _currentPage < _pages.length - 1
                  ? CustomButton(
                text: 'Далее',
                onPressed: _nextPage,
              )
                  : Column(
                children: [
                  CustomButton(
                    text: 'Создать аккаунт',
                    onPressed: () {
                      // Очищаем ошибки перед навигацией
                      Provider.of<AuthProvider>(context, listen: false).clearError();
                      Navigator.pushReplacementNamed(context, AppRoutes.register);
                    },
                  ),
                  SizedBox(height: 16),
                  CustomButton(
                    text: 'Уже есть аккаунт?',
                    onPressed: () {
                      // Очищаем ошибки перед навигацией
                      Provider.of<AuthProvider>(context, listen: false).clearError();
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    isOutlined: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            page.icon,
            size: 120,
            color: AppColors.primaryBlue,
          ),
          SizedBox(height: 40),
          Text(
            page.title,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? AppColors.primaryBlue
            : AppColors.paleBlue,
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}