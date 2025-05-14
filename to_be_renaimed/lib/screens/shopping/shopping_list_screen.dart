
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/enums.dart';
import '../../models/ingredient.dart'; // Используем существующую модель

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  bool _isLoading = false;
  // По умолчанию показываем все элементы
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
      // Загружаем элементы списка покупок из репозитория
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

  // Показываем диалог при нажатии на элемент
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
      // Переходим к сканеру штрих-кода
      if (mounted) {
        // Сразу помечаем элемент как выбранный
        _toggleItemChecked(item, true);

        // Переходим к сканеру штрих-кода
        Navigator.pushNamed(context, '/refrigerator/barcode-scanner')
            .then((_) {
          // Просто перезагружаем данные при возврате
          _loadData();
        });
      }
    } else if (result == 'manual') {
      // Переходим к экрану добавления продукта с предварительно заполненными данными
      if (mounted) {
        // Создаем аргументы для передачи в экран добавления продукта
        final args = {
          'prefill_data': {
            'name': item.name, // Название продукта
            'quantity': item.quantity.toString(), // Количество
            'quantity_type': item.quantityType, // Тип единицы измерения
            'ingredient_type_id': item.ingredientTypeId, // ID типа ингредиента
            'ingredient_type_name': item.ingredientType?.name, // Название типа ингредиента
          },
          'shopping_item_id': item.id // ID элемента списка покупок
        };

        // Открываем экран добавления с данными
        Navigator.pushNamed(
          context,
          '/refrigerator/add-product',
          arguments: args,
        ).then((value) {
          // Когда возвращаемся после добавления продукта вручную, проверяем был ли добавлен продукт
          if (value == true) {
            // Помечаем элемент как выбранный в списке покупок только при успешном добавлении
            _toggleItemChecked(item, true);
          }
          _loadData(); // Перезагружаем данные списка покупок
        });
      }
    } else if (result == 'toggle') {
      // Переключаем состояние выбранности
      _toggleItemChecked(item, !item.isChecked);
    }
  }

  // Переключаем статус выбранности элемента
  Future<void> _toggleItemChecked(ShoppingListItem item, bool isChecked) async {
    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      // Используем репозиторий для обновления элемента в кэше
      await dataRepository.updateShoppingListItem(
        itemId: item.id!,
        isChecked: isChecked,
      );

      // Обновляем локальное состояние
      setState(() {
        item.isChecked = isChecked;
      });

      // Если показываем только невыбранные элементы и этот элемент был только что выбран,
      // удаляем его из списка
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

  // Удаляем отдельный элемент из списка покупок
  Future<void> _removeItem(ShoppingListItem item) async {
    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      // Удаляем с сервера через репозиторий (который также обновляет кэш)
      final success = await dataRepository.removeShoppingListItem(item.id!);

      if (success && mounted) {
        // Удаляем из локального состояния, если успешно
        setState(() {
          _items.remove(item);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} удален из списка'),
            action: SnackBarAction(
              label: 'Отменить',
              onPressed: () {
                // Здесь можно добавить функцию восстановления элемента
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

  // Удаляем все выбранные элементы
  Future<void> _clearCheckedItems() async {
    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);

      // Это удалит выбранные элементы с сервера и из кэша
      final success = await dataRepository.clearCheckedShoppingListItems();

      if (success && mounted) {
        // Обновляем локальное состояние - удаляем выбранные элементы
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

  // Очищаем весь список покупок
  Future<void> _clearAllItems() async {
    // Показываем диалог подтверждения
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

        // Это удалит все элементы и с сервера, и из кэша
        final success = await dataRepository.clearAllShoppingListItems();

        if (success && mounted) {
          // Очищаем локальное состояние
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
          // Переключатель режима отображения
          IconButton(
            icon: Icon(_showOnlyUnchecked
                ? Icons.check_box_outline_blank
                : Icons.checklist),
            onPressed: () {
              setState(() {
                _showOnlyUnchecked = !_showOnlyUnchecked;
                _loadData(); // Перезагружаем данные с новым фильтром
              });
            },
            tooltip: _showOnlyUnchecked
                ? 'Показать все'
                : 'Показать только невыбранные',
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
          // Переход к экрану добавления элемента
          Navigator.pushNamed(
              context,
              '/shopping-list/add'
          ).then((_) => _loadData()); // Перезагружаем данные после возврата
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildShoppingList() {
    // Показываем сообщение об ошибке, если оно есть
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

    // Показываем пустое состояние, если нет элементов
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

    // Получаем все элементы из репозитория для расчета прогресса
    final dataRepository = Provider.of<DataRepository>(context);
    final allItems = dataRepository.shoppingListItems;

    // Рассчитываем прогресс
    final checkedCount = allItems.where((item) => item.isChecked).length;
    final progress = allItems.isEmpty ? 0.0 : checkedCount / allItems.length;

    // Строим список с индикаторами прогресса
    return Column(
      children: [
        // Индикатор прогресса
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: Theme.of(context).colorScheme.primary,
          ),
        ),

        // Статистика прогресса
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

        // Элементы списка покупок
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

  // Элемент списка покупок с правильным зачеркиванием и взаимодействием
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
                // Чекбокс
                Checkbox(
                  value: item.isChecked,
                  onChanged: (value) {
                    if (value != null) {
                      _toggleItemChecked(item, value);
                    }
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                // Контент
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
                // Иконка дополнительных действий
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