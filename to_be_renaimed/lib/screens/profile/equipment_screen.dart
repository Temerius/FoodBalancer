import 'package:flutter/material.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({Key? key}) : super(key: key);

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  // Симуляция списка оборудования
  final List<Map<String, dynamic>> _equipment = [
    {
      'id': 1,
      'name': 'Духовка',
      'type': 'Плита',
      'power': 2500,
      'capacity': 35,
    },
    {
      'id': 2,
      'name': 'Мультиварка',
      'type': 'Малая бытовая техника',
      'power': 860,
      'capacity': 5,
    },
    {
      'id': 3,
      'name': 'Блендер',
      'type': 'Малая бытовая техника',
      'power': 600,
      'capacity': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кухонное оборудование'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Добавьте оборудование, которое у вас есть на кухне, и мы подберем подходящие рецепты',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: _equipment.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.kitchen_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'У вас пока нет добавленного оборудования',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _equipment.length,
              itemBuilder: (context, index) {
                final item = _equipment[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.kitchen,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Тип: ${item['type']}',
                                style:
                                Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Мощность: ${item['power']} Вт, Объем: ${item['capacity']} л',
                                style:
                                Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEquipmentDialog(context, item);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _equipment.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showEquipmentDialog(context, null);
                },
                icon: const Icon(Icons.add),
                label: const Text('Добавить оборудование'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEquipmentDialog(BuildContext context, Map<String, dynamic>? equipment) {
    final isEditing = equipment != null;
    final nameController = TextEditingController(text: isEditing ? equipment['name'] : '');
    final typeController = TextEditingController(text: isEditing ? equipment['type'] : '');
    final powerController = TextEditingController(
        text: isEditing ? equipment['power'].toString() : '');
    final capacityController = TextEditingController(
        text: isEditing ? equipment['capacity'].toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Редактировать оборудование' : 'Добавить оборудование'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(labelText: 'Тип'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: powerController,
                decoration: const InputDecoration(labelText: 'Мощность (Вт)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(labelText: 'Объем (л)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final newEquipment = {
                'id': isEditing ? equipment['id'] : _equipment.length + 1,
                'name': nameController.text,
                'type': typeController.text,
                'power': int.tryParse(powerController.text) ?? 0,
                'capacity': int.tryParse(capacityController.text) ?? 0,
              };

              setState(() {
                if (isEditing) {
                  final index = _equipment.indexWhere((e) => e['id'] == equipment['id']);
                  if (index != -1) {
                    _equipment[index] = newEquipment;
                  }
                } else {
                  _equipment.add(newEquipment);
                }
              });

              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }
}