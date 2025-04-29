import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/home_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Создаем и инициализируем AuthProvider
  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'CookHelper',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: authProvider.isAuthenticated ? const HomeLayout() : const OnboardingScreen(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}