
import 'dart:math';
import '../models/recipe.dart';
import '../utils/date_formatter.dart';

class MealPlanService {
  
  static final MealPlanService _instance = MealPlanService._internal();
  factory MealPlanService() => _instance;
  MealPlanService._internal();

  
  final Map<String, Map<String, dynamic>> _mealPlanData = {};

  
  Map<String, Map<String, dynamic>> get allMealPlans => _mealPlanData;

  
  List<Recipe> _allRecipes = [];

  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  
  Future<void> initializeWithRecipes(List<Recipe> recipes) async {
    if (_isInitialized) return;

    _allRecipes = recipes;

    
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    
    final weekDays = List.generate(
      14, 
          (index) => weekStart.add(Duration(days: index)),
    );

    
    for (final day in weekDays) {
      final dateString = DateFormatter.formatDateISO(day);
      _initMealPlanForDay(dateString);
    }

    _isInitialized = true;
  }

  
  DateTime _getWeekStart(DateTime date) {
    final weekDay = date.weekday;
    return date.subtract(Duration(days: weekDay - 1));
  }

  
  Recipe _getRandomRecipe() {
    if (_allRecipes.isEmpty) {
      
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

  
  List<Map<String, dynamic>> _getRandomRecipes(int count) {
    final List<Map<String, dynamic>> recipes = [];
    final recipesSet = <int>{};  

    for (int i = 0; i < count; i++) {
      
      Recipe recipe;
      int attempts = 0;

      do {
        recipe = _getRandomRecipe();
        attempts++;
        
        if (attempts > 5) break;
      } while (recipesSet.contains(recipe.id) && recipe.id != 0);

      
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

  
  void _initMealPlanForDay(String dateString) {
    
    final breakfastRecipes = _getRandomRecipes(2);
    final lunchRecipes = _getRandomRecipes(2);
    final dinnerRecipes = _getRandomRecipes(2);

    
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

  
  Map<String, dynamic>? getMealPlanForDate(DateTime date) {
    final dateString = DateFormatter.formatDateISO(date);
    return _mealPlanData[dateString];
  }

  
  void updateMealPlanForDate(DateTime date, Map<String, dynamic> newData) {
    final dateString = DateFormatter.formatDateISO(date);
    _mealPlanData[dateString] = newData;
  }

  
  void clear() {
    _mealPlanData.clear();
    _isInitialized = false;
  }
}