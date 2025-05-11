// lib/screens/refrigerator/refrigerator_screen.dart - ИСПРАВЛЕНО
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

  bool _isRefreshing = false;
  String? _error;

  DataRepository? _dataRepository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // ИСПРАВЛЕНО: Сбрасываем категорию при переключении вкладок
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // После завершения анимации переключения
        if (mounted) {
          setState(() {
            // Сбрасываем категорию при переключении вкладок
            _selectedCategory = 'Все';
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dataRepository == null) {
      _dataRepository = Provider.of<DataRepository>(context, listen: false);
    }
  }

  @override
  void dispose() {
    print('RefrigeratorScreen: dispose called');
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Новый метод для обработки возврата с других экранов
  Future<void> _handleNavigationReturn(dynamic result) async {
    if (result == true) {
      final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

      // Просто обновляем данные в репозитории
      await dataRepository.getRefrigeratorItems(forceRefresh: true);

      // UI обновится автоматически
    }
  }

  // Улучшенный метод обновления данных
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

      // Просто принудительно обновляем данные в репозитории
      await dataRepository.getRefrigeratorItems(forceRefresh: true);
      await dataRepository.getRefrigeratorStats(forceRefresh: true);

      // UI обновится автоматически через Provider

    } catch (e) {
      print('Error in _refreshData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // ИСПРАВЛЕНИЕ: Полностью переписан метод _removeItem для правильного обновления статистики
  Future<void> _removeItem(RefrigeratorItem item) async {
    final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

    try {
      setState(() {
        _isRefreshing = true;
      });

      // Просто вызываем метод репозитория
      final success = await dataRepository.removeRefrigeratorItem(item.id);

      if (success && mounted) {
        // ИСПРАВЛЕНО: Принудительно обновляем статистику после удаления
        await dataRepository.getRefrigeratorStats(forceRefresh: true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} удален из холодильника'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error removing item: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _resetCategoryIfNeeded(List<IngredientType> userCategories) {
    final categoryNames = ['Все', ...userCategories.map((cat) => cat.name)];

    // Если выбранная категория больше не существует, сбрасываем на "Все"
    if (!categoryNames.contains(_selectedCategory)) {
      setState(() {
        _selectedCategory = 'Все';
      });
    }
  }



  List<RefrigeratorItem> _filterExpiringItems(List<RefrigeratorItem> items) {
    var filtered = items;

    // Поиск (так же как для основных продуктов)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = item.ingredient?.name?.toLowerCase() ?? '';
        final typeName = item.ingredient?.type?.name?.toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();
        return name.contains(searchLower) || typeName.contains(searchLower);
      }).toList();
    }

    // Категория
    if (_selectedCategory != 'Все') {
      filtered = filtered.where((item) {
        return item.ingredient?.type?.name == _selectedCategory;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // ИСПРАВЛЕНИЕ: Получаем все данные из репозитория через Provider
    return Consumer<DataRepository>(
      builder: (context, dataRepository, child) {
        // Получаем данные из репозитория
        final items = dataRepository.refrigeratorItems;
        final expiringItems = dataRepository.expiringItems;
        final userCategories = dataRepository.userRefrigeratorCategories;
        final stats = dataRepository.refrigeratorStats;
        final isLoading = dataRepository.isLoading;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _resetCategoryIfNeeded(userCategories);
        });

        // Фильтрация основных продуктов
        final filteredItems = _filterItems(items);

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
              if (stats != null)
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.info_outline),
                      if (stats.expiringSoon > 0)
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
                              '${stats.expiringSoon}',
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
                    _showStatsDialog(stats); // ИСПРАВЛЕНО: передаем правильный тип
                  },
                ),
            ],
          ),
          body: _isRefreshing
              ? Stack(
            children: [
              _buildContent(filteredItems, expiringItems, userCategories),
              Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          )
              : _buildContent(filteredItems, expiringItems, userCategories),
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
      },
    );
  }

  List<RefrigeratorItem> _filterItems(List<RefrigeratorItem> items) {
    var filtered = items;

    // Поиск
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = item.ingredient?.name?.toLowerCase() ?? '';
        final typeName = item.ingredient?.type?.name?.toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();
        return name.contains(searchLower) || typeName.contains(searchLower);
      }).toList();
    }

    // Категория
    if (_selectedCategory != 'Все') {
      filtered = filtered.where((item) {
        return item.ingredient?.type?.name == _selectedCategory;
      }).toList();
    }

    return filtered;
  }

  // ИСПРАВЛЕНИЕ: Упрощенный buildContent
  Widget _buildContent(
      List<RefrigeratorItem> filteredItems,
      List<RefrigeratorItem> expiringItems,
      List<IngredientType> userCategories,
      ) {
    // ИСПРАВЛЕНО: Выбираем категории в зависимости от активной вкладки
    final List<String> categoryNames;

    if (_tabController.index == 0) {
      // На основной вкладке - все категории из холодильника
      categoryNames = ['Все', ...userCategories.map((cat) => cat.name)];
    } else {
      // На вкладке истекающих - только категории из истекающих продуктов
      categoryNames = _getUniqueCategories(expiringItems);
    }

    // Проверяем, существует ли выбранная категория в текущем списке
    if (!categoryNames.contains(_selectedCategory)) {
      // Если текущей категории нет в списке, сбрасываем на "Все"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_selectedCategory != 'Все') {
          setState(() {
            _selectedCategory = 'Все';
          });
        }
      });
    }

    // Фильтруем истекающие продукты с учетом поиска и категории
    final filteredExpiringItems = _filterExpiringItems(expiringItems);

    return Column(
      children: [
        // Поиск на обеих вкладках
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _tabController.index == 0 ? 'Поиск продуктов' : 'Поиск истекающих продуктов',
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

        // Фильтр категорий (теперь динамический для каждой вкладки)
        if (categoryNames.length > 1)
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
              _buildProductsList(filteredItems, isMainTab: true),
              _buildProductsList(filteredExpiringItems, isMainTab: false),
            ],
          ),
        ),
      ],
    );
  }


  List<String> _getUniqueCategories(List<RefrigeratorItem> items) {
    final categories = <String>{};

    for (var item in items) {
      if (item.ingredient?.type?.name != null) {
        categories.add(item.ingredient!.type!.name);
      }
    }

    return ['Все', ...categories.toList()..sort()];
  }

  Widget _buildProductsList(List<RefrigeratorItem> products, {required bool isMainTab}) {
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
              isMainTab
                  ? 'Ваш холодильник пуст'
                  : 'Нет продуктов с истекающим сроком годности',
              style: TextStyle(color: Colors.grey[600]),
            ),
            // ИСПРАВЛЕНИЕ: Кнопка добавить всегда показывается для пустого списка
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
      isScrollControlled: true, // Важно для контроля размера
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      // Добавляем ограничение максимальной высоты
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) {
        final daysLeft = item.daysLeft;
        final ingredient = item.ingredient;

        return Container(
          padding: const EdgeInsets.all(24),
          // Делаем содержимое прокручиваемым
          child: SingleChildScrollView(
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

                  // Добавляем отображение аллергенов
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

                SizedBox(
                  width: double.infinity,
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

                // Добавляем отступ снизу для избежания обрезания
                const SizedBox(height: 16),
              ],
            ),
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

  // ИСПРАВЛЕНИЕ: Исправлена сигнатура метода
  void _showStatsDialog(RefrigeratorStats stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика холодильника'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatsRow(
              'Всего продуктов:',
              stats.totalItems.toString(),
              Icons.inventory,
            ),
            const SizedBox(height: 16),
            _buildStatsRow(
              'Скоро истекают:',
              stats.expiringSoon.toString(),
              Icons.warning,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildStatsRow(
              'Просрочены:',
              stats.expired.toString(),
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