import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int? recipeId;

  const RecipeDetailScreen({Key? key, this.recipeId}) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isFavorite = false;

  // Симуляция данных рецепта
  Map<String, dynamic> _recipe = {};

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  void _loadRecipe() {
    // Здесь будет загрузка данных о рецепте с сервера
    // Для примера используем статичные данные
    setState(() {
      _recipe = {
        'id': widget.recipeId ?? 1,
        'title': 'Рецепт ${widget.recipeId ?? 1}',
        'description': 'Описание рецепта. Вкусное и полезное блюдо для всей семьи.',
        'calories': 350,
        'protein': 15,
        'fat': 10,
        'carbs': 30,
        'time': 30,
        'servings': 4,
        'ingredients': [
          {'name': 'Ингредиент 1', 'quantity': '200 г'},
          {'name': 'Ингредиент 2', 'quantity': '150 г'},
          {'name': 'Ингредиент 3', 'quantity': '100 мл'},
          {'name': 'Ингредиент 4', 'quantity': '2 ст. л.'},
          {'name': 'Ингредиент 5', 'quantity': '1 шт.'},
        ],
        'steps': [
          'Шаг 1: Подготовьте все ингредиенты. Нарежьте овощи кубиками.',
          'Шаг 2: Разогрейте сковороду и добавьте масло.',
          'Шаг 3: Обжарьте ингредиенты на среднем огне 5-7 минут.',
          'Шаг 4: Добавьте специи и перемешайте.',
          'Шаг 5: Готовьте еще 10 минут до готовности.',
        ],
      };
      _isFavorite = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _recipe.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          // AppBar с изображением
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_recipe['title']),
              background: Container(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isFavorite
                            ? 'Добавлено в избранное'
                            : 'Удалено из избранного',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Эта функция будет доступна в будущем'),
                    ),
                  );
                },
              ),
            ],
          ),

          // Содержимое рецепта
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Описание рецепта
                  Text(
                    _recipe['description'],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Информация о рецепте
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn(
                          context,
                          Icons.access_time,
                          '${_recipe['time']} мин',
                          'Время'
                      ),
                      _buildInfoColumn(
                          context,
                          Icons.restaurant,
                          '${_recipe['servings']} порц.',
                          'Порции'
                      ),
                      _buildInfoColumn(
                          context,
                          Icons.local_fire_department,
                          '${_recipe['calories']} ккал',
                          'Калории'
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // БЖУ
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrientInfo(
                              context,
                              'Белки',
                              '${_recipe['protein']} г'
                          ),
                          _buildNutrientInfo(
                              context,
                              'Жиры',
                              '${_recipe['fat']} г'
                          ),
                          _buildNutrientInfo(
                              context,
                              'Углеводы',
                              '${_recipe['carbs']} г'
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ингредиенты
                  Text(
                    'Ингредиенты',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _recipe['ingredients'].length,
                        (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _recipe['ingredients'][index]['name'],
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Text(
                            _recipe['ingredients'][index]['quantity'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Кнопка добавления недостающих ингредиентов в список покупок
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Добавлено в список покупок'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Добавить в список покупок'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Инструкции
                  Text(
                    'Инструкции',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _recipe['steps'].length,
                        (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _recipe['steps'][index],
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Кнопка "Приготовить"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Добавить в "Сегодня готовлю"
                        Navigator.pushNamed(context, '/meal-plan/daily');
                      },
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Приготовить сегодня'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
      BuildContext context,
      IconData icon,
      String value,
      String label,
      ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildNutrientInfo(
      BuildContext context,
      String label,
      String value,
      ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}