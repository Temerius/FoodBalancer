// lib/config/routes.dart - Update to add debug routes
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/password_reset_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home_layout.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/allergies_screen.dart';
import '../screens/profile/equipment_screen.dart';
import '../screens/recipes/recipes_screen.dart';
import '../screens/recipes/recipe_detail_screen.dart';
import '../screens/recipes/favorites_screen.dart';
import '../screens/refrigerator/refrigerator_screen.dart';
import '../screens/refrigerator/add_product_screen.dart';
import '../screens/refrigerator/barcode_scanner_screen.dart';
import '../screens/shopping/shopping_list_screen.dart';
import '../screens/shopping/add_to_shopping_list_screen.dart';
import '../screens/meal_plan/weakly_plan_screen.dart';
import '../screens/meal_plan/daily_plan_screen.dart';
import '../screens/meal_plan/generate_plan_screen.dart';
import '../screens/debug/cache_debug_screen.dart';  // Добавляем импорт отладочного экрана

class AppRoutes {
  static const String onboarding = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String passwordReset = '/password-reset';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String allergies = '/profile/allergies';
  static const String equipment = '/profile/equipment';
  static const String recipes = '/recipes';
  static const String recipeDetail = '/recipes/detail';
  static const String favorites = '/recipes/favorites';
  static const String refrigerator = '/refrigerator';
  static const String addProduct = '/refrigerator/add-product';
  static const String barcodeScanner = '/refrigerator/barcode-scanner';
  static const String shoppingList = '/shopping-list';
  static const String addToShoppingList = '/shopping-list/add';
  static const String weeklyPlan = '/meal-plan/weekly';
  static const String dailyPlan = '/meal-plan/daily';
  static const String generatePlan = '/meal-plan/generate';
  static const String debugCache = '/debug/cache';  // Добавляем маршрут для отладки кэша

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case passwordReset:
        return MaterialPageRoute(builder: (_) => const PasswordResetScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeLayout());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case allergies:
        return MaterialPageRoute(builder: (_) => const AllergiesScreen());
      case equipment:
        return MaterialPageRoute(builder: (_) => const EquipmentScreen());
      case recipes:
        return MaterialPageRoute(builder: (_) => const RecipesScreen());
      case recipeDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: args?['recipeId']));
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case refrigerator:
        return MaterialPageRoute(builder: (_) => const RefrigeratorScreen());
      case addProduct:
        return MaterialPageRoute(builder: (_) => const AddProductScreen());
      case barcodeScanner:
        return MaterialPageRoute(builder: (_) => const BarcodeScannerScreen());
      case shoppingList:
        return MaterialPageRoute(builder: (_) => const ShoppingListScreen());
      case addToShoppingList:
        return MaterialPageRoute(builder: (_) => const AddToShoppingListScreen());
      case weeklyPlan:
        return MaterialPageRoute(builder: (_) => const WeeklyPlanScreen());
      case dailyPlan:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => DailyPlanScreen(date: args?['date']));
      case generatePlan:
        return MaterialPageRoute(builder: (_) => const GeneratePlanScreen());
      case debugCache:  // Добавляем маршрут к отладочному экрану
        return MaterialPageRoute(builder: (_) => const CacheDebugScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Маршрут не найден: ${settings.name}'),
            ),
          ),
        );
    }
  }
}