// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/data_repository.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/logo_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      final success = await authProvider.login(
          _emailController.text,
          _passwordController.text,
          rememberMe: _rememberMe
      );

      if (success) {
        // Очищаем ошибки перед навигацией
        authProvider.clearError();

        // После успешного входа инициализируем данные пользователя
        try {
          // Показываем индикатор загрузки
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка данных...'),
                ],
              ),
            ),
          );

          // Инициализируем репозитории
          await dataRepository.initialize();

          // Загружаем профиль пользователя
          await dataRepository.getUserProfile();

          // Загружаем полный список аллергенов
          await dataRepository.getAllAllergens(forceRefresh: true);

          // Загружаем полный список оборудования
          await dataRepository.getEquipment(forceRefresh: true);

          // Обновляем аллергены пользователя
          await dataRepository.refreshUserAllergens();

          // Закрываем диалог с индикатором загрузки
          if (mounted) {
            Navigator.pop(context);
          }
        } catch (e) {
          // Закрываем диалог с индикатором загрузки в случае ошибки
          if (mounted) {
            Navigator.pop(context);
          }

          // Показываем сообщение об ошибке
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при загрузке данных: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Переходим на главный экран
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.textDark,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LogoWidget(size: 80),
                  SizedBox(height: 48),
                  Text(
                    'Вход в аккаунт',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Добро пожаловать обратно! Пожалуйста, войдите в свой аккаунт.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Email поле
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                  ),
                  SizedBox(height: 16),

                  // Пароль поле
                  CustomTextField(
                    label: 'Пароль',
                    controller: _passwordController,
                    validator: Validators.validatePassword,
                    isPassword: true,
                    prefixIcon: Icons.lock,
                  ),
                  SizedBox(height: 16),

                  // Опция "Запомнить меня" и "Забыли пароль"
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: AppColors.primaryBlue,
                          ),
                          Text(
                            'Запомнить меня',
                            style: TextStyle(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.passwordReset);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(10, 10),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Забыли пароль?',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Сообщение об ошибке
                  if (authProvider.error != null) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authProvider.error!,
                              style: TextStyle(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Кнопка входа
                  CustomButton(
                    text: 'Войти',
                    onPressed: _login,
                    isLoading: authProvider.isLoading,
                  ),
                  SizedBox(height: 24),

                  // Ссылка на регистрацию
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Еще нет аккаунта? ',
                        style: TextStyle(
                          color: AppColors.textMedium,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Очищаем ошибки перед навигацией
                          Provider.of<AuthProvider>(context, listen: false).clearError();
                          Navigator.pushReplacementNamed(context, AppRoutes.register);
                        },
                        child: Text(
                          'Зарегистрироваться',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}