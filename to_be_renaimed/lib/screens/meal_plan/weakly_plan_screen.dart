// lib/screens/meal_plan/weakly_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/date_formatter.dart';
import '../../repositories/data_repository.dart';
import '../../models/recipe.dart';
import 'dart:math';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  // Текущая неделя (первый день недели - понедельник)
  late DateTime _currentWeekStart;

  // Список дней недели
  late List<DateTime> _weekDays;

  // Выбранный день
  late DateTime _selectedDay;

  // Информация о приемах пищи для текущей недели (ключ - дата в формате yyyy-MM-dd)
  final Map<String, Map<String, dynamic>> _mealPlanData = {};

  // Данные о рецептах
  List<Recipe> _allRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Инициализация текущей недели
    final now = DateTime.now();
    _currentWeekStart = _getWeekStart(now);
    _selectedDay = now;

    // Получение списка дней недели
    _weekDays = List.generate(
      7,
          (index) => _currentWeekStart.add(Duration(days: index)),
    );

    // Загружаем рецепты и инициализируем данные
    _loadRecipesAndInitData();
  }

  // Загрузка рецептов и инициализация данных о приемах пищи
  Future<void> _loadRecipesAndInitData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      _allRecipes = await dataRepository.getRecipes();

      // Инициализация данных о приемах пищи с реальными рецептами
      _initMealPlanData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
  List<Map<String, dynamic>> _getRandomRecipes(int count, String type, String time) {
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

  // Получение начала недели (понедельник)
  DateTime _getWeekStart(DateTime date) {
    final weekDay = date.weekday;
    return date.subtract(Duration(days: weekDay - 1));
  }

  // Инициализация данных о приемах пищи с реальными рецептами
  void _initMealPlanData() {
    for (final day in _weekDays) {
      final dateString = DateFormatter.formatDateISO(day);

      // Формируем случайные приемы пищи для каждого дня
      final breakfastRecipes = _getRandomRecipes(2, 'Завтрак', '08:00');
      final lunchRecipes = _getRandomRecipes(2, 'Обед', '13:00');
      final dinnerRecipes = _getRandomRecipes(2, 'Ужин', '19:00');

      // Вычисляем общее количество калорий для дня
      int totalCalories = 0;

      for (var recipe in [...breakfastRecipes, ...lunchRecipes, ...dinnerRecipes]) {
        totalCalories += recipe['calories'] as int;
      }

      _mealPlanData[dateString] = {
        'calories': totalCalories,
        'meals': [
          {
            'type': 'Завтрак',
            'time': '08:00',
            'recipes': breakfastRecipes,
          },
          {
            'type': 'Обед',
            'time': '13:00',
            'recipes': lunchRecipes,
          },
          {
            'type': 'Ужин',
            'time': '19:00',
            'recipes': dinnerRecipes,
          },
        ],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('План питания на неделю'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/meal-plan/generate');
            },
            tooltip: 'Создать новый план',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Навигация по неделям
          _buildWeekNavigation(),

          // Дни недели
          _buildWeekDaySelector(),

          // План на выбранный день
          Expanded(
            child: _buildDayPlan(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final startDateFormatted = DateFormatter.formatDateMonth(_currentWeekStart);
    final endDateFormatted = DateFormatter.formatDateMonthYear(
      _currentWeekStart.add(const Duration(days: 6)),
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                _weekDays = List.generate(
                  7,
                      (index) => _currentWeekStart.add(Duration(days: index)),
                );
                // Инициализация данных о приемах пищи для новой недели
                _initMealPlanData();
              });
            },
          ),
          Text(
            '$startDateFormatted - $endDateFormatted',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                _weekDays = List.generate(
                  7,
                      (index) => _currentWeekStart.add(Duration(days: index)),
                );
                // Инициализация данных о приемах пищи для новой недели
                _initMealPlanData();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _weekDays.map((day) {
          final isSelected = _isSameDay(day, _selectedDay);
          final isToday = _isSameDay(day, DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = day;
              });
            },
            child: Container(
              width: 40,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                borderRadius: BorderRadius.circular(20),
                border: isToday && !isSelected
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayOfWeekShort(day),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayPlan() {
    final selectedDateString = DateFormatter.formatDateISO(_selectedDay);
    final dayData = _mealPlanData[selectedDateString];

    if (dayData == null) {
      return const Center(
        child: Text('Нет данных о плане питания на выбранный день'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о калориях
          Card(
              margin: const EdgeInsets.only(bottom: 16),
              // Убедимся, что карточка занимает всю ширину
              child: Container(
                width: double.infinity,
                child: Stack(
                  children: [
                    // Основное содержимое карточки с дополнительным отступом справа
                    // чтобы текст не перекрывался с иконкой
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormatter.formatDateFull(_selectedDay),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Всего калорий: ${dayData['calories']} ккал',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Кнопка редактирования в виде карандаша
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/meal-plan/daily',
                            arguments: {'date': _selectedDay},
                          );
                        },
                        tooltip: 'Изменить',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
          ),

          // Приемы пищи
          ...(dayData['meals'] as List).map((meal) => _buildMealCard(meal)),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final recipes = meal['recipes'] as List;
    final totalCalories = recipes.fold<int>(
      0,
          (sum, recipe) => sum + (recipe['calories'] as int),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок приема пищи
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  meal['type'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  meal['time'] as String,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const Divider(),

            // Список рецептов
            ...recipes.map((recipe) => _buildRecipeItem(recipe)),

            const Divider(),

            // Итоговые калории
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Всего калорий:'),
                Text(
                  '$totalCalories ккал',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeItem(Map<String, dynamic> recipe) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(recipe['name'] as String),
      subtitle: Text('${recipe['calories']} ккал'),
      trailing: IconButton(
        icon: const Icon(Icons.visibility),
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/recipes/detail',
            arguments: {'recipeId': recipe['id']},
          );
        },
      ),
    );
  }

  // Проверка, является ли день тем же самым (без учета времени)
  bool _isSameDay(DateTime day1, DateTime day2) {
    return day1.year == day2.year &&
        day1.month == day2.month &&
        day1.day == day2.day;
  }

  // Получение сокращенного названия дня недели
  String _getDayOfWeekShort(DateTime day) {
    final weekDays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return weekDays[day.weekday - 1];
  }
}