// lib/screens/meal_plan/daily_plan_screen.dart
import 'package:flutter/material.dart';
import '../../utils/date_formatter.dart';

class DailyPlanScreen extends StatefulWidget {
  final DateTime? date;

  const DailyPlanScreen({Key? key, this.date}) : super(key: key);

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  late DateTime _selectedDate;

  // Симуляция данных о приемах пищи
  List<Map<String, dynamic>> _meals = [];

  // Общее количество калорий
  int _totalCalories = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date ?? DateTime.now();

    // Инициализация данных
    _initMealData();
  }

  // Инициализация данных о приемах пищи (симуляция)
  void _initMealData() {
    _meals = [
      {
        'id': 1,
        'type': 'Завтрак',
        'time': '08:00',
        'recipes': [
          {'id': 1, 'name': 'Омлет с овощами', 'calories': 350},
          {'id': 2, 'name': 'Тост с авокадо', 'calories': 220},
        ],
      },
      {
        'id': 2,
        'type': 'Обед',
        'time': '13:00',
        'recipes': [
          {'id': 3, 'name': 'Куриный суп', 'calories': 420},
          {'id': 4, 'name': 'Салат из свежих овощей', 'calories': 180},
        ],
      },
      {
        'id': 3,
        'type': 'Ужин',
        'time': '19:00',
        'recipes': [
          {'id': 5, 'name': 'Запеченная рыба', 'calories': 380},
          {'id': 6, 'name': 'Гарнир из риса', 'calories': 250},
        ],
      },
    ];

    _updateTotalCalories();
  }

  // Обновление общего количества калорий
  void _updateTotalCalories() {
    _totalCalories = 0;
    for (final meal in _meals) {
      for (final recipe in meal['recipes']) {
        _totalCalories += recipe['calories'] as int;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('План на ${DateFormatter.formatDateShort(_selectedDate)}'),
      ),
      body: Column(
        children: [
          // Информация о калориях
          Card(
            margin: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              child: Stack(
                children: [
                  // Основное содержимое карточки
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Всего калорий',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_totalCalories ккал',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Кнопка изменения цели
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showCaloriesTargetDialog();
                      },
                      tooltip: 'Изменить цель',
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Список приемов пищи
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _meals.map((meal) => _buildMealCard(meal)).toList(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _meals.removeAt(oldIndex);
                  _meals.insert(newIndex, item);
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMealDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    return Card(
      key: Key('meal_${meal['id']}'),
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
                Row(
                  children: [
                    const Icon(Icons.restaurant),
                    const SizedBox(width: 8),
                    Text(
                      meal['type'] as String,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meal['time'] as String,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _showEditMealDialog(meal);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _showDeleteMealDialog(meal);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),

            // Список рецептов
            if ((meal['recipes'] as List).isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Нет добавленных рецептов',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else
              ...List.generate(
                (meal['recipes'] as List).length,
                    (index) => _buildRecipeItem(meal['recipes'][index], meal),
              ),

            // Кнопка добавления рецепта
            InkWell(
              onTap: () {
                _showAddRecipeDialog(meal);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Добавить рецепт',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeItem(Map<String, dynamic> recipe, Map<String, dynamic> meal) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.restaurant_menu,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(recipe['name'] as String),
      subtitle: Text('${recipe['calories']} ккал'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/recipes/detail',
                arguments: {'recipeId': recipe['id']},
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                (meal['recipes'] as List).removeWhere(
                      (r) => r['id'] == recipe['id'],
                );
                _updateTotalCalories();
              });
            },
          ),
        ],
      ),
    );
  }

  // Диалог для изменения цели по калориям
  void _showCaloriesTargetDialog() {
    final caloriesController = TextEditingController(text: '2000');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Установите цель по калориям'),
        content: TextField(
          controller: caloriesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Калории в день',
            suffixText: 'ккал',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Обновление цели (в реальном приложении)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Цель по калориям обновлена')),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // Диалог для добавления нового приема пищи
  void _showAddMealDialog() {
    final typeController = TextEditingController();
    final timeController = TextEditingController(text: '12:00');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить прием пищи'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например: Завтрак, Обед, Ужин',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Время',
                hintText: 'ЧЧ:ММ',
              ),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (typeController.text.isNotEmpty) {
                setState(() {
                  _meals.add({
                    'id': _meals.length + 1,
                    'type': typeController.text,
                    'time': timeController.text,
                    'recipes': [],
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  // Диалог для редактирования приема пищи
  void _showEditMealDialog(Map<String, dynamic> meal) {
    final typeController = TextEditingController(text: meal['type'] as String);
    final timeController = TextEditingController(text: meal['time'] as String);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать прием пищи'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Название',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Время',
                hintText: 'ЧЧ:ММ',
              ),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (typeController.text.isNotEmpty) {
                setState(() {
                  meal['type'] = typeController.text;
                  meal['time'] = timeController.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // Диалог для удаления приема пищи
  void _showDeleteMealDialog(Map<String, dynamic> meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить прием пищи'),
        content: Text('Вы уверены, что хотите удалить "${meal['type']}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _meals.removeWhere((m) => m['id'] == meal['id']);
                _updateTotalCalories();
              });
              Navigator.pop(context);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // Диалог для добавления рецепта
  void _showAddRecipeDialog(Map<String, dynamic> meal) {
    // Симуляция списка доступных рецептов
    final availableRecipes = [
      {'id': 10, 'name': 'Каша овсяная', 'calories': 220},
      {'id': 11, 'name': 'Греческий салат', 'calories': 150},
      {'id': 12, 'name': 'Куриная грудка', 'calories': 300},
      {'id': 13, 'name': 'Паста с соусом', 'calories': 450},
      {'id': 14, 'name': 'Творог с ягодами', 'calories': 180},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить рецепт'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableRecipes.length,
            itemBuilder: (context, index) {
              final recipe = availableRecipes[index];
              return ListTile(
                title: Text(recipe['name'] as String),
                subtitle: Text('${recipe['calories']} ккал'),
                onTap: () {
                  setState(() {
                    (meal['recipes'] as List).add(recipe);
                    _updateTotalCalories();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }
}