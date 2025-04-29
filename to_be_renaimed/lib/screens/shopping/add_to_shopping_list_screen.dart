import 'package:flutter/material.dart';

class AddToShoppingListScreen extends StatefulWidget {
  final int? itemId;

  const AddToShoppingListScreen({Key? key, this.itemId}) : super(key: key);

  @override
  State<AddToShoppingListScreen> createState() => _AddToShoppingListScreenState();
}

class _AddToShoppingListScreenState extends State<AddToShoppingListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _quantityType = 'grams';
  String _category = 'Овощи';
  bool _isEditing = false;

  // Опции для выпадающих списков
  final List<String> _quantityTypes = [
    'grams',
    'milliliters',
    'liters',
    'pieces',
    'tablespoons',
    'teaspoons',
    'cups',
  ];

  final List<String> _categories = [
    'Овощи',
    'Фрукты',
    'Мясо',
    'Молочные',
    'Крупы',
    'Напитки',
    'Другое',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.itemId != null;
    if (_isEditing) {
      // Загрузка данных продукта для редактирования
      _loadItemData();
    }
  }

  void _loadItemData() {
    // Симуляция загрузки данных
    // В реальном приложении здесь будет запрос к API или базе данных
    Future.delayed(Duration.zero, () {
      setState(() {
        _nameController.text = 'Продукт ${widget.itemId}';
        _quantityController.text = '500';
        _quantityType = 'grams';
        _category = 'Овощи';
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование продукта' : 'Добавление в список покупок'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название продукта
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название продукта',
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название продукта';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Количество и единица измерения
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
                    child: DropdownButtonFormField<String>(
                      value: _quantityType,
                      decoration: const InputDecoration(
                        labelText: 'Единица измерения',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      items: _quantityTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(_getQuantityTypeText(type)),
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
              const SizedBox(height: 16),

              // Категория
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Кнопки действий
              Row(
                children: [
                  if (_isEditing)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Удаление продукта из списка
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Продукт удален из списка покупок'),
                            ),
                          );
                        },
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
                      onPressed: _saveItem,
                      icon: Icon(_isEditing ? Icons.save : Icons.add),
                      label: Text(_isEditing ? 'Сохранить' : 'Добавить'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Кнопка сканирования штрих-кода (только для добавления)
              if (!_isEditing)
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

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      // Сохранение продукта
      // В реальном приложении здесь будет запрос к API или базе данных

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Продукт обновлен'
                : 'Продукт добавлен в список покупок',
          ),
        ),
      );
    }
  }

  String _getQuantityTypeText(String quantityType) {
    switch (quantityType) {
      case 'grams':
        return 'Граммы (г)';
      case 'milliliters':
        return 'Миллилитры (мл)';
      case 'liters':
        return 'Литры (л)';
      case 'pieces':
        return 'Штуки (шт)';
      case 'tablespoons':
        return 'Столовые ложки (ст. л.)';
      case 'teaspoons':
        return 'Чайные ложки (ч. л.)';
      case 'cups':
        return 'Стаканы';
      default:
        return '';
    }
  }
}