// lib/screens/refrigerator/add_product_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/data_repository.dart';
import '../../repositories/repositories/refrigerator_repository.dart';
import '../../models/refrigerator_item.dart';
import '../../models/ingredient.dart';
import '../../models/enums.dart';
import '../../services/refrigerator_service.dart';
import '../../utils/date_formatter.dart';

class AddProductScreen extends StatefulWidget {
  final int? productId;

  const AddProductScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  QuantityType _quantityType = QuantityType.grams;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  Ingredient? _selectedIngredient;
  List<Ingredient> _searchResults = [];
  RefrigeratorItem? _currentItem;

  late RefrigeratorRepository _refrigeratorRepository;

  @override
  void initState() {
    super.initState();

    // Получаем DataRepository для доступа к ApiService
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    final apiService = dataRepository.apiService;
    final refrigeratorService = RefrigeratorService(apiService: apiService);
    _refrigeratorRepository = RefrigeratorRepository(refrigeratorService: refrigeratorService);

    _isEditing = widget.productId != null;

    if (_isEditing) {
      _loadExistingProduct();
    }
  }

  Future<void> _loadExistingProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем данные существующего продукта
      final items = await _refrigeratorRepository.getItems();
      final item = items.firstWhere(
            (item) => item.id == widget.productId,
        orElse: () => throw Exception('Продукт не найден'),
      );

      setState(() {
        _currentItem = item;
        _selectedIngredient = item.ingredient;
        _quantityController.text = item.quantity.toString();
        _quantityType = item.quantityType;

        if (item.ingredient?.expiryDate != null) {
          _expiryDate = item.ingredient!.expiryDate!;
        }

        if (_selectedIngredient != null) {
          _searchController.text = _selectedIngredient!.name;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchIngredients(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _refrigeratorRepository.searchIngredients(query: query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка поиска: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование продукта' : 'Добавление продукта'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Назад'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Поиск и выбор ингредиента
              if (!_isEditing) ...[
                Text(
                  'Выберите продукт',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Поиск продукта',
                    hintText: 'Начните вводить название',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : null,
                  ),
                  validator: (value) {
                    if (_selectedIngredient == null) {
                      return 'Пожалуйста, выберите продукт из списка';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _searchIngredients(value);
                  },
                ),
                const SizedBox(height: 12),

                // Результаты поиска
                if (_searchResults.isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final ingredient = _searchResults[index];
                        return ListTile(
                          leading: ingredient.imageUrl != null
                              ? Image.network(
                            ingredient.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.fastfood),
                          )
                              : const Icon(Icons.fastfood),
                          title: Text(ingredient.name),
                          subtitle: Text(ingredient.type?.name ?? ''),
                          onTap: () {
                            setState(() {
                              _selectedIngredient = ingredient;
                              _searchController.text = ingredient.name;
                              _searchResults = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
              ] else ...[
                // Если редактируем, показываем название продукта
                Text(
                  'Продукт: ${_selectedIngredient?.name ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],

              const SizedBox(height: 24),

              // Количество и единица измерения
              Text(
                'Количество',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Количество',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите количество';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Введите число';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<QuantityType>(
                      value: _quantityType,
                      decoration: const InputDecoration(
                        labelText: 'Единица измерения',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      items: QuantityType.values.map((type) {
                        return DropdownMenuItem<QuantityType>(
                          value: type,
                          child: Text(type.toDisplayString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _quantityType = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Срок годности
              Text(
                'Срок годности',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Срок годности',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormatter.formatDate(_expiryDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Кнопки действий
              Row(
                children: [
                  if (_isEditing)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _deleteProduct,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Удалить',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  if (_isEditing) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveProduct,
                      icon: Icon(_isEditing ? Icons.save : Icons.add),
                      label: Text(_isEditing ? 'Сохранить' : 'Добавить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isEditing && _currentItem != null) {
          // Обновление существующего продукта
          await _refrigeratorRepository.updateItem(
            itemId: _currentItem!.id,
            quantity: int.parse(_quantityController.text),
            quantityType: _quantityType,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Продукт обновлен'),
              ),
            );
          }
        } else {
          // Добавление нового продукта
          if (_selectedIngredient == null) {
            throw Exception('Выберите продукт');
          }

          await _refrigeratorRepository.addItem(
            ingredientId: _selectedIngredient!.id,
            quantity: int.parse(_quantityController.text),
            quantityType: _quantityType,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Продукт добавлен в холодильник'),
              ),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (!_isEditing || _currentItem == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы уверены, что хотите удалить ${_selectedIngredient?.name ?? 'этот продукт'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _refrigeratorRepository.removeItem(_currentItem!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Продукт удален'),
          ),
        );
        Navigator.pop(context);
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}