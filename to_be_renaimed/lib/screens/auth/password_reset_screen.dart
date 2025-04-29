import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/logo_widget.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      final success = await Provider.of<AuthProvider>(context, listen: false)
          .resetPassword(_emailController.text);

      if (success) {
        // Очищаем ошибки перед сменой состояния
        Provider.of<AuthProvider>(context, listen: false).clearError();
        setState(() {
          _resetSent = true;
        });
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
        title: Text(
          'Восстановление пароля',
          style: TextStyle(
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _resetSent
                ? _buildSuccessView(context)
                : _buildFormView(context, authProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LogoWidget(size: 70),
          SizedBox(height: 32),
          Text(
            'Забыли пароль?',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          SizedBox(height: 8),
          Text(
            'Введите ваш email, и мы отправим вам инструкции по восстановлению пароля.',
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

          // Кнопка отправки
          CustomButton(
            text: 'Отправить инструкции',
            onPressed: _resetPassword,
            isLoading: authProvider.isLoading,
          ),
          SizedBox(height: 24),

          // Ссылка на вход
          TextButton(
            onPressed: () {
              // Очищаем ошибки перед навигацией
              Provider.of<AuthProvider>(context, listen: false).clearError();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            child: Text(
              'Вернуться к входу',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mark_email_read,
          size: 100,
          color: AppColors.primaryBlue,
        ),
        SizedBox(height: 32),
        Text(
          'Инструкции отправлены!',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,  // Добавляем центрирование текста
        ),
        SizedBox(height: 16),
        Text(
          'Мы отправили инструкции по восстановлению пароля на email ${_emailController.text}.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,  // Уже есть, но подтверждаем
        ),
        SizedBox(height: 16),
        Text(
          'Если вы не получили письмо, проверьте папку "Спам" или попробуйте еще раз.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,  // Уже есть, но подтверждаем
        ),
        SizedBox(height: 32),
        CustomButton(
          text: 'Вернуться к входу',
          onPressed: () {
            // Очищаем ошибки перед навигацией
            Provider.of<AuthProvider>(context, listen: false).clearError();
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
        ),
      ],
    );
  }
}