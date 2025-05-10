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
    print('\n=== RefrigeratorItem.fromJson DEBUG ===');
    print('JSON TYPE: ${json.runtimeType}');
    print('JSON CONTENT: $json');

    // Сначала получаем данные из сериализованной структуры
    Ingredient? ingredient;
    if (json['ingredient'] != null && json['ingredient'] is Map<String, dynamic>) {
      ingredient = Ingredient.fromJson(json['ingredient']);
    }

    // Парсим enum для quantityType
    QuantityType quantityType = QuantityType.grams;
    try {
      quantityType = QuantityType.fromString(json['mui_quantity_type'] ?? 'grams');
    } catch (e) {
      print('Error parsing quantity type: $e');
    }

    // Правильно парсим числовые поля
    int id = 0;
    try {
      print('PARSING mui_id: ${json['mui_id']} (type: ${json['mui_id']?.runtimeType})');
      if (json['mui_id'] is int) {
        id = json['mui_id'];
      } else if (json['mui_id'] is String) {
        id = int.tryParse(json['mui_id']) ?? 0;
      }
    } catch (e) {
      print('ERROR parsing id: $e');
    }

    int userId = 0;
    try {
      print('PARSING mui_usr_id: ${json['mui_usr_id']} (type: ${json['mui_usr_id']?.runtimeType})');
      if (json['mui_usr_id'] is int) {
        userId = json['mui_usr_id'];
      } else if (json['mui_usr_id'] is String) {
        userId = int.tryParse(json['mui_usr_id']) ?? 0;
      }
    } catch (e) {
      print('ERROR parsing userId: $e');
    }

    int ingredientId = 0;
    try {
      print('PARSING mui_ing_id: ${json['mui_ing_id']} (type: ${json['mui_ing_id']?.runtimeType})');
      if (json['mui_ing_id'] is int) {
        ingredientId = json['mui_ing_id'];
      } else if (json['mui_ing_id'] is String) {
        ingredientId = int.tryParse(json['mui_ing_id']) ?? 0;
      } else if (json['mui_ing_id'] is Map && json['mui_ing_id']['ing_id'] != null) {
        // Если mui_ing_id - это объект, извлекаем ID из него
        ingredientId = json['mui_ing_id']['ing_id'];
      } else if (ingredient != null) {
        // Если не получилось извлечь ID из mui_ing_id, используем ID из ingredient
        ingredientId = ingredient.id;
      }
    } catch (e) {
      print('ERROR parsing ingredientId: $e');
    }

    int quantity = 0;
    try {
      print('PARSING mui_quantity: ${json['mui_quantity']} (type: ${json['mui_quantity']?.runtimeType})');
      if (json['mui_quantity'] is int) {
        quantity = json['mui_quantity'];
      } else if (json['mui_quantity'] is String) {
        quantity = int.tryParse(json['mui_quantity']) ?? 0;
      }
    } catch (e) {
      print('ERROR parsing quantity: $e');
    }

    print('=== FINAL VALUES ===');
    print('id: $id');
    print('userId: $userId');
    print('ingredientId: $ingredientId');
    print('quantity: $quantity');
    print('quantityType: $quantityType');
    print('=========================\n');

    return RefrigeratorItem(
      id: id,
      userId: userId,
      ingredientId: ingredientId,
      quantity: quantity,
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

    // Получаем только даты без времени для правильного сравнения
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      ingredient!.expiryDate!.year,
      ingredient!.expiryDate!.month,
      ingredient!.expiryDate!.day,
    );

    // Считаем разницу в днях
    final difference = expiry.difference(today).inDays;

    return difference;
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