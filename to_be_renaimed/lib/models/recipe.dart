// lib/models/recipe.dart
import 'package:to_be_renaimed/models/enums.dart';
import 'package:to_be_renaimed/models/equipment.dart';
import 'package:to_be_renaimed/models/ingredient_type.dart';

class Recipe {
  final int id;
  final String title;
  final String description;
  final int calories;
  final int portionCount;
  final String? mainImageUrl;

  // Новые поля
  final int weight;
  final int fat;
  final int carbs;
  final int protein;

  // Runtime properties
  bool isFavorite = false;
  List<RecipeStep> steps = [];
  List<RecipeIngredient> ingredients = [];
  List<Equipment> requiredEquipment = [];

  // Calculated nutritional values
  int? _prepTime; // Estimated preparation time in minutes

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.calories,
    required this.portionCount,
    this.mainImageUrl,
    this.weight = 0,      // Новое поле - вес порции
    this.fat = 0,         // Новое поле - жиры
    this.carbs = 0,       // Новое поле - углеводы
    this.protein = 0,     // Новое поле - белки
    this.isFavorite = false,
    List<RecipeStep>? steps,
    List<RecipeIngredient>? ingredients,
    List<Equipment>? requiredEquipment,
    int? prepTime,
  }) :
        steps = steps ?? [],
        ingredients = ingredients ?? [],
        requiredEquipment = requiredEquipment ?? [],
        _prepTime = prepTime;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    try {
      // Проверка базовых полей
      final recipeId = json['rcp_id'];
      final title = json['rcp_title'] ?? '';
      final description = json['rcp_description'] ?? '';

      if (recipeId == null) {
        throw FormatException('Обязательное поле rcp_id отсутствует в данных рецепта');
      }

      // Попытка парсинга числовых полей с корректной обработкой ошибок
      int calories = 0;
      try {
        var calValue = json['rcp_cal'] ?? 0;
        if (calValue is String) {
          calories = int.tryParse(calValue) ?? 0;
        } else {
          calories = calValue is int ? calValue : 0;
        }
      } catch (e) {
        print("Error parsing calories: $e");
        calories = 0;
      }

      int portionCount = 1;
      try {
        var portionValue = json['rcp_portion_count'] ?? 1;
        if (portionValue is String) {
          portionCount = int.tryParse(portionValue) ?? 1;
        } else {
          portionCount = portionValue is int ? portionValue : 1;
        }
        if (portionCount <= 0) portionCount = 1; // Минимум 1 порция
      } catch (e) {
        print("Error parsing portion count: $e");
        portionCount = 1;
      }

      // Парсинг новых полей
      int weight = 0;
      try {
        var weightValue = json['rcp_weight'] ?? 0;
        if (weightValue is String) {
          weight = int.tryParse(weightValue) ?? 0;
        } else {
          weight = weightValue is int ? weightValue : 0;
        }
      } catch (e) {
        print("Error parsing weight: $e");
        weight = 0;
      }

      int fat = 0;
      try {
        var fatValue = json['rcp_fat'] ?? 0;
        if (fatValue is String) {
          fat = int.tryParse(fatValue) ?? 0;
        } else {
          fat = fatValue is int ? fatValue : 0;
        }
      } catch (e) {
        print("Error parsing fat: $e");
        fat = 0;
      }

      int carbs = 0;
      try {
        var carbsValue = json['rcp_hydrates'] ?? 0; // Важно: поле называется rcp_hydrates в БД
        if (carbsValue is String) {
          carbs = int.tryParse(carbsValue) ?? 0;
        } else {
          carbs = carbsValue is int ? carbsValue : 0;
        }
      } catch (e) {
        print("Error parsing carbs: $e");
        carbs = 0;
      }

      int protein = 0;
      try {
        var proteinValue = json['rcp_protein'] ?? 0;
        if (proteinValue is String) {
          protein = int.tryParse(proteinValue) ?? 0;
        } else {
          protein = proteinValue is int ? proteinValue : 0;
        }
      } catch (e) {
        print("Error parsing protein: $e");
        protein = 0;
      }

      // Парсинг флага избранного
      bool isFavorite = false;
      try {
        var favValue = json['is_favorite'] ?? false;
        if (favValue is String) {
          isFavorite = favValue.toLowerCase() == 'true';
        } else {
          isFavorite = favValue is bool ? favValue : false;
        }
      } catch (e) {
        print("Error parsing isFavorite: $e");
        isFavorite = false;
      }

      // Парсинг URL изображения
      String? mainImageUrl;
      try {
        mainImageUrl = json['rcp_main_img'] as String?;
      } catch (e) {
        print("Error parsing main image URL: $e");
        mainImageUrl = null;
      }

      // Создание и возврат объекта Recipe
      return Recipe(
        id: recipeId is int ? recipeId : 0,
        title: title,
        description: description,
        calories: calories,
        portionCount: portionCount,
        mainImageUrl: mainImageUrl,
        weight: weight,        // Новое поле
        fat: fat,              // Новое поле
        carbs: carbs,          // Новое поле
        protein: protein,      // Новое поле
        isFavorite: isFavorite,
      );
    } catch (e) {
      print("Error creating Recipe from JSON: $e");
      print("JSON data: $json");
      throw FormatException('Ошибка при создании рецепта из данных: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'rcp_id': id,
      'rcp_title': title,
      'rcp_description': description,
      'rcp_cal': calories,
      'rcp_portion_count': portionCount,
      'rcp_weight': weight,       // Новое поле
      'rcp_fat': fat,             // Новое поле
      'rcp_hydrates': carbs,      // Важно: в БД поле называется hydrates, а не carbs
      'rcp_protein': protein,     // Новое поле
      'is_favorite': isFavorite,
      if (mainImageUrl != null) 'rcp_main_img': mainImageUrl,
    };
  }

  // Методы для расчета пищевой ценности на 100 г с округлением вверх
  int calculatePer100g(int value) {
    if (weight <= 0) return 0;
    // Используем функцию .ceil() для округления вверх
    return (value * 100 / weight).ceil();
  }

  // Геттеры для значений на 100 г
  int get caloriesPer100g => calculatePer100g(calories);
  int get proteinPer100g => calculatePer100g(protein);
  int get fatPer100g => calculatePer100g(fat);
  int get carbsPer100g => calculatePer100g(carbs);

  // Getter for prep time (calculated if not set)
  int get prepTime {
    if (_prepTime != null) return _prepTime!;
    if (steps.isEmpty) return 30; // Default value

    // Basic calculation based on number of steps
    return steps.length * 10; // 10 minutes per step as a basic estimate
  }

  // Setter for prep time
  set prepTime(int value) => _prepTime = value;

  Recipe copyWith({
    int? id,
    String? title,
    String? description,
    int? calories,
    int? portionCount,
    String? mainImageUrl,
    int? weight,
    int? fat,
    int? carbs,
    int? protein,
    bool? isFavorite,
    List<RecipeStep>? steps,
    List<RecipeIngredient>? ingredients,
    List<Equipment>? requiredEquipment,
    int? prepTime,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      portionCount: portionCount ?? this.portionCount,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      weight: weight ?? this.weight,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      isFavorite: isFavorite ?? this.isFavorite,
      steps: steps ?? List.from(this.steps),
      ingredients: ingredients ?? List.from(this.ingredients),
      requiredEquipment: requiredEquipment ?? List.from(this.requiredEquipment),
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

  // Метод для отладочного вывода информации о рецепте
  void debugPrint() {
    print("\n===== RECIPE DEBUG INFO =====");
    print("ID: $id");
    print("Title: $title");
    print("Description: ${description.substring(0, description.length > 50 ? 50 : description.length)}...");
    print("Calories: $calories");
    print("Portions: $portionCount");
    print("Weight: $weight g");
    print("Protein: $protein g");
    print("Fat: $fat g");
    print("Carbs: $carbs g");
    print("Is Favorite: $isFavorite");
    print("Steps count: ${steps.length}");
    print("Ingredients count: ${ingredients.length}");
    print("==========================\n");
  }
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