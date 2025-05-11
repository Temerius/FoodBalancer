// lib/screens/refrigerator/add_product_screen.dart - Improved version
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/refrigerator_item.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_type.dart';
import '../../models/allergen.dart';
import '../../models/enums.dart';
import '../../utils/date_formatter.dart';

class AddProductScreen extends StatefulWidget {
  final int? productId;

  const AddProductScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeSearchController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  QuantityType _quantityType = QuantityType.grams;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSearchingTypes = false;
  String? _error;

  IngredientType? _selectedType;
  List<IngredientType> _searchResults = [];
  List<IngredientType> _allTypes = [];
  RefrigeratorItem? _currentItem;
  List<Allergen> _allAllergens = [];
  List<Allergen> _selectedAllergens = [];

  DataRepository? _dataRepository;

  // Ограничиваем единицы измерения только нужными
  final List<QuantityType> _allowedQuantityTypes = [
    QuantityType.grams,
    QuantityType.milliliters,
    QuantityType.liters,
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.productId != null;

    // Задержка инициализации до получения контекста
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    _dataRepository = Provider.of<DataRepository>(context, listen: false);
    await _loadIngredientTypes();
    await _loadAllergens();

    if (_isEditing) {
      await _loadExistingProduct();
    }
  }

  Future<void> _loadIngredientTypes() async {
    try {
      final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

      // Загружаем все типы ингредиентов из API через DataRepository
      final response = await dataRepository.apiService.get('/api/ingredient-types/?limit=1000');

      if (response['results'] != null) {
        setState(() {
          _allTypes = (response['results'] as List)
              .map((json) => IngredientType.fromJson(json))
              .toList();
          _searchResults = _allTypes;
        });
      }
    } catch (e) {
      print('Error loading ingredient types: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки типов продуктов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadAllergens() async {
    try {
      final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);
      final allergens = await dataRepository.getAllAllergens();

      setState(() {
        _allAllergens = allergens.map((allergen) =>
            allergen.copyWith(isSelected: false)
        ).toList();
      });
    } catch (e) {
      print('Error loading allergens: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки аллергенов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadExistingProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

      // Получаем продукты из DataRepository
      final items = dataRepository.refrigeratorItems;

      RefrigeratorItem? item;
      if (items.isEmpty) {
        // Если список пустой, загружаем из API
        await dataRepository.getRefrigeratorItems();
        final updatedItems = dataRepository.refrigeratorItems;
        item = updatedItems.firstWhere(
              (item) => item.id == widget.productId,
          orElse: () => throw Exception('Продукт не найден'),
        );
      } else {
        item = items.firstWhere(
              (item) => item.id == widget.productId,
          orElse: () => throw Exception('Продукт не найден'),
        );
      }

      setState(() {
        _currentItem = item;
        _quantityController.text = item!.quantity.toString();
        _quantityType = item.quantityType;

        if (item.ingredient?.expiryDate != null) {
          _expiryDate = item.ingredient!.expiryDate!;
        }

        if (item.ingredient?.type != null) {
          _selectedType = item.ingredient!.type;
          _typeSearchController.text = _selectedType!.name;
        }

        if (item.ingredient != null) {
          _productNameController.text = item.ingredient!.name;
          _caloriesController.text = item.ingredient!.calories.toString();
          _proteinController.text = item.ingredient!.protein.toString();
          _fatController.text = item.ingredient!.fat.toString();
          _carbsController.text = item.ingredient!.carbs.toString();
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

  void _searchTypes(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _allTypes;
      });
      return;
    }

    setState(() {
      _searchResults = _allTypes
          .where((type) => type.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleAllergen(Allergen allergen) {
    setState(() {
      allergen.isSelected = !allergen.isSelected;
      if (allergen.isSelected) {
        _selectedAllergens.add(allergen);
      } else {
        _selectedAllergens.remove(allergen);
      }
    });
  }

  @override
  void dispose() {
    print('AddProductScreen: dispose called');
    _typeSearchController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('AddProductScreen: build called');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование продукта' : 'Добавление продукта'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            print('AddProductScreen: Close button pressed');
            Navigator.of(context).pop(false);
          },
        ),
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
          : Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Шаг 1: Выбор типа продукта
                  Text(
                    'Шаг 1: Выберите тип продукта',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _typeSearchController,
                    decoration: InputDecoration(
                      labelText: 'Тип продукта',
                      hintText: 'Например: Молочные продукты, Овощи',
                      prefixIcon: const Icon(Icons.category),
                      suffixIcon: _selectedType != null
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedType = null;
                            _typeSearchController.clear();
                            _searchResults = _allTypes;
                          });
                        },
                      )
                          : null,
                    ),
                    enabled: !_isEditing,
                    onChanged: _searchTypes,
                    validator: (value) {
                      if (_selectedType == null) {
                        return 'Пожалуйста, выберите тип продукта';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Результаты поиска типов
                  if (_searchResults.isNotEmpty && _selectedType == null)
                    Container(
                      height: 200, // Увеличили высоту
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final type = _searchResults[index];
                          return ListTile(
                            leading: type.imageUrl != null
                                ? Image.network(
                              type.imageUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.category),
                            )
                                : const Icon(Icons.category),
                            title: Text(type.name),
                            onTap: () {
                              setState(() {
                                _selectedType = type;
                                _typeSearchController.text = type.name;
                                _searchResults = [];
                              });
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Шаг 2: Название продукта
                  Text(
                    'Шаг 2: Введите название продукта',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _productNameController,
                    decoration: InputDecoration(
                      labelText: 'Название продукта',
                      hintText: 'Например: Молоко 3.2%, Помидоры черри',
                      prefixIcon: const Icon(Icons.fastfood),
                    ),
                    enabled: _selectedType != null || _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите название продукта';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Шаг 3: Пищевая ценность
                  Text(
                    'Шаг 3: Пищевая ценность (на 100г/100мл)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _caloriesController,
                          decoration: const InputDecoration(
                            labelText: 'Калории (ккал)',
                            prefixIcon: Icon(Icons.local_fire_department),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (int.tryParse(value) == null) {
                                return 'Число';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _proteinController,
                          decoration: const InputDecoration(
                            labelText: 'Белки (г)',
                            prefixIcon: Icon(Icons.fitness_center),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (int.tryParse(value) == null) {
                                return 'Число';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fatController,
                          decoration: const InputDecoration(
                            labelText: 'Жиры (г)',
                            prefixIcon: Icon(Icons.opacity),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (int.tryParse(value) == null) {
                                return 'Число';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _carbsController,
                          decoration: const InputDecoration(
                            labelText: 'Углеводы (г)',
                            prefixIcon: Icon(Icons.grain),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (int.tryParse(value) == null) {
                                return 'Число';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Шаг 4: Аллергены
                  Text(
                    'Шаг 4: Выберите аллергены',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_allAllergens.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _allAllergens.length,
                        itemBuilder: (context, index) {
                          final allergen = _allAllergens[index];
                          return CheckboxListTile(
                            title: Text(allergen.name),
                            value: allergen.isSelected,
                            onChanged: (bool? value) {
                              _toggleAllergen(allergen);
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Шаг 5: Количество и единица измерения
                  Text(
                    'Шаг 5: Укажите количество',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Поле для количества
                      SizedBox(
                        width: 120, // Фиксированная ширина
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
                      // Выпадающий список единиц измерения
                      Expanded(
                        child: DropdownButtonFormField<QuantityType>(
                          value: _quantityType,
                          decoration: const InputDecoration(
                            labelText: 'Единица измерения',
                            prefixIcon: Icon(Icons.straighten),
                            // Добавляем contentPadding для лучшего отображения
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          // Уменьшаем padding для элементов списка
                          isExpanded: true,
                          items: _allowedQuantityTypes.map((type) {
                            return DropdownMenuItem<QuantityType>(
                              value: type,
                              child: Text(
                                type.toDisplayString(),
                                // Добавляем стиль с меньшим размером шрифта
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
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

                  // Шаг 6: Срок годности
                  Text(
                    'Шаг 6: Укажите срок годности',
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
                  const SizedBox(height: 24), // Дополнительный отступ внизу
                ]),
              ),
            ),
          ],
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
    print('_saveProduct: Starting save process');

    if (_formKey.currentState!.validate()) {
      print('_saveProduct: Form validation passed');

      setState(() {
        _isLoading = true;
      });

      try {
        final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

        if (_isEditing && _currentItem != null) {
          print('_saveProduct: Updating existing product');

          // Обновление существующего продукта
          final updatedItem = await dataRepository.updateRefrigeratorItem(
            itemId: _currentItem!.id,
            quantity: int.parse(_quantityController.text),
            quantityType: _quantityType,
          );

          if (updatedItem != null && mounted) {
            print('_saveProduct: Showing success snackbar for update');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Продукт обновлен'),
              ),
            );
            print('_saveProduct: Navigating back with result=true for update');
            Navigator.pop(context, true);
          }
        } else {
          print('_saveProduct: Adding new product');

          // Добавление нового продукта
          if (_selectedType == null) {
            print('_saveProduct: Error - no type selected');
            throw Exception('Выберите тип продукта');
          }

          final selectedAllergenIds = <int>[];
          for (var allergen in _allAllergens) {
            if (allergen.isSelected) {
              print('Selected allergen: ${allergen.id} - ${allergen.name}');
              selectedAllergenIds.add(allergen.id);
            }
          }

          print('Final allergen IDs to send: $selectedAllergenIds');
          // Получаем аллергены


          final newIngredientResponse = await dataRepository.apiService.post('/api/ingredients/', {
            'ing_name': _productNameController.text,
            'ing_exp_date': _expiryDate.toIso8601String().split('T')[0],
            'ing_weight': 100,
            'ing_calories': int.tryParse(_caloriesController.text) ?? 0,
            'ing_protein': int.tryParse(_proteinController.text) ?? 0,
            'ing_fat': int.tryParse(_fatController.text) ?? 0,
            'ing_hydrates': int.tryParse(_carbsController.text) ?? 0,
            'ing_igt_id': _selectedType!.id,
            'allergen_ids': selectedAllergenIds,
          });

          print('API Response: $newIngredientResponse');

          final ingredientId = newIngredientResponse['ing_id'];
          print('_saveProduct: New ingredient created with id=$ingredientId');

          // Добавляем продукт в холодильник
          print('_saveProduct: Adding product to refrigerator');
          final addedItem = await dataRepository.addRefrigeratorItem(
            ingredientId: ingredientId,
            quantity: int.parse(_quantityController.text),
            quantityType: _quantityType,
          );

          if (addedItem != null && mounted) {
            print('_saveProduct: Showing success snackbar for add');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_productNameController.text} добавлен в холодильник'),
              ),
            );
            print('_saveProduct: Navigating back with result=true for add');
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        print('_saveProduct: Error occurred - $e');
        print('_saveProduct: Stack trace - ${StackTrace.current}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          print('_saveProduct: Save process completed, _isLoading set to false');
        }
      }
    } else {
      print('_saveProduct: Form validation failed');
    }
  }

  Future<void> _deleteProduct() async {
    if (!_isEditing || _currentItem == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы уверены, что хотите удалить ${_productNameController.text}?'),
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
      final dataRepository = _dataRepository ?? Provider.of<DataRepository>(context, listen: false);

      final success = await dataRepository.removeRefrigeratorItem(_currentItem!.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Продукт удален'),
          ),
        );
        Navigator.pop(context, true);
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