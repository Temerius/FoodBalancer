import 'package:to_be_renaimed/models/enums.dart';
import 'package:to_be_renaimed/models/ingredient_type.dart';
import 'package:to_be_renaimed/models/allergen.dart';

class Ingredient {
  final int id;
  final String name;
  final DateTime? expiryDate;
  final int weight;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final int ingredientTypeId;
  final String? imageUrl;


  IngredientType? type;
  bool isSelected = false;
  List<Allergen> allergens = [];

  Ingredient({
    required this.id,
    required this.name,
    this.expiryDate,
    required this.weight,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.ingredientTypeId,
    this.imageUrl,
    this.type,
    this.allergens = const [],
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    int ingredientTypeId = 0;
    try {
      if (json['ing_igt_id'] is int) {
        ingredientTypeId = json['ing_igt_id'];
      } else if (json['ing_igt_id'] is Map<String, dynamic>) {
        final typeMap = json['ing_igt_id'] as Map<String, dynamic>;
        ingredientTypeId = typeMap['igt_id'] ?? 0;
      } else if (json['ing_igt_id'] is String) {
        ingredientTypeId = int.tryParse(json['ing_igt_id']) ?? 0;
      }
    } catch (e) {
      print('Error parsing ing_igt_id: $e');
    }

    IngredientType? type;
    try {
      if (json['ing_igt_id'] is Map<String, dynamic>) {
        type = IngredientType.fromJson(json['ing_igt_id']);
      }
    } catch (e) {
      print('Error parsing IngredientType from ing_igt_id: $e');
    }

    List<Allergen> allergens = [];
    try {
      if (json['allergens'] != null && json['allergens'] is List) {
        allergens = (json['allergens'] as List)
            .map((allergenJson) => Allergen.fromJson(allergenJson))
            .toList();
      }
    } catch (e) {
      print('Error parsing allergens: $e');
    }

    return Ingredient(
      id: json['ing_id'],
      name: json['ing_name'] ?? '',
      expiryDate: json['ing_exp_date'] != null
          ? DateTime.parse(json['ing_exp_date'])
          : null,
      weight: json['ing_weight'] ?? 0,
      calories: json['ing_calories'] ?? 0,
      protein: json['ing_protein'] ?? 0,
      fat: json['ing_fat'] ?? 0,
      carbs: json['ing_hydrates'] ?? 0,
      ingredientTypeId: ingredientTypeId,
      imageUrl: json['ing_img_url'],
      type: type,
      allergens: allergens,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ing_id': id,
      'ing_name': name,
      if (expiryDate != null) 'ing_exp_date': expiryDate!.toIso8601String().split('T')[0],
      'ing_weight': weight,
      'ing_calories': calories,
      'ing_protein': protein,
      'ing_fat': fat,
      'ing_hydrates': carbs,
      'ing_igt_id': ingredientTypeId,
      if (imageUrl != null) 'ing_img_url': imageUrl,
      'allergen_ids': allergens.map((allergen) => allergen.id).toList(),
    };
  }

  int? get daysLeft {
    if (expiryDate == null) return null;

    final now = DateTime.now();
    final difference = expiryDate!.difference(now);
    return difference.inDays;
  }

  String? get category => type?.category;

  String get allergensString {
    if (allergens.isEmpty) return 'Нет аллергенов';
    return allergens.map((allergen) => allergen.name).join(', ');
  }

  Ingredient copyWith({
    int? id,
    String? name,
    DateTime? expiryDate,
    int? weight,
    int? calories,
    int? protein,
    int? fat,
    int? carbs,
    int? ingredientTypeId,
    String? imageUrl,
    IngredientType? type,
    List<Allergen>? allergens,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      expiryDate: expiryDate ?? this.expiryDate,
      weight: weight ?? this.weight,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      ingredientTypeId: ingredientTypeId ?? this.ingredientTypeId,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      allergens: allergens ?? this.allergens,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Ingredient &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}


class UserIngredient {
  final int? id;
  final int userId;
  final int ingredientId;
  final int quantity;
  final QuantityType quantityType;

  
  Ingredient? ingredient;
  bool isChecked = false; 

  UserIngredient({
    this.id,
    required this.userId,
    required this.ingredientId,
    required this.quantity,
    required this.quantityType,
    this.ingredient,
  });

  factory UserIngredient.fromJson(Map<String, dynamic> json) {
    return UserIngredient(
      id: json['mui_id'],
      userId: json['mui_usr_id'],
      ingredientId: json['mui_ing_id'],
      quantity: json['mui_quantity'] ?? 0,
      quantityType: QuantityType.fromString(json['mui_quantity_type'] ?? 'grams'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'mui_id': id,
      'mui_usr_id': userId,
      'mui_ing_id': ingredientId,
      'mui_quantity': quantity,
      'mui_quantity_type': quantityType.toString().split('.').last,
    };
  }

  
  String get formattedQuantity {
    return '$quantity ${quantityType.getShortName()}';
  }

  UserIngredient copyWith({
    int? id,
    int? userId,
    int? ingredientId,
    int? quantity,
    QuantityType? quantityType,
    Ingredient? ingredient,
    bool? isChecked,
  }) {
    return UserIngredient(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ingredientId: ingredientId ?? this.ingredientId,
      quantity: quantity ?? this.quantity,
      quantityType: quantityType ?? this.quantityType,
      ingredient: ingredient ?? this.ingredient,
    )..isChecked = isChecked ?? this.isChecked;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserIngredient &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}


class ShoppingListItem {
  final int? id;
  final int shoppingListId;
  final int ingredientTypeId;
  final int quantity;
  final QuantityType quantityType;

  
  IngredientType? ingredientType;
  bool isChecked = false;

  ShoppingListItem({
    this.id,
    required this.shoppingListId,
    required this.ingredientTypeId,
    required this.quantity,
    required this.quantityType,
    this.ingredientType,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['mis_id'],
      shoppingListId: json['mis_spl_id'],
      ingredientTypeId: json['mis_igt_id'],
      quantity: json['mis_quantity'] ?? 0,
      quantityType: QuantityType.fromString(json['mis_quantity_type'] ?? 'grams'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'mis_id': id,
      'mis_spl_id': shoppingListId,
      'mis_igt_id': ingredientTypeId,
      'mis_quantity': quantity,
      'mis_quantity_type': quantityType.toString().split('.').last,
    };
  }

  
  String get formattedQuantity {
    return '$quantity ${quantityType.getShortName()}';
  }

  
  String get name => ingredientType?.name ?? 'Неизвестный продукт';

  ShoppingListItem copyWith({
    int? id,
    int? shoppingListId,
    int? ingredientTypeId,
    int? quantity,
    QuantityType? quantityType,
    IngredientType? ingredientType,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      ingredientTypeId: ingredientTypeId ?? this.ingredientTypeId,
      quantity: quantity ?? this.quantity,
      quantityType: quantityType ?? this.quantityType,
      ingredientType: ingredientType ?? this.ingredientType,
    )..isChecked = isChecked ?? this.isChecked;
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