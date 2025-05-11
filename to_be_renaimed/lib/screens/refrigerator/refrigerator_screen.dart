// lib/screens/refrigerator/refrigerator_screen.dart - COMPLETE FILE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/refrigerator_item.dart';
import '../../models/ingredient_type.dart';
import '../../models/enums.dart';

class RefrigeratorScreen extends StatefulWidget {
  const RefrigeratorScreen({Key? key}) : super(key: key);

  @override
  State<RefrigeratorScreen> createState() => _RefrigeratorScreenState();
}

class _RefrigeratorScreenState extends State<RefrigeratorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Все';

  bool _isRefreshing = false; // Флаг для предотвращения повторных обновлений
  String? _error;

  List<RefrigeratorItem> _items = [];
  List<RefrigeratorItem> _expiringItems = [];
  List<IngredientType> _categories = [];
  RefrigeratorStats? _stats;

  DataRepository? _dataRepository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dataRepository == null) {
      _dataRepository = Provider.of<DataRepository>(context, listen: false);
      _loadData();
    }
  }

  @override
  void dispose() {
    print('RefrigeratorScreen: dispose called');
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Обновленный метод загрузки данных
  Future<void> _loadData() async {
    print('_loadData: Starting data load');

    try {
      setState(() {
        _error = null;
      });

      final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

      // Загружаем данные в зависимости от активной вкладки
      if (_tabController.index == 0) {
        print('_loadData: Loading items and categories');
        await _loadItems();
        await _loadCategories();
      } else {
        print('_loadData: Loading expiring items');
        await _loadExpiringItems();
      }

      // Всегда загружаем статистику
      print('_loadData: Loading statistics');
      await _loadStats();

      print('_loadData: Data loaded successfully');
    } catch (e) {
      print('_loadData: Error occurred - $e');
      setState(() {
        _error = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadItems() async {
    final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

    try {
      List<RefrigeratorItem> items;
      if (_searchQuery.isNotEmpty || _selectedCategory != 'Все') {
        // Если есть фильтры, загружаем отфильтрованные данные
        items = await dataRepository.getFilteredRefrigeratorItems(
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          category: _selectedCategory != 'Все' ? _selectedCategory : null,
        );
      } else {
        // Если нет фильтров, получаем все продукты из DataRepository
        items = dataRepository.refrigeratorItems;

        // Если список пустой, принудительно загружаем
        if (items.isEmpty) {
          items = await dataRepository.getRefrigeratorItems();
        }
      }

      setState(() {
        _items = items;
      });
    } catch (e) {
      print('Ошибка загрузки продуктов: $e');
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки продуктов: $e';
        });
      }
    }
  }

  Future<void> _loadExpiringItems() async {
    final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

    try {
      final items = await dataRepository.getExpiringItems();

      setState(() {
        _expiringItems = items;
      });
    } catch (e) {
      print('Ошибка загрузки истекающих продуктов: $e');
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки продуктов: $e';
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

    try {
      final categories = await dataRepository.getRefrigeratorCategories();

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Ошибка загрузки категорий: $e');
    }
  }

  Future<void> _loadStats() async {
    final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

    try {
      final stats = await dataRepository.getRefrigeratorStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      print('Ошибка загрузки статистики: $e');
    }
  }

  // Новый метод для обработки возврата с других экранов
  Future<void> _handleNavigationReturn(dynamic result) async {
    if (result == true) {
      // Принудительно обновляем данные из API
      final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);
      await dataRepository.getRefrigeratorItems(forceRefresh: true);
      await dataRepository.getRefrigeratorCategories(forceRefresh: true);
      await _loadData();
    }
  }

  // Улучшенный метод обновления данных
  Future<void> _refreshData() async {
    if (_isRefreshing) return; // Предотвращаем многократные вызовы

    setState(() {
      _isRefreshing = true;
    });

    try {
      final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

      // Принудительно обновляем данные
      await dataRepository.getRefrigeratorItems(forceRefresh: true);
      await dataRepository.getRefrigeratorCategories(forceRefresh: true);
      await _loadData();
    } catch (e) {
      print('Error in _refreshData: $e');
      throw e; // Перебрасываем исключение для обработки выше
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _removeItem(RefrigeratorItem item) async {
    final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

    try {
      final success = await dataRepository.removeRefrigeratorItem(item.id);

      if (success) {
        // Обновляем локальные списки
        setState(() {
          _items.removeWhere((i) => i.id == item.id);
          _expiringItems.removeWhere((i) => i.id == item.id);
        });

        // После удаления проверяем, остались ли продукты этого типа
        final removedItemType = item.ingredient?.type;
        if (removedItemType != null) {
          // Проверяем, есть ли еще продукты этого типа
          final hasItemsOfThisType = _items.any((item) =>
          item.ingredient?.type?.id == removedItemType.id);

          if (!hasItemsOfThisType) {
            // Если больше нет продуктов этого типа, удаляем его из категорий
            setState(() {
              _categories.removeWhere((cat) => cat.id == removedItemType.id);

              // Если удаляемый тип был выбран в фильтре, сбрасываем на "Все"
              if (_selectedCategory == removedItemType.name) {
                _selectedCategory = 'Все';
                // Перезагружаем список без фильтра
                _loadItems();
              }
            });
          }
        }

        // Показываем уведомление
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} удален из холодильника'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context);

    // Используем данные из DataRepository
    final isLoading = dataRepository.isLoading;

    // Создаем список категорий для фильтра
    List<String> categoryNames = ['Все'];
    categoryNames.addAll(_categories.map((cat) => cat.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой холодильник'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все продукты'),
            Tab(text: 'Скоро истекают'),
          ],
        ),
        actions: [
          if (_stats != null)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.info_outline),
                  if (_stats!.expiringSoon > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_stats!.expiringSoon}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                _showStatsDialog();
              },
            ),
        ],
      ),
      body: _isRefreshing
          ? Stack(
        children: [
          _buildCurrentContent(),
          Container(
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      )
          : _buildCurrentContent(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'btn1',
            onPressed: () {
              Navigator.pushNamed(context, '/refrigerator/barcode-scanner')
                  .then((result) => _handleNavigationReturn(result));
            },
            backgroundColor: Colors.orange,
            mini: true,
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'btn2',
            onPressed: () {
              Navigator.pushNamed(context, '/refrigerator/add-product')
                  .then((result) => _handleNavigationReturn(result));
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Произошла ошибка',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Создаем список категорий для фильтра
    List<String> categoryNames = ['Все'];
    categoryNames.addAll(_categories.map((cat) => cat.name));

    return Column(
      children: [
        // Поиск
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск продуктов',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                  _loadItems();
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
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchQuery == value) {
                  _loadItems();
                }
              });
            },
          ),
        ),

        // Фильтр категорий (только для вкладки "Все продукты")
        if (_tabController.index == 0)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categoryNames.length,
              itemBuilder: (context, index) {
                final category = categoryNames[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _loadItems();
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),

        // Список продуктов
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductsList(_items),
              _buildProductsList(_expiringItems),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList(List<RefrigeratorItem> products) {
    // ... rest of the build methods remain the same ...
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.kitchen,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0
                  ? 'Ваш холодильник пуст'
                  : 'Нет продуктов с истекающим сроком годности',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_tabController.index == 0) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/refrigerator/add-product')
                      .then((result) => _handleNavigationReturn(result));
                },
                icon: const Icon(Icons.add),
                label: const Text('Добавить продукты'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final item = products[index];
          final daysLeft = item.daysLeft;

          // Определение цвета индикатора срока годности
          Color statusColor;
          if (daysLeft == null) {
            statusColor = Colors.grey;
          } else if (daysLeft <= 0) {
            statusColor = Colors.red;
          } else if (daysLeft <= 3) {
            statusColor = Colors.orange;
          } else if (daysLeft <= 7) {
            statusColor = Colors.yellow;
          } else {
            statusColor = Colors.green;
          }

          return Dismissible(
            key: Key(item.id.toString()),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _removeItem(item);
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.ingredient?.imageUrl != null &&
                      item.ingredient!.imageUrl!.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.ingredient!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.kitchen,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                  )
                      : Icon(
                    Icons.kitchen,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(item.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.formattedQuantity),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          daysLeft == null
                              ? 'Срок не указан'
                              : daysLeft <= 0
                              ? 'Просрочено'
                              : 'Осталось $daysLeft дн.',
                          style: TextStyle(
                            color: daysLeft != null && daysLeft <= 0
                                ? Colors.red
                                : null,
                            fontWeight: daysLeft != null && daysLeft <= 3
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/refrigerator/add-product',
                      arguments: {'productId': item.id},
                    ).then((result) => _handleNavigationReturn(result));
                  },
                ),
                onTap: () {
                  _showProductDetails(context, item);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProductDetails(BuildContext context, RefrigeratorItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final daysLeft = item.daysLeft;
        final ingredient = item.ingredient;

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              if (ingredient != null) ...[
                _buildDetailRow(
                  context,
                  'Тип:',
                  ingredient.type?.name ?? 'Не указан',
                ),
              ],

              _buildDetailRow(
                context,
                'Количество:',
                item.formattedQuantity,
              ),

              if (ingredient?.expiryDate != null) _buildDetailRow(
                context,
                'Срок годности:',
                ingredient!.expiryDate!.toIso8601String().split('T')[0],
              ),

              if (daysLeft != null) _buildDetailRow(
                context,
                'Осталось дней:',
                daysLeft.toString(),
                valueColor: daysLeft <= 0
                    ? Colors.red
                    : daysLeft <= 3
                    ? Colors.orange
                    : null,
              ),

              if (ingredient != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Пищевая ценность',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  'Калории:',
                  '${ingredient.calories} ккал',
                ),
                _buildDetailRow(
                  context,
                  'Белки:',
                  '${ingredient.protein} г',
                ),
                _buildDetailRow(
                  context,
                  'Жиры:',
                  '${ingredient.fat} г',
                ),
                _buildDetailRow(
                  context,
                  'Углеводы:',
                  '${ingredient.carbs} г',
                ),

                // Add allergens display
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Аллергены',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (ingredient.allergens.isEmpty)
                  Text(
                    'Аллергены не указаны',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: ingredient.allergens.map((allergen) =>
                        Chip(
                          label: Text(
                            allergen.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        )
                    ).toList(),
                  ),
              ],

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/refrigerator/add-product',
                          arguments: {'productId': item.id},
                        ).then((_) => _refreshData());
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Редактировать'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/recipes',
                          arguments: {'ingredient': item},
                        );
                      },
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Рецепты'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
      BuildContext context,
      String label,
      String value, {
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: valueColor,
              fontWeight: valueColor != null ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    if (_stats == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика холодильника'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatsRow(
              'Всего продуктов:',
              _stats!.totalItems.toString(),
              Icons.inventory,
            ),
            const SizedBox(height: 16),
            _buildStatsRow(
              'Скоро истекают:',
              _stats!.expiringSoon.toString(),
              Icons.warning,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildStatsRow(
              'Просрочены:',
              _stats!.expired.toString(),
              Icons.error,
              color: Colors.red,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}