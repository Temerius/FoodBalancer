import 'package:to_be_renaimed/models/ingredient.dart';

class ShoppingList {
  final int id;
  final int userId;

  // Runtime properties
  List<ShoppingListItem> items = [];

  ShoppingList({
    required this.id,
    required this.userId,
    List<ShoppingListItem>? items,
  }) : items = items ?? [];

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['spl_id'],
      userId: json['spl_usr_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spl_id': id,
      'spl_usr_id': userId,
    };
  }

  // Get checked items (for progress calculation)
  List<ShoppingListItem> get checkedItems =>
      items.where((item) => item.isChecked).toList();

  // Get progress percentage
  double get progress =>
      items.isEmpty ? 0.0 : checkedItems.length / items.length;

  // Get items by category
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

  ShoppingList copyWith({
    int? id,
    int? userId,
    List<ShoppingListItem>? items,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? List.from(this.items),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ShoppingList &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}