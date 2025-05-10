// lib/screens/recipes/recipe_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/recipe.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int? recipeId;

  const RecipeDetailScreen({Key? key, this.recipeId}) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe({bool forceRefresh = false}) async {
    if (widget.recipeId == null) {
      setState(() {
        _errorMessage = 'Ошибка: ID рецепта не указан';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      // Добавим лог для отладки
      print("Trying to load recipe with ID: ${widget.recipeId}");

      final recipe = await dataRepository.getRecipeDetails(widget.recipeId!, forceRefresh: forceRefresh);

      if (recipe == null) {
        setState(() {
          _errorMessage = 'Рецепт не найден';
        });
      } else {
        setState(() {
          _recipe = recipe;
        });
      }
    } catch (e) {
      // Более подробная обработка ошибок
      setState(() {
        if (e.toString().contains("column ingredient_type.category does not exist")) {
          _errorMessage = 'Ошибка в структуре данных: поле категории отсутствует в базе данных. Требуется обновление приложения.';
        } else if (e.toString().contains("SocketException") ||
            e.toString().contains("Connection")) {
          _errorMessage = 'Ошибка соединения с сервером. Проверьте подключение к интернету.';
        } else if (e.toString().contains("404")) {
          _errorMessage = 'Рецепт не найден на сервере.';
        } else {
          _errorMessage = 'Ошибка загрузки рецепта: ${e.toString()}';
        }

        // Выводим полный текст ошибки для отладки
        print("Error loading recipe: $e");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.recipeId == null || _recipe == null) return;

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final success = await dataRepository.toggleFavoriteRecipe(widget.recipeId!);

      if (success) {
        setState(() {
          _recipe = _recipe!.copyWith(isFavorite: !_recipe!.isFavorite);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _recipe!.isFavorite
                  ? 'Добавлено в избранное'
                  : 'Удалено из избранного',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _recipe != null
          ? _buildRecipeDetail()
          : const Center(child: Text('Рецепт не найден')),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Произошла ошибка',
            style: TextStyle(color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadRecipe(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeDetail() {
    return CustomScrollView(
      slivers: [
        // AppBar with image
        SliverAppBar(
          expandedHeight: 200.0,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(_recipe!.title),
            background: _recipe!.mainImageUrl != null && _recipe!.mainImageUrl!.isNotEmpty
                ? Image.network(
              _recipe!.mainImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Если не удалось загрузить изображение, показываем иконку
                return Container(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            )
                : Container(
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
                _recipe!.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _recipe!.isFavorite ? Colors.red : null,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Эта функция будет доступна в будущем')),
                );
              },
            ),
          ],
        ),

        // Recipe content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe description
                Text(
                  _recipe!.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // Recipe information
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(
                        context,
                        Icons.access_time,
                        '${_recipe!.prepTime} мин',
                        'Время'
                    ),
                    _buildInfoColumn(
                        context,
                        Icons.restaurant,
                        '${_recipe!.portionCount} порц.',
                        'Порции'
                    ),
                    _buildInfoColumn(
                        context,
                        Icons.local_fire_department,
                        '${_recipe!.calories} ккал',
                        'Калории'
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nutritional info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Пищевая ценность порции (${_recipe!.weight > 0 ? '${_recipe!.weight} г' : ''})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNutrientInfo(
                                context,
                                'Калории',
                                '${_recipe!.calories} ккал'
                            ),
                            _buildNutrientInfo(
                                context,
                                'Белки',
                                '${_recipe!.protein} г'
                            ),
                            _buildNutrientInfo(
                                context,
                                'Жиры',
                                '${_recipe!.fat} г'
                            ),
                            _buildNutrientInfo(
                                context,
                                'Углеводы',
                                '${_recipe!.carbs} г'
                            ),
                          ],
                        ),

                        if (_recipe!.weight > 0) ...[
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Добавим отображение пищевой ценности на 100 грамм
                          Text(
                            'На 100 грамм:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildNutrientInfo(
                                  context,
                                  'Калории',
                                  '${(_recipe!.weight > 0 ? _recipe?.caloriesPer100g: 0)} ккал'
                              ),
                              _buildNutrientInfo(
                                  context,
                                  'Белки',
                                  '${(_recipe!.weight > 0 ? _recipe?.proteinPer100g : 0)} г'
                              ),
                              _buildNutrientInfo(
                                  context,
                                  'Жиры',
                                  '${(_recipe!.weight > 0 ? _recipe?.fatPer100g : 0)} г'
                              ),
                              _buildNutrientInfo(
                                  context,
                                  'Углеводы',
                                  '${(_recipe!.weight > 0 ? _recipe?.carbsPer100g : 0)} г'
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Ingredients
                Text(
                  'Ингредиенты',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildIngredientsList(),

                // Add missing ingredients to shopping list button
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

                // Instructions
                Text(
                  'Инструкции',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildInstructionsList(),
                const SizedBox(height: 24),

                // Cook today button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Add to "Cook Today"
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
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
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

  Widget _buildIngredientsList() {
    // Check if recipe has ingredients
    if (_recipe?.ingredients == null || _recipe!.ingredients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Информация об ингредиентах отсутствует'),
      );
    }

    return Column(
      children: _recipe!.ingredients.map((ingredient) {
        return Padding(
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
                  ingredient.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                ingredient.formattedQuantity ?? '---',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstructionsList() {
    // Check if recipe has steps
    if (_recipe?.steps == null || _recipe!.steps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Информация о шагах приготовления отсутствует'),
      );
    }

    return Column(
      children: List.generate(
        _recipe!.steps.length,
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
                  _recipe!.steps[index].instruction,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}