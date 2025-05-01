import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'repositories/data_repository.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create providers without initialization
  final authProvider = AuthProvider();
  final dataRepository = DataRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: dataRepository),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CookHelper',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const LoadingScreen(), // Используем экран загрузки как начальный
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}