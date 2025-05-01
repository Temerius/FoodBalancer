import 'package:to_be_renaimed/models/enums.dart';
import 'package:to_be_renaimed/models/equipment.dart';
import 'package:to_be_renaimed/models/ingredient_type.dart';

class Recipe {
  final int id;
  final String title;
  final String description;
  final int calories;
  final int portionCount;

  // Runtime properties
  bool isFavorite = false;
  List<RecipeStep> steps = [];
  List<RecipeIngredient> ingredients = [];
  List<Equipment> requiredEquipment = [];

  // Calculated nutritional values
  int? _protein;
  int? _fat;
  int? _carbs;
  int? _prepTime; // Estimated preparation time in minutes

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.calories,
    required this.portionCount,
    this.isFavorite = false,
    List<RecipeStep>? steps,
    List<RecipeIngredient>? ingredients,
    List<Equipment>? requiredEquipment,
    int? protein,
    int? fat,
    int? carbs,
    int? prepTime,
  }) :
        steps = steps ?? [],
        ingredients = ingredients ?? [],
        requiredEquipment = requiredEquipment ?? [],
        _protein = protein,
        _fat = fat,
        _carbs = carbs,
        _prepTime = prepTime;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['rcp_id'],
      title: json['rcp_title'] ?? '',
      description: json['rcp_description'] ?? '',
      calories: json['rcp_cal'] ?? 0,
      portionCount: json['rcp_portion_count'] ?? 1,
      isFavorite: json['is_favorite'] ?? false, // From favorite_recipe table/join
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rcp_id': id,
      'rcp_title': title,
      'rcp_description': description,
      'rcp_cal': calories,
      'rcp_portion_count': portionCount,
      'is_favorite': isFavorite,
    };
  }

  // Getter for protein (calculated if not set)
  int get protein {
    if (_protein != null) return _protein!;
    if (ingredients.isEmpty) return 0;

    // Calculate from ingredients
    int totalProtein = 0;
    for (var ingredient in ingredients) {
      if (ingredient.ingredientType != null) {
        // Add calculation logic here
        totalProtein += 3; // Placeholder
      }
    }
    return totalProtein;
  }

  // Getter for fat (calculated if not set)
  int get fat {
    if (_fat != null) return _fat!;
    if (ingredients.isEmpty) return 0;

    // Calculate from ingredients
    int totalFat = 0;
    for (var ingredient in ingredients) {
      if (ingredient.ingredientType != null) {
        // Add calculation logic here
        totalFat += 2; // Placeholder
      }
    }
    return totalFat;
  }

  // Getter for carbs (calculated if not set)
  int get carbs {
    if (_carbs != null) return _carbs!;
    if (ingredients.isEmpty) return 0;

    // Calculate from ingredients
    int totalCarbs = 0;
    for (var ingredient in ingredients) {
      if (ingredient.ingredientType != null) {
        // Add calculation logic here
        totalCarbs += 5; // Placeholder
      }
    }
    return totalCarbs;
  }

  // Getter for prep time (calculated if not set)
  int get prepTime {
    if (_prepTime != null) return _prepTime!;
    if (steps.isEmpty) return 30; // Default value

    // Basic calculation based on number of steps
    return steps.length * 10; // 10 minutes per step as a basic estimate
  }

  // Setters for nutrition values
  set protein(int value) => _protein = value;
  set fat(int value) => _fat = value;
  set carbs(int value) => _carbs = value;
  set prepTime(int value) => _prepTime = value;

  Recipe copyWith({
    int? id,
    String? title,
    String? description,
    int? calories,
    int? portionCount,
    bool? isFavorite,
    List<RecipeStep>? steps,
    List<RecipeIngredient>? ingredients,
    List<Equipment>? requiredEquipment,
    int? protein,
    int? fat,
    int? carbs,
    int? prepTime,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      portionCount: portionCount ?? this.portionCount,
      isFavorite: isFavorite ?? this.isFavorite,
      steps: steps ?? List.from(this.steps),
      ingredients: ingredients ?? List.from(this.ingredients),
      requiredEquipment: requiredEquipment ?? List.from(this.requiredEquipment),
      protein: protein ?? _protein,
      fat: fat ?? _fat,
      carbs: carbs ?? _carbs,
      prepTime: prepTime ?? _prepTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Recipe &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class RecipeStep {
  final int id;
  final int recipeId;
  final String title;
  final String instruction;
  final List<String> imageUrls;
  final List<RecipeStepIngredient> ingredients;

  RecipeStep({
    required this.id,
    required this.recipeId,
    required this.title,
    required this.instruction,
    this.imageUrls = const [],
    this.ingredients = const [],
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      id: json['stp_id'],
      recipeId: json['stp_rcp_id'],
      title: json['stp_title'] ?? '',
      instruction: json['stp_instruction'] ?? '',
      // Images would be populated from a separate query/join
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stp_id': id,
      'stp_rcp_id': recipeId,
      'stp_title': title,
      'stp_instruction': instruction,
    };
  }

  RecipeStep copyWith({
    int? id,
    int? recipeId,
    String? title,
    String? instruction,
    List<String>? imageUrls,
    List<RecipeStepIngredient>? ingredients,
  }) {
    return RecipeStep(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      title: title ?? this.title,
      instruction: instruction ?? this.instruction,
      imageUrls: imageUrls ?? List.from(this.imageUrls),
      ingredients: ingredients ?? List.from(this.ingredients),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RecipeStep &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class RecipeIngredient {
  final int recipeId;
  final int ingredientTypeId;
  final int? quantity;
  final QuantityType? quantityType;

  // Runtime properties
  IngredientType? ingredientType;

  RecipeIngredient({
    required this.recipeId,
    required this.ingredientTypeId,
    this.quantity,
    this.quantityType,
    this.ingredientType,
  });

  // For recipe ingredients, we'd expect a more custom data structure
  // since there's no direct table mapping in the DB schema
  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      recipeId: json['recipe_id'],
      ingredientTypeId: json['ingredient_type_id'],
      quantity: json['quantity'],
      quantityType: json['quantity_type'] != null
          ? QuantityType.fromString(json['quantity_type'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipe_id': recipeId,
      'ingredient_type_id': ingredientTypeId,
      if (quantity != null) 'quantity': quantity,
      if (quantityType != null) 'quantity_type': quantityType.toString().split('.').last,
    };
  }

  // Get formatted quantity with units
  String? get formattedQuantity {
    if (quantity == null || quantityType == null) return null;
    return '$quantity ${quantityType!.getShortName()}';
  }

  // Get ingredient name (if available)
  String get name => ingredientType?.name ?? 'Неизвестный ингредиент';

  RecipeIngredient copyWith({
    int? recipeId,
    int? ingredientTypeId,
    int? quantity,
    QuantityType? quantityType,
    IngredientType? ingredientType,
  }) {
    return RecipeIngredient(
      recipeId: recipeId ?? this.recipeId,
      ingredientTypeId: ingredientTypeId ?? this.ingredientTypeId,
      quantity: quantity ?? this.quantity,
      quantityType: quantityType ?? this.quantityType,
      ingredientType: ingredientType ?? this.ingredientType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RecipeIngredient &&
              runtimeType == other.runtimeType &&
              recipeId == other.recipeId &&
              ingredientTypeId == other.ingredientTypeId;

  @override
  int get hashCode => Object.hash(recipeId, ingredientTypeId);
}

class RecipeStepIngredient {
  final int id;
  final int stepId;
  final int ingredientTypeId;
  final int quantity;
  final QuantityType quantityType;

  // Runtime properties
  IngredientType? ingredientType;

  RecipeStepIngredient({
    required this.id,
    required this.stepId,
    required this.ingredientTypeId,
    required this.quantity,
    required this.quantityType,
    this.ingredientType,
  });

  factory RecipeStepIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeStepIngredient(
      id: json['msi_id'],
      stepId: json['msi_stp_id'],
      ingredientTypeId: json['msi_igt_id'],
      quantity: json['msi_quantity'] ?? 0,
      quantityType: QuantityType.fromString(json['msi_quantity_type'] ?? 'grams'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'msi_id': id,
      'msi_stp_id': stepId,
      'msi_igt_id': ingredientTypeId,
      'msi_quantity': quantity,
      'msi_quantity_type': quantityType.toString().split('.').last,
    };
  }

  // Get formatted quantity with units
  String get formattedQuantity {
    return '$quantity ${quantityType.getShortName()}';
  }

  // Get ingredient name (if available)
  String get name => ingredientType?.name ?? 'Неизвестный ингредиент';

  RecipeStepIngredient copyWith({
    int? id,
    int? stepId,
    int? ingredientTypeId,
    int? quantity,
    QuantityType? quantityType,
    IngredientType? ingredientType,
  }) {
    return RecipeStepIngredient(
      id: id ?? this.id,
      stepId: stepId ?? this.stepId,
      ingredientTypeId: ingredientTypeId ?? this.ingredientTypeId,
      quantity: quantity ?? this.quantity,
      quantityType: quantityType ?? this.quantityType,
      ingredientType: ingredientType ?? this.ingredientType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RecipeStepIngredient &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class FavoriteRecipe {
  final int id;
  final int recipeId;
  final int userId;

  FavoriteRecipe({
    required this.id,
    required this.recipeId,
    required this.userId,
  });

  factory FavoriteRecipe.fromJson(Map<String, dynamic> json) {
    return FavoriteRecipe(
      id: json['fvr_id'],
      recipeId: json['fvr_rcp_id'],
      userId: json['fvr_usr_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fvr_id': id,
      'fvr_rcp_id': recipeId,
      'fvr_usr_id': userId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FavoriteRecipe &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}