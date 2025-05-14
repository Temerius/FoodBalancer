// lib/screens/shopping/add_to_shopping_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/data_repository.dart';
import '../../models/enums.dart';
import '../../models/ingredient_type.dart';

class AddToShoppingListScreen extends StatefulWidget {
  const AddToShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<AddToShoppingListScreen> createState() => _AddToShoppingListScreenState();
}

class _AddToShoppingListScreenState extends State<AddToShoppingListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  QuantityType _quantityType = QuantityType.grams;
  IngredientType? _selectedIngredientType;
  bool _isLoading = false;
  String? _errorMessage;

  // Options for quantity types dropdown
  final List<QuantityType> _quantityTypes = [
    QuantityType.grams,
    QuantityType.milliliters,
    QuantityType.liters,
    QuantityType.pieces,
    QuantityType.tablespoons,
    QuantityType.teaspoons,
    QuantityType.cups,
  ];

  // All ingredient types
  List<IngredientType> _ingredientTypes = [];

  @override
  void initState() {
    super.initState();
    _loadIngredientTypes();
  }

  Future<void> _loadIngredientTypes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load ingredient types from repository
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      _ingredientTypes = await dataRepository.getAllIngredientTypes();

      // Sort ingredient types by name
      _ingredientTypes.sort((a, b) => a.name.compareTo(b.name));

      // Set default selected ingredient type if list is not empty
      if (_ingredientTypes.isNotEmpty && _selectedIngredientType == null) {
        _selectedIngredientType = _ingredientTypes.first;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки типов ингредиентов: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    if (_formKey.currentState!.validate()) {
      if (_selectedIngredientType == null) {
        setState(() {
          _errorMessage = 'Пожалуйста, выберите ингредиент';
        });
        return;
      }

      // Get quantity
      final quantity = int.tryParse(_quantityController.text);
      if (quantity == null || quantity <= 0) {
        setState(() {
          _errorMessage = 'Пожалуйста, введите корректное количество';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Add item to shopping list
        final dataRepository = Provider.of<DataRepository>(context, listen: false);
        final newItem = await dataRepository.addShoppingListItem(
          ingredientTypeId: _selectedIngredientType!.id,
          quantity: quantity,
          quantityType: _quantityType,
        );

        if (newItem != null && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Продукт добавлен в список покупок')),
          );
        } else if (mounted) {
          setState(() {
            _errorMessage = 'Ошибка при добавлении продукта';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Ошибка: $e';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавление в список покупок'),
      ),
      body: _isLoading && _ingredientTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Ingredient type selection
              if (_ingredientTypes.isEmpty) ...[
                const Center(
                  child: Text(
                    'Нет доступных типов ингредиентов. Пожалуйста, обновите список.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _loadIngredientTypes,
                    child: const Text('Обновить'),
                  ),
                ),
              ] else ...[
                // Ingredient type dropdown
                DropdownButtonFormField<IngredientType>(
                  value: _selectedIngredientType,
                  decoration: const InputDecoration(
                    labelText: 'Тип ингредиента',
                    prefixIcon: Icon(Icons.category),
                    helperText: 'Выберите тип продукта',
                  ),
                  items: _ingredientTypes.map((type) {
                    return DropdownMenuItem<IngredientType>(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedIngredientType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Пожалуйста, выберите тип ингредиента';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quantity and unit of measurement
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
                        items: _quantityTypes.map((type) {
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
              ],

              const SizedBox(height: 32),

              // Add button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || _ingredientTypes.isEmpty ? null : _addItem,
                  icon: _isLoading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)
                  )
                      : const Icon(Icons.add),
                  label: const Text('Добавить в список'),
                ),
              ),

              const SizedBox(height: 16),

              // Barcode scanner button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/refrigerator/barcode-scanner');
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Сканировать штрих-код'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}