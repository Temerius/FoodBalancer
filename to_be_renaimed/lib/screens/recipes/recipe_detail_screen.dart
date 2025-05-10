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

      print("Trying to load recipe with ID: ${widget.recipeId}");

      // Сначала загружаем список избранного, чтобы статус был актуальным
      await dataRepository.getFavoriteRecipes(forceRefresh: forceRefresh);

      // Затем загружаем детали рецепта
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
                  'Шаги приготовления',
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
      String label,  // Этот параметр больше не используется
      ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        // Удалили отображение label
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

  // В lib/screens/recipes/recipe_detail_screen.dart
  // В lib/screens/recipes/recipe_detail_screen.dart
  Widget _buildIngredientsList() {
    // Создаем общий список ингредиентов из всех шагов
    Map<String, Map<String, dynamic>> allIngredients = {};

    // Собираем ингредиенты из всех шагов
    if (_recipe?.steps != null) {
      for (var step in _recipe!.steps) {
        for (var ingredient in step.ingredients) {
          if (ingredient.ingredientType != null) {
            final key = '${ingredient.ingredientType!.id}_${ingredient.quantityType.toString()}';

            if (allIngredients.containsKey(key)) {
              // Складываем количество для одинаковых ингредиентов с одинаковыми единицами измерения
              allIngredients[key]!['totalQuantity'] += ingredient.quantity;
            } else {
              // Добавляем новый ингредиент
              allIngredients[key] = {
                'ingredient': ingredient,
                'totalQuantity': ingredient.quantity,
              };
            }
          }
        }
      }
    }

    if (allIngredients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Информация об ингредиентах отсутствует'),
      );
    }

    // Просто выводим все ингредиенты без группировки
    return Column(
      children: allIngredients.values.map((ingredientData) {
        final ingredient = ingredientData['ingredient'] as RecipeStepIngredient;
        final totalQuantity = ingredientData['totalQuantity'] as int;

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
                '$totalQuantity ${ingredient.quantityType.getShortName()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // В lib/screens/recipes/recipe_detail_screen.dart
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
            (index) {
          final step = _recipe!.steps[index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step number and title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
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
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (step.title.isNotEmpty) ...[
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                step.instruction,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Step ingredients (if any)
                    if (step.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Необходимо для этого шага:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: step.ingredients.map((ingredient) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${ingredient.name} - ${ingredient.formattedQuantity}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    if (step.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: step.imageUrls.length,
                          itemBuilder: (context, imageIndex) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  step.imageUrls[imageIndex],
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            color: Theme.of(context).colorScheme.onErrorContainer,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Не удалось\nзагрузить',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onErrorContainer,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}