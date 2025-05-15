import 'package:flutter/material.dart';
import '../../utils/date_formatter.dart';

class GeneratePlanScreen extends StatefulWidget {
  const GeneratePlanScreen({Key? key}) : super(key: key);

  @override
  State<GeneratePlanScreen> createState() => _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends State<GeneratePlanScreen> {
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));

  
  final TextEditingController _caloriesController = TextEditingController(text: '2000');

  
  final List<String> _diets = [
    'Обычная',
    'Вегетарианская',
    'Веганская',
    'Кето',
    'Низкоуглеводная',
    'Безглютеновая',
  ];
  String _selectedDiet = 'Обычная';

  
  final Map<String, bool> _meals = {
    'Завтрак': true,
    'Обед': true,
    'Ужин': true,
    'Перекус': false,
  };

  
  final Map<String, bool> _cuisines = {
    'Итальянская': false,
    'Азиатская': false,
    'Русская': false,
    'Французская': false,
    'Мексиканская': false,
  };

  
  bool _isGenerating = false;

  @override
  void dispose() {
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание плана питания'),
      ),
      body: _isGenerating
          ? _buildGeneratingView()
          : _buildSettingsView(),
    );
  }

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Text(
            'Период планирования',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Начало',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormatter.formatDate(_startDate)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Конец',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormatter.formatDate(_endDate)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          
          Text(
            'Цель по калориям',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caloriesController,
            decoration: const InputDecoration(
              labelText: 'Калории в день',
              hintText: 'Например: 2000',
              prefixIcon: Icon(Icons.local_fire_department),
              suffixText: 'ккал',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          
          Text(
            'Тип диеты',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedDiet,
            decoration: const InputDecoration(
              labelText: 'Выберите диету',
              prefixIcon: Icon(Icons.restaurant_menu),
            ),
            items: _diets.map((diet) {
              return DropdownMenuItem<String>(
                value: diet,
                child: Text(diet),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDiet = value;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          
          Text(
            'Приемы пищи',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ..._meals.entries.map((entry) => CheckboxListTile(
            title: Text(entry.key),
            value: entry.value,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _meals[entry.key] = value;
                });
              }
            },
            activeColor: Theme.of(context).colorScheme.primary,
          )),
          const SizedBox(height: 16),

          
          Text(
            'Предпочтения по кухням',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ..._cuisines.entries.map((entry) => CheckboxListTile(
            title: Text(entry.key),
            value: entry.value,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _cuisines[entry.key] = value;
                });
              }
            },
            activeColor: Theme.of(context).colorScheme.primary,
          )),
          const SizedBox(height: 32),

          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generatePlan,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Создать план питания'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Создаем ваш план питания...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Учитываем ваши предпочтения и доступные продукты',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 6));
          }
        } else {
          _endDate = picked;
          
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 6));
          }
        }
      });
    }
  }

  void _generatePlan() {
    
    if (_caloriesController.text.isEmpty || int.tryParse(_caloriesController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, укажите корректное количество калорий')),
      );
      return;
    }

    
    if (!_meals.values.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите хотя бы один прием пищи')),
      );
      return;
    }

    
    setState(() {
      _isGenerating = true;
    });

    
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isGenerating = false;
      });

      
      Navigator.pushReplacementNamed(context, '/meal-plan/weekly');

      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('План питания успешно создан!')),
      );
    });
  }
}