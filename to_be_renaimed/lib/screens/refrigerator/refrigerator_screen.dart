import 'package:flutter/material.dart';

class RefrigeratorScreen extends StatefulWidget {
  const RefrigeratorScreen({Key? key}) : super(key: key);

  @override
  State<RefrigeratorScreen> createState() => _RefrigeratorScreenState();
}

class _RefrigeratorScreenState extends State<RefrigeratorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Все';

  // Симуляция категорий продуктов
  final List<String> _categories = [
    'Все',
    'Овощи',
    'Фрукты',
    'Мясо',
    'Молочные',
    'Крупы',
    'Напитки',
  ];

  // Симуляция продуктов в холодильнике
  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'name': 'Помидоры',
      'quantity': '500',
      'quantityType': 'grams',
      'category': 'Овощи',
      'expiryDate': '2025-05-05',
      'daysLeft': 6,
    },
    {
      'id': 2,
      'name': 'Огурцы',
      'quantity': '300',
      'quantityType': 'grams',
      'category': 'Овощи',
      'expiryDate': '2025-05-02',
      'daysLeft': 3,
    },
    {
      'id': 3,
      'name': 'Молоко',
      'quantity': '1',
      'quantityType': 'liters',
      'category': 'Молочные',
      'expiryDate': '2025-05-01',
      'daysLeft': 2,
    },
    {
      'id': 4,
      'name': 'Яблоки',
      'quantity': '5',
      'quantityType': 'pieces',
      'category': 'Фрукты',
      'expiryDate': '2025-05-10',
      'daysLeft': 11,
    },
    {
      'id': 5,
      'name': 'Куриное филе',
      'quantity': '600',
      'quantityType': 'grams',
      'category': 'Мясо',
      'expiryDate': '2025-05-03',
      'daysLeft': 4,
    },
    {
      'id': 6,
      'name': 'Рис',
      'quantity': '500',
      'quantityType': 'grams',
      'category': 'Крупы',
      'expiryDate': '2025-12-31',
      'daysLeft': 246,
    },
    {
      'id': 7,
      'name': 'Апельсиновый сок',
      'quantity': '1.5',
      'quantityType': 'liters',
      'category': 'Напитки',
      'expiryDate': '2025-05-15',
      'daysLeft': 16,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((product) {
      // Фильтрация по поиску
      final matchesSearch = _searchQuery.isEmpty ||
          product['name'].toLowerCase().contains(_searchQuery.toLowerCase());

      // Фильтрация по категории
      final matchesCategory = _selectedCategory == 'Все' ||
          product['category'] == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Map<String, dynamic>> get _expiringProducts {
    return _products
        .where((product) => product['daysLeft'] <= 3)
        .toList()
      ..sort((a, b) => a['daysLeft'].compareTo(b['daysLeft']));
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Column(
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

          // Фильтр категорий (только для вкладки "Все продукты")
          if (_tabController.index == 0)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
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
                // Вкладка "Все продукты"
                _buildProductsList(_filteredProducts),

                // Вкладка "Скоро истекают"
                _buildProductsList(_expiringProducts),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'btn1',
            onPressed: () {
              Navigator.pushNamed(context, '/refrigerator/barcode-scanner');
            },
            backgroundColor: Colors.orange,
            mini: true,
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'btn2',
            onPressed: () {
              Navigator.pushNamed(context, '/refrigerator/add-product');
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<Map<String, dynamic>> products) {
    return products.isEmpty
        ? Center(
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
                Navigator.pushNamed(context, '/refrigerator/add-product');
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить продукты'),
            ),
          ],
        ],
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        // Определение цвета индикатора срока годности
        Color statusColor;
        if (product['daysLeft'] <= 0) {
          statusColor = Colors.red;
        } else if (product['daysLeft'] <= 3) {
          statusColor = Colors.orange;
        } else if (product['daysLeft'] <= 7) {
          statusColor = Colors.yellow;
        } else {
          statusColor = Colors.green;
        }

        return Dismissible(
          key: Key(product['id'].toString()),
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
            setState(() {
              _products.removeWhere((item) => item['id'] == product['id']);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product['name']} удален из холодильника'),
                action: SnackBarAction(
                  label: 'Отменить',
                  onPressed: () {
                    setState(() {
                      _products.add(product);
                    });
                  },
                ),
              ),
            );
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
                child: Icon(
                  Icons.kitchen,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(product['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product['quantity']} ${_getQuantityTypeText(product['quantityType'])}',
                  ),
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
                        product['daysLeft'] <= 0
                            ? 'Просрочено'
                            : 'Осталось ${product['daysLeft']} дн.',
                        style: TextStyle(
                          color: product['daysLeft'] <= 0 ? Colors.red : null,
                          fontWeight: product['daysLeft'] <= 3
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
                  // Редактирование продукта
                  Navigator.pushNamed(
                    context,
                    '/refrigerator/add-product',
                    arguments: {'productId': product['id']},
                  );
                },
              ),
              onTap: () {
                // Детальная информация о продукте
                _showProductDetails(context, product);
              },
            ),
          ),
        );
      },
    );
  }

  String _getQuantityTypeText(String quantityType) {
    switch (quantityType) {
      case 'grams':
        return 'г';
      case 'milliliters':
        return 'мл';
      case 'liters':
        return 'л';
      case 'pieces':
        return 'шт';
      case 'tablespoons':
        return 'ст. л.';
      case 'teaspoons':
        return 'ч. л.';
      case 'cups':
        return 'стак.';
      default:
        return '';
    }
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product['name'],
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                context,
                'Категория:',
                product['category'],
              ),
              _buildDetailRow(
                context,
                'Количество:',
                '${product['quantity']} ${_getQuantityTypeText(product['quantityType'])}',
              ),
              _buildDetailRow(
                context,
                'Срок годности:',
                product['expiryDate'],
              ),
              _buildDetailRow(
                context,
                'Осталось дней:',
                '${product['daysLeft']}',
                valueColor: product['daysLeft'] <= 0
                    ? Colors.red
                    : product['daysLeft'] <= 3
                    ? Colors.orange
                    : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/refrigerator/add-product',
                          arguments: {'productId': product['id']},
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Редактировать'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/recipes',
                          arguments: {'ingredientId': product['id']},
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
}