// lib/screens/recipes/recipes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Добавлен импорт
import '../../repositories/data_repository.dart';
import '../../models/recipe.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;
  String? _errorMessage;

  // Lists to store recipes
  List<Recipe> _allRecipes = [];
  List<Recipe> _favoriteRecipes = [];
  List<Recipe> _recommendedRecipes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load data when screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Load recipe data from repository
  Future<void> _loadData({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    }

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      // Добавляем обработку ошибок с более подробными сообщениями
      try {
        // Load all recipes
        _allRecipes = await dataRepository.getRecipes(forceRefresh: forceRefresh);
      } catch (e) {
        print("Error loading recipes: $e");

        if (e.toString().contains("column ingredient_type.category does not exist")) {
          throw Exception('Ошибка в структуре данных: поле категории отсутствует в базе данных. Требуется обновление приложения.');
        } else if (e.toString().contains("SocketException") ||
            e.toString().contains("Connection")) {
          throw Exception('Ошибка соединения с сервером. Проверьте подключение к интернету.');
        } else {
          throw e; // Пробрасываем другие ошибки
        }
      }

      try {
        // Load favorite recipes
        _favoriteRecipes = await dataRepository.getFavoriteRecipes(forceRefresh: forceRefresh);
      } catch (e) {
        print("Error loading favorite recipes: $e");
        // Даже если не удалось загрузить избранное, продолжаем работу
        _favoriteRecipes = [];
      }

      // Get recommended recipes (for now, just take newest ones or most popular)
      // In a real implementation, this would use a more sophisticated algorithm
      try {
        _recommendedRecipes = List.from(_allRecipes);
        _recommendedRecipes.sort((a, b) => b.calories.compareTo(a.calories)); // Sort by calories for now
        if (_recommendedRecipes.length > 5) {
          _recommendedRecipes = _recommendedRecipes.sublist(0, 5);
        }
      } catch (e) {
        print("Error preparing recommended recipes: $e");
        // Если не удалось подготовить рекомендации, просто оставляем пустой список
        _recommendedRecipes = [];
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().startsWith('Exception: ')
              ? e.toString().substring('Exception: '.length)
              : 'Ошибка загрузки данных: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  List<Recipe> _getFilteredRecipes() {
    if (_searchQuery.isEmpty) return _allRecipes;

    return _allRecipes.where((recipe) =>
        recipe.title.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рецепты'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : () => _loadData(forceRefresh: true),
          ),
        ],
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
          // Error message if any
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.all(8.0),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  )
                ],
              ),
            ),

          // Search bar
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

          // Loading indicator
          if (_isRefreshing)
            LinearProgressIndicator(),

          // Recipe lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All recipes tab
                _buildRecipesList(_getFilteredRecipes()),

                // Recommended tab
                _buildRecipesList(_recommendedRecipes),

                // Favorites tab
                _buildRecipesList(_favoriteRecipes),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Functionality for adding a custom recipe
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Добавление рецепта будет доступно в будущем')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecipesList(List<Recipe> recipes) {
    if (_isRefreshing && recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка рецептов...'),
          ],
        ),
      );
    }

    if (recipes.isEmpty) {
      return Center(
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadData(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Обновить'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
              ).then((_) {
                // Refresh data when returning from details
                _loadData();
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Recipe image с использованием CachedNetworkImage
                  recipe.mainImageUrl != null && recipe.mainImageUrl!.isNotEmpty
                      ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: recipe.mainImageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        print('ОШИБКА ЗАГРУЗКИ ИЗОБРАЖЕНИЯ: $url, ошибка: $error');
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            color: Theme.of(context).colorScheme.primary,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  )
                      : Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Recipe information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Исправленное отображение информации о рецепте
                        Row(
                          children: [
                            // Калории
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
                            const SizedBox(width: 8), // Уменьшен отступ

                            // Время приготовления с ограничением ширины
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${recipe.prepTime} мин',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Favorite button
                  IconButton(
                    icon: Icon(
                      recipe.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: recipe.isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      _toggleFavorite(recipe.id);
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

  Future<void> _toggleFavorite(int recipeId) async {
    final dataRepository = Provider.of<DataRepository>(context, listen: false);

    try {
      final success = await dataRepository.toggleFavoriteRecipe(recipeId);

      if (success) {
        // Refresh data after toggling favorite
        await _loadData();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось обновить статус избранного')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }
}