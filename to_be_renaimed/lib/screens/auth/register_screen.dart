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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Для регистрации необходимо согласиться с условиями использования'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      final success = await authProvider.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (success) {
        
        authProvider.clearError();

        
        try {
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Инициализация профиля...'),
                ],
              ),
            ),
          );

          
          await dataRepository.initialize();

          
          await dataRepository.getUserProfile();

          
          await dataRepository.getAllAllergens(forceRefresh: true);

          
          await dataRepository.getEquipment(forceRefresh: true);

          
          if (mounted) {
            Navigator.pop(context);
          }
        } catch (e) {
          
          if (mounted) {
            Navigator.pop(context);
          }

          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при инициализации профиля: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }

        
        Navigator.pushReplacementNamed(context, AppRoutes.home);
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
                  LogoWidget(size: 70),
                  SizedBox(height: 32),
                  Text(
                    'Создание аккаунта',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Создайте аккаунт, чтобы начать пользоваться всеми возможностями приложения.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  
                  CustomTextField(
                    label: 'Имя',
                    controller: _nameController,
                    validator: Validators.validateName,
                    prefixIcon: Icons.person,
                  ),
                  SizedBox(height: 16),

                  
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                  ),
                  SizedBox(height: 16),

                  
                  CustomTextField(
                    label: 'Пароль',
                    controller: _passwordController,
                    validator: Validators.validatePassword,
                    isPassword: true,
                    prefixIcon: Icons.lock,
                  ),
                  SizedBox(height: 16),

                  
                  CustomTextField(
                    label: 'Подтверждение пароля',
                    controller: _confirmPasswordController,
                    validator: (value) => Validators.validatePasswordMatch(
                      value,
                      _passwordController.text,
                    ),
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  SizedBox(height: 24),

                  
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                        activeColor: AppColors.primaryBlue,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreedToTerms = !_agreedToTerms;
                            });
                          },
                          child: Text.rich(
                            TextSpan(
                              text: 'Я принимаю ',
                              style: TextStyle(
                                color: AppColors.textMedium,
                              ),
                              children: [
                                TextSpan(
                                  text: 'условия использования',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: ' и ',
                                ),
                                TextSpan(
                                  text: 'политику конфиденциальности',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  
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

                  
                  CustomButton(
                    text: 'Зарегистрироваться',
                    onPressed: _register,
                    isLoading: authProvider.isLoading,
                  ),
                  SizedBox(height: 24),

                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Уже есть аккаунт? ',
                        style: TextStyle(
                          color: AppColors.textMedium,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          
                          Provider.of<AuthProvider>(context, listen: false).clearError();
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        },
                        child: Text(
                          'Войти',
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