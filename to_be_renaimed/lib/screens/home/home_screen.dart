
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/refrigerator_item.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/recipe.dart';
import '../../models/user.dart';
import '../../models/ingredient.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingRecipes = false;
  bool _isLoadingRefrigerator = false;

  List<Recipe> _recommendedRecipes = [];
  List<RefrigeratorItem> _expiringProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _loadRecommendedRecipes();
    _loadExpiringProducts();
  }

  Future<void> _loadRecommendedRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
    });

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final recipes = await dataRepository.getRecipes();

      
      
      
      if (recipes.isNotEmpty) {
        
        final sorted = List<Recipe>.from(recipes);
        sorted.sort((a, b) => b.calories.compareTo(a.calories));

        
        _recommendedRecipes = sorted.take(sorted.length > 5 ? 5 : sorted.length).toList();
      }
    } catch (e) {
      print('Error loading recommended recipes: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecipes = false;
        });
      }
    }
  }

  Future<void> _loadExpiringProducts() async {
    setState(() {
      _isLoadingRefrigerator = true;
    });

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      
      _expiringProducts = await dataRepository.getExpiringItems();
    } catch (e) {
      print('Error loading expiring products: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRefrigerator = false;
        });
      }
    }
  }

  
  DateTime _getStartOfWeek() {
    final now = DateTime.now();
    
    final difference = now.weekday - 1;
    
    return DateTime(now.year, now.month, now.day - difference);
  }

  
  DateTime _getEndOfWeek() {
    final startOfWeek = _getStartOfWeek();
    
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6);
  }

  
  String _formatDate(DateTime date) {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  
  int _getCurrentDayOfWeek() {
    return DateTime.now().weekday;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'Пользователь';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Привет, $userName!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Что будем готовить сегодня?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'П',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Рекомендуемые рецепты',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/recipes');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Все'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _isLoadingRecipes
                    ? const Center(child: CircularProgressIndicator())
                    : _recommendedRecipes.isEmpty
                    ? _buildEmptyRecipesView()
                    : SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendedRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recommendedRecipes[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/recipes/detail',
                            arguments: {'recipeId': recipe.id},
                          );
                        },
                        child: Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: recipe.mainImageUrl != null && recipe.mainImageUrl!.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                  child: Image.network(
                                    recipe.mainImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      
                                      return Center(
                                        child: Icon(
                                          Icons.restaurant,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      );
                                    },
                                  ),
                                )
                                    : Center(
                                  child: Icon(
                                    Icons.restaurant,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${recipe.calories} ккал',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Срочные продукты',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/refrigerator');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Все'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _isLoadingRefrigerator
                    ? const Center(child: CircularProgressIndicator())
                    : _expiringProducts.isEmpty
                    ? _buildEmptyProductsView()
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _expiringProducts.length,
                    itemBuilder: (context, index) {
                      final product = _expiringProducts[index];
                      
                      final daysLeft = product.ingredient!.expiryDate!.difference(DateTime.now()).inDays + 1;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.kitchen, color: Colors.orange),
                        ),
                        title: Text(product.ingredient!.name),
                        subtitle: Text('Истекает через $daysLeft дн.'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pushNamed(context, '/refrigerator');
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                
                Text(
                  'Текущий план питания',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'План на неделю',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatDate(_getStartOfWeek())} - ${_formatDate(_getEndOfWeek())} ${_getEndOfWeek().year}',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Прогресс: ${_getCurrentDayOfWeek()}/7 дней'),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/meal-plan/weekly');
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Смотреть'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                
                Text(
                  'Быстрый доступ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAccessButton(
                      context,
                      Icons.add_shopping_cart,
                      'Добавить\nпродукт',
                          () => Navigator.pushNamed(context, '/refrigerator/add-product'),
                    ),
                    _buildQuickAccessButton(
                      context,
                      Icons.camera_alt,
                      'Сканировать\nштрих-код',
                          () => Navigator.pushNamed(context, '/refrigerator/barcode-scanner'),
                    ),
                    _buildQuickAccessButton(
                      context,
                      Icons.calendar_today,
                      'Создать план\nпитания',
                          () => Navigator.pushNamed(context, '/meal-plan/generate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecipesView() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Нет рекомендуемых рецептов',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProductsView() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.kitchen,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Нет продуктов с истекающим сроком годности',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onTap,
      ) {
    
    
    final buttonWidth = (MediaQuery.of(context).size.width - 48 - 6) / 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonWidth,
        height: 110, 
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}