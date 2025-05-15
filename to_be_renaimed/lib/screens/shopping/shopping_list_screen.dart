
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/enums.dart';
import '../../models/ingredient.dart'; 

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  bool _isLoading = false;
  
  bool _showOnlyUnchecked = false;
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
      
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final items = await dataRepository.getShoppingListItems(
        onlyUnchecked: _showOnlyUnchecked,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки данных: $e';
          _isLoading = false;
        });
      }
    }
  }

  
  Future<void> _onItemTap(ShoppingListItem item) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите действие'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.formattedQuantity,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Что вы хотите сделать?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'scan'),
            child: const Text('Сканировать штрих-код'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: const Text('Добавить вручную'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'toggle'),
            child: Text(item.isChecked ? 'Отметить как не куплено' : 'Отметить как куплено'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (result == 'scan') {
      
      if (mounted) {
        
        _toggleItemChecked(item, true);

        
        Navigator.pushNamed(context, '/refrigerator/barcode-scanner')
            .then((_) {
          
          _loadData();
        });
      }
    } else if (result == 'manual') {
      
      if (mounted) {
        
        final args = {
          'prefill_data': {
            'name': item.name, 
            'quantity': item.quantity.toString(), 
            'quantity_type': item.quantityType, 
            'ingredient_type_id': item.ingredientTypeId, 
            'ingredient_type_name': item.ingredientType?.name, 
          },
          'shopping_item_id': item.id 
        };

        
        Navigator.pushNamed(
          context,
          '/refrigerator/add-product',
          arguments: args,
        ).then((value) {
          
          if (value == true) {
            
            _toggleItemChecked(item, true);
          }
          _loadData(); 
        });
      }
    } else if (result == 'toggle') {
      
      _toggleItemChecked(item, !item.isChecked);
    }
  }

  
  Future<void> _toggleItemChecked(ShoppingListItem item, bool isChecked) async {
    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      
      await dataRepository.updateShoppingListItem(
        itemId: item.id!,
        isChecked: isChecked,
      );

      
      setState(() {
        item.isChecked = isChecked;
      });

      
      
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
        
        setState(() {
          _items.remove(item);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} удален из списка'),
            action: SnackBarAction(
              label: 'Отменить',
              onPressed: () {
                
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
          
          IconButton(
            icon: Icon(_showOnlyUnchecked
                ? Icons.check_box_outline_blank
                : Icons.checklist),
            onPressed: () {
              setState(() {
                _showOnlyUnchecked = !_showOnlyUnchecked;
                _loadData(); 
              });
            },
            tooltip: _showOnlyUnchecked
                ? 'Показать все'
                : 'Показать только невыбранные',
          ),
          
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
                child: Text('Удалить выбранные'),
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
          
          Navigator.pushNamed(
              context,
              '/shopping-list/add'
          ).then((_) => _loadData()); 
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildShoppingList() {
    
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

    
    final dataRepository = Provider.of<DataRepository>(context);
    final allItems = dataRepository.shoppingListItems;

    
    final checkedCount = allItems.where((item) => item.isChecked).length;
    final progress = allItems.isEmpty ? 0.0 : checkedCount / allItems.length;

    
    return Column(
      children: [
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: Theme.of(context).colorScheme.primary,
          ),
        ),

        
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
        child: InkWell(
          onTap: () => _onItemTap(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              children: [
                
                Checkbox(
                  value: item.isChecked,
                  onChanged: (value) {
                    if (value != null) {
                      _toggleItemChecked(item, value);
                    }
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          decoration: item.isChecked ? TextDecoration.lineThrough : null,
                          color: item.isChecked ? Colors.grey : null,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.formattedQuantity,
                        style: TextStyle(
                          decoration: item.isChecked ? TextDecoration.lineThrough : null,
                          color: item.isChecked ? Colors.grey : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _onItemTap(item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}