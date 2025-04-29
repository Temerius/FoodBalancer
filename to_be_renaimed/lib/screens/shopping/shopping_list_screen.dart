import 'package:flutter/material.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // Симуляция категорий продуктов
  final Map<String, List<Map<String, dynamic>>> _shoppingItems = {
    'Овощи': [
      {'id': 1, 'name': 'Помидоры', 'quantity': '500 г', 'checked': false},
      {'id': 2, 'name': 'Огурцы', 'quantity': '300 г', 'checked': false},
      {'id': 3, 'name': 'Морковь', 'quantity': '400 г', 'checked': true},
    ],
    'Молочные': [
      {'id': 4, 'name': 'Молоко', 'quantity': '1 л', 'checked': false},
      {'id': 5, 'name': 'Творог', 'quantity': '200 г', 'checked': false},
    ],
    'Мясо': [
      {'id': 6, 'name': 'Курица', 'quantity': '1 кг', 'checked': false},
    ],
    'Фрукты': [
      {'id': 7, 'name': 'Яблоки', 'quantity': '5 шт', 'checked': true},
      {'id': 8, 'name': 'Бананы', 'quantity': '1 кг', 'checked': false},
    ],
  };

  // Текущий режим отображения
  bool _showOnlyUnchecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список покупок'),
        actions: [
          // Переключатель режима отображения
          IconButton(
            icon: Icon(_showOnlyUnchecked
                ? Icons.check_box_outline_blank
                : Icons.checklist),
            onPressed: () {
              setState(() {
                _showOnlyUnchecked = !_showOnlyUnchecked;
              });
            },
            tooltip: _showOnlyUnchecked
                ? 'Показать все'
                : 'Показать только невыполненные',
          ),
          // Меню опций
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_checked') {
                _clearCheckedItems();
              } else if (value == 'clear_all') {
                _clearAllItems();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_checked',
                child: Text('Удалить выполненные'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Очистить весь список'),
              ),
            ],
          ),
        ],
      ),
      body: _buildShoppingList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/shopping-list/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildShoppingList() {
    // Проверяем, есть ли продукты
    final allItems = _getAllItems();
    final displayItems = _showOnlyUnchecked
        ? allItems.where((item) => !item['checked']).toList()
        : allItems;

    if (displayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showOnlyUnchecked
                  ? 'Все продукты уже куплены'
                  : 'Ваш список покупок пуст',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/shopping-list/add');
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить продукты'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Прогресс выполнения
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: LinearProgressIndicator(
            value: _getProgress(),
            backgroundColor: Colors.grey[300],
            color: Theme.of(context).colorScheme.primary,
          ),
        ),

        // Статистика выполнения
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Куплено: ${_getCheckedCount()}/${allItems.length}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(_getProgress() * 100).toInt()}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Список продуктов
        Expanded(
          child: _showOnlyUnchecked
              ? _buildFlatList(displayItems)
              : _buildCategorizedList(),
        ),
      ],
    );
  }

  Widget _buildFlatList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildShoppingItem(item);
      },
    );
  }

  Widget _buildCategorizedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shoppingItems.length,
      itemBuilder: (context, index) {
        final category = _shoppingItems.keys.elementAt(index);
        final categoryItems = _shoppingItems[category]!;

        // Пропускаем пустые категории
        if (categoryItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок категории
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Элементы категории
            ...categoryItems.map((item) => _buildShoppingItem(item)).toList(),

            // Разделитель между категориями
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildShoppingItem(Map<String, dynamic> item) {
    return Dismissible(
      key: Key('shopping_item_${item['id']}'),
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
        _removeItem(item['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['name']} удален из списка'),
            action: SnackBarAction(
              label: 'Отменить',
              onPressed: () {
                // Восстановление элемента (в реальном приложении)
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: CheckboxListTile(
          value: item['checked'],
          onChanged: (value) {
            setState(() {
              item['checked'] = value;
            });
          },
          title: Text(
            item['name'],
            style: TextStyle(
              decoration: item['checked'] ? TextDecoration.lineThrough : null,
              color: item['checked'] ? Colors.grey : null,
            ),
          ),
          subtitle: Text(
            item['quantity'],
            style: TextStyle(
              decoration: item['checked'] ? TextDecoration.lineThrough : null,
              color: item['checked'] ? Colors.grey : null,
            ),
          ),
          secondary: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Редактирование элемента
              Navigator.pushNamed(
                context,
                '/shopping-list/add',
                arguments: {'itemId': item['id']},
              );
            },
          ),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAllItems() {
    final List<Map<String, dynamic>> allItems = [];
    for (final categoryItems in _shoppingItems.values) {
      allItems.addAll(categoryItems);
    }
    return allItems;
  }

  double _getProgress() {
    final allItems = _getAllItems();
    if (allItems.isEmpty) return 0.0;

    final checkedCount = allItems.where((item) => item['checked']).length;
    return checkedCount / allItems.length;
  }

  int _getCheckedCount() {
    return _getAllItems().where((item) => item['checked']).length;
  }

  void _removeItem(int id) {
    setState(() {
      for (final category in _shoppingItems.keys) {
        _shoppingItems[category]!.removeWhere((item) => item['id'] == id);
      }
    });
  }

  void _clearCheckedItems() {
    setState(() {
      for (final category in _shoppingItems.keys) {
        _shoppingItems[category]!.removeWhere((item) => item['checked']);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Выполненные покупки удалены')),
    );
  }

  void _clearAllItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить список'),
        content: const Text('Вы уверены, что хотите удалить все продукты из списка покупок?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                for (final category in _shoppingItems.keys) {
                  _shoppingItems[category]!.clear();
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Список покупок очищен')),
              );
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}