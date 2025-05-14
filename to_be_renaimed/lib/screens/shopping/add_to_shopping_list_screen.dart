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
  final _typeSearchController = TextEditingController();
  QuantityType _quantityType = QuantityType.grams;
  IngredientType? _selectedIngredientType;
  bool _isLoading = false;
  bool _isSearchingTypes = false;
  String? _errorMessage;

  // Все допустимые единицы измерения
  final List<QuantityType> _quantityTypes = [
    QuantityType.grams,
    QuantityType.milliliters,
    QuantityType.liters,
    QuantityType.pieces,
  ];

  // Все типы ингредиентов и результаты поиска
  List<IngredientType> _allTypes = [];
  List<IngredientType> _searchResults = [];

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
      // Загружаем типы ингредиентов из репозитория
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      _allTypes = await dataRepository.getAllIngredientTypes();

      // Сортируем по имени
      _allTypes.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки типов ингредиентов: $e';
        _isLoading = false;
      });
    }
  }

  // Функция поиска типов ингредиентов
  void _searchTypes(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingTypes = false;
      });
      return;
    }

    setState(() {
      _isSearchingTypes = true;
      _searchResults = _allTypes
          .where((type) => type.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _typeSearchController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    // Скрываем клавиатуру
    FocusScope.of(context).unfocus();

    // Валидация формы
    if (_formKey.currentState!.validate()) {
      if (_selectedIngredientType == null) {
        setState(() {
          _errorMessage = 'Пожалуйста, выберите тип продукта';
        });
        return;
      }

      // Получаем количество
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
        // Добавляем элемент в список покупок через репозиторий
        final dataRepository = Provider.of<DataRepository>(context, listen: false);
        final newItem = await dataRepository.addShoppingListItem(
          ingredientTypeId: _selectedIngredientType!.id,
          quantity: quantity,
          quantityType: _quantityType,
        );

        if (newItem != null && mounted) {
          Navigator.pop(context, true); // Возвращаем true для индикации успеха
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Продукт добавлен в список покупок')),
          );
        } else if (mounted) {
          setState(() {
            _errorMessage = 'Ошибка при добавлении продукта';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Ошибка: $e';
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
      body: _isLoading && _allTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Сообщение об ошибке, если есть
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

              // Поле поиска типа
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
                  suffixIcon: _selectedIngredientType != null
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedIngredientType = null;
                        _typeSearchController.clear();
                        _searchResults = [];
                        _isSearchingTypes = false;
                      });
                    },
                  )
                      : null,
                ),
                onChanged: _searchTypes,
                validator: (value) {
                  if (_selectedIngredientType == null) {
                    return 'Пожалуйста, выберите тип продукта';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Результаты поиска
              if (_searchResults.isNotEmpty && _isSearchingTypes)
                Container(
                  height: 200,
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
                            _selectedIngredientType = type;
                            _typeSearchController.text = type.name;
                            _searchResults = [];
                            _isSearchingTypes = false;
                          });
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // Секция количества
              Text(
                'Шаг 2: Укажите количество',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Поле количества
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
                  // Выпадающий список единиц измерения
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<QuantityType>(
                      value: _quantityType,
                      decoration: const InputDecoration(
                        labelText: 'Единица измерения',
                        prefixIcon: Icon(Icons.straighten),
                        // Добавляем padding для лучшего отображения
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      // Увеличиваем размер по ширине
                      isExpanded: true,
                      items: _quantityTypes.map((type) {
                        return DropdownMenuItem<QuantityType>(
                          value: type,
                          child: Text(
                            type.toDisplayString(),
                            // Стиль с меньшим размером шрифта
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

              const SizedBox(height: 32),

              // Кнопка добавления
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addItem,
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
            ],
          ),
        ),
      ),
    );
  }
}