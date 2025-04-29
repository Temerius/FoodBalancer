import 'package:flutter/material.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Симуляция списка рецептов
  final List<Map<String, dynamic>> _recipes = List.generate(
    20,
        (index) => {
      'id': index + 1,
      'title': 'Рецепт ${index + 1}',
      'calories': 200 + (index * 30),
      'time': 15 + (index % 4) * 10,
      'imageUrl': '',
      'isFavorite': false,
    },
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredRecipes {
    if (_searchQuery.isEmpty) {
      return _recipes;
    }
    return _recipes.where((recipe) {
      return recipe['title'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _favoriteRecipes {
    return _recipes.where((recipe) => recipe['isFavorite']).toList();
  }

  List<Map<String, dynamic>> get _recommendedRecipes {
    // Просто для примера берем первые 5 рецептов
    return _recipes.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рецепты'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все'),
            Tab(text: 'Рекомендации'),
            Tab(text: 'Избранное'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск рецептов',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Список рецептов
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Вкладка "Все"
                _buildRecipesList(_filteredRecipes),

                // Вкладка "Рекомендации"
                _buildRecipesList(_recommendedRecipes),

                // Вкладка "Избранное"
                _buildRecipesList(_favoriteRecipes),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Можно добавить функциональность для добавления своего рецепта
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Добавление рецепта будет доступно в будущем')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecipesList(List<Map<String, dynamic>> recipes) {
    return recipes.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет доступных рецептов',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/recipes/detail',
                arguments: {'recipeId': recipe['id']},
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Изображение рецепта
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Информация о рецепте
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['title'],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe['calories']} ккал',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe['time']} мин',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Кнопка "Избранное"
                  IconButton(
                    icon: Icon(
                      recipe['isFavorite']
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: recipe['isFavorite'] ? Colors.red : null,
                    ),
                    onPressed: () {
                      setState(() {
                        recipe['isFavorite'] = !recipe['isFavorite'];
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}