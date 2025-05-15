
import 'package:to_be_renaimed/models/enums.dart';
import 'package:to_be_renaimed/models/ingredient_type.dart';

class ShoppingListItem {
  final int id;
  final int quantity;
  final QuantityType quantityType;
  final bool isChecked;
  final IngredientType? ingredientType;

  ShoppingListItem({
    required this.id,
    required this.quantity,
    required this.quantityType,
    required this.isChecked,
    this.ingredientType,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    print('\n=== ShoppingListItem.fromJson DEBUG ===');
    print('JSON TYPE: ${json.runtimeType}');
    print('JSON CONTENT: $json');

    
    QuantityType quantityType = QuantityType.grams;
    try {
      quantityType = QuantityType.fromString(json['mis_quantity_type'] ?? 'grams');
    } catch (e) {
      print('Error parsing quantity type: $e');
    }

    
    IngredientType? ingredientType;
    if (json['ingredient_type'] != null && json['ingredient_type'] is Map<String, dynamic>) {
      ingredientType = IngredientType.fromJson(json['ingredient_type']);
    }

    return ShoppingListItem(
      id: json['mis_id'] ?? 0,
      quantity: json['mis_quantity'] ?? 0,
      quantityType: quantityType,
      isChecked: json['is_checked'] ?? false,
      ingredientType: ingredientType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mis_id': id,
      'mis_quantity': quantity,
      'mis_quantity_type': quantityType.toString().split('.').last,
      'is_checked': isChecked,
    };
  }

  
  String get formattedQuantity {
    return '$quantity ${quantityType.getShortName()}';
  }

  
  String get name => ingredientType?.name ?? 'Неизвестный продукт';

  ShoppingListItem copyWith({
    int? id,
    int? quantity,
    QuantityType? quantityType,
    bool? isChecked,
    IngredientType? ingredientType,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      quantityType: quantityType ?? this.quantityType,
      isChecked: isChecked ?? this.isChecked,
      ingredientType: ingredientType ?? this.ingredientType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ShoppingListItem &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ShoppingList {
  final int id;
  final int userId;
  final List<ShoppingListItem> items;

  ShoppingList({
    required this.id,
    required this.userId,
    required this.items,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    List<ShoppingListItem> items = [];
    if (json['items'] != null) {
      items = (json['items'] as List).map((item) => ShoppingListItem.fromJson(item)).toList();
    }

    return ShoppingList(
      id: json['spl_id'] ?? 0,
      userId: 0, 
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spl_id': id,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  
  List<ShoppingListItem> get checkedItems => items.where((item) => item.isChecked).toList();

  
  double get progress => items.isEmpty ? 0.0 : checkedItems.length / items.length;

  
  Map<String, List<ShoppingListItem>> get itemsByCategory {
    final Map<String, List<ShoppingListItem>> result = {};

    for (var item in items) {
      final category = item.ingredientType?.category ?? 'Другое';
      if (!result.containsKey(category)) {
        result[category] = [];
      }
      result[category]!.add(item);
    }

    return result;
  }
}