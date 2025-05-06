// lib/screens/recipes/recipes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/data_repository.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    // Получаем данные из репозитория через Provider
    final dataRepository = Provider.of<DataRepository>(context);

    // Используем рецепты из репозитория
    final recipes = dataRepository.recipes;

    // Фильтрация рецептов по поисковому запросу
    final filteredRecipes = _searchQuery.isEmpty
        ? recipes
        : recipes.where((recipe) =>
        recipe.title.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    // Избранные рецепты
    final favoriteRecipes = recipes.where((recipe) => recipe.isFavorite).toList();

    // Рекомендуемые рецепты (для примера берем первые 5 или менее)
    final recommendedRecipes = recipes.take(recipes.length < 5 ? recipes.length : 5).toList();

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

          // Список рецептов с индикатором загрузки
          Expanded(
            child: dataRepository.isLoading
                ? Center(
              child: CircularProgressIndicator(),
            )
                : TabBarView(
              controller: _tabController,
              children: [
                // Вкладка "Все"
                _buildRecipesList(filteredRecipes),

                // Вкладка "Рекомендации"
                _buildRecipesList(recommendedRecipes),

                // Вкладка "Избранное"
                _buildRecipesList(favoriteRecipes),
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

  Widget _buildRecipesList(List<dynamic> recipes) {
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
                arguments: {'recipeId': recipe.id},
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
                          recipe.title,
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
                              '${recipe.calories} ккал',
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
                              '${recipe.prepTime} мин',
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
                      recipe.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: recipe.isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      // Обновление статуса "избранное" через репозиторий
                      final dataRepository = Provider.of<DataRepository>(context, listen: false);
                      dataRepository.toggleFavoriteRecipe(recipe.id);
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