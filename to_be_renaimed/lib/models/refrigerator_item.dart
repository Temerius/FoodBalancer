// lib/models/refrigerator_item.dart
import 'package:to_be_renaimed/models/ingredient.dart';
import 'package:to_be_renaimed/models/enums.dart';

class RefrigeratorItem {
  final int id;
  final int userId;
  final int ingredientId;
  final int quantity;
  final QuantityType quantityType;

  // Runtime properties
  Ingredient? ingredient;

  RefrigeratorItem({
    required this.id,
    required this.userId,
    required this.ingredientId,
    required this.quantity,
    required this.quantityType,
    this.ingredient,
  });

  factory RefrigeratorItem.fromJson(Map<String, dynamic> json) {
    // Сначала получаем данные из сериализованной структуры
    Ingredient? ingredient;
    if (json['ingredient'] != null) {
      ingredient = Ingredient.fromJson(json['ingredient']);
    }

    // Парсим enum для quantityType
    QuantityType quantityType = QuantityType.grams;
    try {
      quantityType = QuantityType.fromString(json['mui_quantity_type'] ?? 'grams');
    } catch (e) {
      print('Error parsing quantity type: $e');
    }

    return RefrigeratorItem(
      id: json['mui_id'] ?? 0,
      userId: json['mui_usr_id'] ?? 0,
      ingredientId: json['mui_ing_id'] ?? ingredient?.id ?? 0,
      quantity: json['mui_quantity'] ?? 0,
      quantityType: quantityType,
      ingredient: ingredient,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mui_id': id,
      'mui_usr_id': userId,
      'mui_ing_id': ingredientId,
      'mui_quantity': quantity,
      'mui_quantity_type': quantityType.toString().split('.').last,
      if (ingredient != null) 'ingredient': ingredient!.toJson(),
    };
  }

  // Получить отформатированное количество с единицами измерения
  String get formattedQuantity {
    return '$quantity ${quantityType.getShortName()}';
  }

  // Получить название ингредиента
  String get name => ingredient?.name ?? 'Неизвестный продукт';

  // Получить дни до истечения срока годности
  int? get daysLeft {
    if (ingredient?.expiryDate == null) return null;

    final now = DateTime.now();
    final difference = ingredient!.expiryDate!.difference(now);
    return difference.inDays;
  }

  // Проверить, истек ли срок годности
  bool get isExpired {
    final days = daysLeft;
    return days != null && days < 0;
  }

  // Проверить, истекает ли срок годности в ближайшие дни
  bool isExpiringSoon(int days) {
    final daysLeft = this.daysLeft;
    return daysLeft != null && daysLeft >= 0 && daysLeft <= days;
  }

  RefrigeratorItem copyWith({
    int? id,
    int? userId,
    int? ingredientId,
    int? quantity,
    QuantityType? quantityType,
    Ingredient? ingredient,
  }) {
    return RefrigeratorItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ingredientId: ingredientId ?? this.ingredientId,
      quantity: quantity ?? this.quantity,
      quantityType: quantityType ?? this.quantityType,
      ingredient: ingredient ?? this.ingredient,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RefrigeratorItem &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Статистика холодильника
class RefrigeratorStats {
  final int totalItems;
  final int expiringSoon;
  final int expired;

  RefrigeratorStats({
    required this.totalItems,
    required this.expiringSoon,
    required this.expired,
  });

  factory RefrigeratorStats.fromJson(Map<String, dynamic> json) {
    return RefrigeratorStats(
      totalItems: json['total_items'] ?? 0,
      expiringSoon: json['expiring_soon'] ?? 0,
      expired: json['expired'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'expiring_soon': expiringSoon,
      'expired': expired,
    };
  }
}