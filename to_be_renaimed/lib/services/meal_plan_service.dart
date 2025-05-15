// lib/services/meal_plan_service.dart
import 'dart:math';
import '../models/recipe.dart';
import '../utils/date_formatter.dart';

class MealPlanService {
  // Синглтон для единого доступа по всему приложению
  static final MealPlanService _instance = MealPlanService._internal();
  factory MealPlanService() => _instance;
  MealPlanService._internal();

  // Информация о приемах пищи для текущей недели (ключ - дата в формате yyyy-MM-dd)
  final Map<String, Map<String, dynamic>> _mealPlanData = {};

  // Геттер для получения всех данных
  Map<String, Map<String, dynamic>> get allMealPlans => _mealPlanData;

  // Список всех рецептов (будет заполнен из репозитория)
  List<Recipe> _allRecipes = [];

  // Флаг инициализации
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Инициализация планов питания с рецептами из репозитория
  Future<void> initializeWithRecipes(List<Recipe> recipes) async {
    if (_isInitialized) return;

    _allRecipes = recipes;

    // Определяем текущую неделю (начиная с понедельника)
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    // Создаем планы на две недели (текущую и следующую)
    final weekDays = List.generate(
      14, // 2 недели
          (index) => weekStart.add(Duration(days: index)),
    );

    // Инициализируем данные для каждого дня
    for (final day in weekDays) {
      final dateString = DateFormatter.formatDateISO(day);
      _initMealPlanForDay(dateString);
    }

    _isInitialized = true;
  }

  // Получение даты начала недели (понедельник)
  DateTime _getWeekStart(DateTime date) {
    final weekDay = date.weekday;
    return date.subtract(Duration(days: weekDay - 1));
  }

  // Получение случайного рецепта из списка
  Recipe _getRandomRecipe() {
    if (_allRecipes.isEmpty) {
      // Если нет рецептов, создаем заглушку
      return Recipe(
        id: 0,
        title: 'Нет данных о рецепте',
        description: 'Нет описания',
        calories: 0,
        portionCount: 1,
      );
    }

    final random = Random();
    return _allRecipes[random.nextInt(_allRecipes.length)];
  }

  // Получение списка случайных рецептов
  List<Map<String, dynamic>> _getRandomRecipes(int count) {
    final List<Map<String, dynamic>> recipes = [];
    final recipesSet = <int>{};  // Множество для отслеживания выбранных ID

    for (int i = 0; i < count; i++) {
      // Выбираем случайный рецепт, который еще не был выбран
      Recipe recipe;
      int attempts = 0;

      do {
        recipe = _getRandomRecipe();
        attempts++;
        // Если после 5 попыток не удалось найти уникальный рецепт, выходим из цикла
        if (attempts > 5) break;
      } while (recipesSet.contains(recipe.id) && recipe.id != 0);

      // Если это не заглушка, добавляем ID в множество
      if (recipe.id != 0) {
        recipesSet.add(recipe.id);
      }

      recipes.add({
        'id': recipe.id,
        'name': recipe.title,
        'calories': recipe.calories,
      });
    }

    return recipes;
  }

  // Инициализация данных о приемах пищи для конкретного дня
  void _initMealPlanForDay(String dateString) {
    // Формируем случайные приемы пищи для каждого дня
    final breakfastRecipes = _getRandomRecipes(2);
    final lunchRecipes = _getRandomRecipes(2);
    final dinnerRecipes = _getRandomRecipes(2);

    // Вычисляем общее количество калорий для дня
    int totalCalories = 0;

    for (var recipe in [...breakfastRecipes, ...lunchRecipes, ...dinnerRecipes]) {
      totalCalories += recipe['calories'] as int;
    }

    _mealPlanData[dateString] = {
      'calories': totalCalories,
      'meals': [
        {
          'id': 1,
          'type': 'Завтрак',
          'time': '08:00',
          'recipes': breakfastRecipes,
        },
        {
          'id': 2,
          'type': 'Обед',
          'time': '13:00',
          'recipes': lunchRecipes,
        },
        {
          'id': 3,
          'type': 'Ужин',
          'time': '19:00',
          'recipes': dinnerRecipes,
        },
      ],
    };
  }

  // Получение плана на конкретный день
  Map<String, dynamic>? getMealPlanForDate(DateTime date) {
    final dateString = DateFormatter.formatDateISO(date);
    return _mealPlanData[dateString];
  }

  // Обновление плана для конкретного дня
  void updateMealPlanForDate(DateTime date, Map<String, dynamic> newData) {
    final dateString = DateFormatter.formatDateISO(date);
    _mealPlanData[dateString] = newData;
  }

  // Очистка всех данных
  void clear() {
    _mealPlanData.clear();
    _isInitialized = false;
  }
}