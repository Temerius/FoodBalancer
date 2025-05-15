import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_be_renaimed/services/api_service.dart';
import 'package:to_be_renaimed/services/auth_service.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'repositories/data_repository.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  final apiService = ApiService();

  
  await apiService.initialize();

  
  final authService = AuthService(apiService: apiService);
  final authProvider = AuthProvider(authService: authService);
  final dataRepository = DataRepository(apiService: apiService);

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
      home: const LoadingScreen(), 
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}