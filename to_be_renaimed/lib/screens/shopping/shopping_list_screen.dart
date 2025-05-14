// lib/screens/shopping/shopping_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/enums.dart';
import '../../models/ingredient.dart'; // Using the existing model

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  bool _isLoading = false;
  // Show only unchecked items by default
  bool _showOnlyUnchecked = true;
  String? _errorMessage;
  List<ShoppingListItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Load shopping list items
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final items = await dataRepository.getShoppingListItems(
        onlyUnchecked: _showOnlyUnchecked,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _items = items;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки данных: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleItemChecked(ShoppingListItem item) async {
    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      await dataRepository.updateShoppingListItem(
        itemId: item.id!,
        isChecked: !item.isChecked,
      );

      // Update local state
      setState(() {
        item.isChecked = !item.isChecked;
      });

      // If we're showing only unchecked items and this item was just checked,
      // remove it from the list
      if (_showOnlyUnchecked && item.isChecked) {
        setState(() {
          _items.remove(item);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления элемента: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(ShoppingListItem item) async {
    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final success = await dataRepository.removeShoppingListItem(item.id!);

      if (success && mounted) {
        // Remove from local state
        setState(() {
          _items.remove(item);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} удален из списка'),
            action: SnackBarAction(
              label: 'Отменить',
              onPressed: () {
                // Here you would re-add the item if possible
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления элемента: $e')),
        );
      }
    }
  }

  Future<void> _clearCheckedItems() async {
    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final success = await dataRepository.clearCheckedShoppingListItems();

      if (success && mounted) {
        // Update local state - remove checked items
        setState(() {
          _items.removeWhere((item) => item.isChecked);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выполненные покупки удалены')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления выполненных покупок: $e')),
        );
      }
    }
  }

  Future<void> _clearAllItems() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить список'),
        content: const Text('Вы уверены, что хотите удалить все продукты из списка покупок?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dataRepository = Provider.of<DataRepository>(context, listen: false);
        final success = await dataRepository.clearAllShoppingListItems();

        if (success && mounted) {
          // Clear local state
          setState(() {
            _items.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Список покупок очищен')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка очистки списка покупок: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список покупок'),
        actions: [
          // Toggle display mode
          IconButton(
            icon: Icon(_showOnlyUnchecked
                ? Icons.check_box_outline_blank
                : Icons.checklist),
            onPressed: () {
              setState(() {
                _showOnlyUnchecked = !_showOnlyUnchecked;
                _loadData(); // Reload data with new filter
              });
            },
            tooltip: _showOnlyUnchecked
                ? 'Показать все'
                : 'Показать только невыполненные',
          ),
          // Options menu
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildShoppingList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add item screen
          Navigator.pushNamed(
              context,
              '/shopping-list/add'
          ).then((_) => _loadData()); // Reload data after returning from add screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildShoppingList() {
    // Show error message if there is one
    if (_errorMessage != null) {
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
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Show empty state if there are no items
    if (_items.isEmpty) {
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
                Navigator.pushNamed(
                    context,
                    '/shopping-list/add'
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить продукты'),
            ),
          ],
        ),
      );
    }

    // Get all items from the repository to calculate progress
    final allItems = [..._items];
    if (_showOnlyUnchecked) {
      // Add checked items from repo if we need them for progress calculation
      final dataRepository = Provider.of<DataRepository>(context);
      final repoItems = dataRepository.shoppingListItems;

      // Add checked items that aren't in our current list
      for (var repoItem in repoItems) {
        if (repoItem.isChecked && !_items.any((item) => item.id == repoItem.id)) {
          allItems.add(repoItem);
        }
      }
    }

    // Calculate progress
    final checkedCount = allItems.where((item) => item.isChecked).length;
    final progress = allItems.isEmpty ? 0.0 : checkedCount / allItems.length;

    // Build the list with progress indicators
    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: Theme.of(context).colorScheme.primary,
          ),
        ),

        // Progress statistics
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Куплено: $checkedCount/${allItems.length}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Shopping list items
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildShoppingItem(item);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingItem(ShoppingListItem item) {
    return Dismissible(
      key: Key('shopping_item_${item.id}'),
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
        margin: const EdgeInsets.only(bottom: 8),
        child: CheckboxListTile(
          value: item.isChecked,
          onChanged: (value) {
            _toggleItemChecked(item);
          },
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              color: item.isChecked ? Colors.grey : null,
            ),
          ),
          subtitle: Text(
            item.formattedQuantity,
            style: TextStyle(
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              color: item.isChecked ? Colors.grey : null,
            ),
          ),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}