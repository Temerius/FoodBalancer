import 'package:flutter/material.dart';
import '../../utils/date_formatter.dart';

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

    // Инициализация данных о приемах пищи (симуляция)
    _initMealPlanData();
  }

  // Получение начала недели (понедельник)
  DateTime _getWeekStart(DateTime date) {
    final weekDay = date.weekday;
    return date.subtract(Duration(days: weekDay - 1));
  }

  // Инициализация данных о приемах пищи (симуляция)
  void _initMealPlanData() {
    for (final day in _weekDays) {
      final dateString = DateFormatter.formatDateISO(day);

      _mealPlanData[dateString] = {
        'calories': 1800 + (day.day % 3) * 100,
        'meals': [
          {
            'type': 'Завтрак',
            'time': '08:00',
            'recipes': [
              {'id': 1, 'name': 'Омлет с овощами', 'calories': 350},
              {'id': 2, 'name': 'Тост с авокадо', 'calories': 220},
            ],
          },
          {
            'type': 'Обед',
            'time': '13:00',
            'recipes': [
              {'id': 3, 'name': 'Куриный суп', 'calories': 420},
              {'id': 4, 'name': 'Салат из свежих овощей', 'calories': 180},
            ],
          },
          {
            'type': 'Ужин',
            'time': '19:00',
            'recipes': [
              {'id': 5, 'name': 'Запеченная рыба', 'calories': 380},
              {'id': 6, 'name': 'Гарнир из риса', 'calories': 250},
            ],
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
      body: Column(
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/meal-plan/daily',
                        arguments: {'date': _selectedDay},
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Изменить'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
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