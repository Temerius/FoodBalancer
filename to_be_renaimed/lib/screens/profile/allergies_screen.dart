import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({Key? key}) : super(key: key);

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  // Симуляция списка аллергенов
  final List<Map<String, dynamic>> _allergens = [
    {'id': 1, 'name': 'Глютен', 'selected': false},
    {'id': 2, 'name': 'Лактоза', 'selected': false},
    {'id': 3, 'name': 'Яйца', 'selected': false},
    {'id': 4, 'name': 'Орехи', 'selected': false},
    {'id': 5, 'name': 'Арахис', 'selected': false},
    {'id': 6, 'name': 'Соя', 'selected': false},
    {'id': 7, 'name': 'Рыба', 'selected': false},
    {'id': 8, 'name': 'Морепродукты', 'selected': false},
    {'id': 9, 'name': 'Цитрусовые', 'selected': false},
  ];

  @override
  void initState() {
    super.initState();
    // Загрузка аллергий пользователя
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.allergenIds != null) {
      for (var allergen in _allergens) {
        allergen['selected'] = user!.allergenIds!.contains(allergen['id']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аллергии'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Выберите продукты, на которые у вас аллергия, и мы исключим их из рекомендаций',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _allergens.length,
              itemBuilder: (context, index) {
                final allergen = _allergens[index];
                return CheckboxListTile(
                  title: Text(allergen['name']),
                  value: allergen['selected'],
                  onChanged: (bool? value) {
                    setState(() {
                      allergen['selected'] = value ?? false;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Получение выбранных аллергенов
                  final selectedAllergenIds = _allergens
                      .where((allergen) => allergen['selected'])
                      .map((allergen) => allergen['id'] as int)
                      .toList();

                  // TODO: Сохранение аллергенов в профиле пользователя

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Аллергии успешно обновлены')),
                  );
                },
                child: const Text('Сохранить'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}