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

  final int weight;
  final int fat;
  final int carbs;
  final int protein;

  bool isFavorite = false;
  List<RecipeStep> steps = [];
  List<RecipeIngredient> ingredients = [];
  List<Equipment> requiredEquipment = [];

  
  int? _prepTime; 

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.calories,
    required this.portionCount,
    this.mainImageUrl,
    this.weight = 0,
    this.fat = 0,
    this.carbs = 0,
    this.protein = 0,
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
      final recipeId = json['rcp_id'];
      final title = json['rcp_title'] ?? '';
      final description = json['rcp_description'] ?? '';

      if (recipeId == null) {
        throw FormatException('Обязательное поле rcp_id отсутствует в данных рецепта');
      }

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
        if (portionCount <= 0) portionCount = 1;
      } catch (e) {
        print("Error parsing portion count: $e");
        portionCount = 1;
      }

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
        var carbsValue = json['rcp_hydrates'] ?? 0;
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

      String? mainImageUrl;
      try {
        mainImageUrl = json['rcp_main_img'] as String?;
      } catch (e) {
        print("Error parsing main image URL: $e");
        mainImageUrl = null;
      }

      List<RecipeStep> steps = [];
      try {
        if (json['steps'] != null && json['steps'] is List) {
          steps = (json['steps'] as List)
              .map((stepJson) => RecipeStep.fromJson(stepJson))
              .toList();
        }
      } catch (e) {
        print("Error parsing steps: $e");
        steps = [];
      }


      List<Equipment> equipment = [];
      try {
        if (json['equipment'] != null && json['equipment'] is List) {
          equipment = (json['equipment'] as List)
              .map((equipmentJson) => Equipment.fromJson(equipmentJson))
              .toList();
        }
      } catch (e) {
        print("Error parsing equipment: $e");
        equipment = [];
      }


      final recipe = Recipe(
        id: recipeId is int ? recipeId : 0,
        title: title,
        description: description,
        calories: calories,
        portionCount: portionCount,
        mainImageUrl: mainImageUrl,
        weight: weight,
        fat: fat,
        carbs: carbs,
        protein: protein,
        isFavorite: isFavorite,
      );

      recipe.steps = steps;
      recipe.requiredEquipment = equipment;

      return recipe;
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
      'rcp_weight': weight,
      'rcp_fat': fat,
      'rcp_hydrates': carbs,
      'rcp_protein': protein,
      'is_favorite': isFavorite,
      if (mainImageUrl != null) 'rcp_main_img': mainImageUrl,
    };
  }

  int calculatePer100g(int value) {
    if (weight <= 0) return 0;
    return (value * 100 / weight).ceil();
  }

  int get caloriesPer100g => calculatePer100g(calories);
  int get proteinPer100g => calculatePer100g(protein);
  int get fatPer100g => calculatePer100g(fat);
  int get carbsPer100g => calculatePer100g(carbs);

  int get prepTime {
    if (_prepTime != null) return _prepTime!;
    if (steps.isEmpty) return 30;

    
    return steps.length * 10; 
  }

  
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
    try {
      List<String> imageUrls = [];
      if (json['images'] != null && json['images'] is List) {
        imageUrls = (json['images'] as List)
            .map((imageJson) {
          if (imageJson is Map<String, dynamic> && imageJson['img_url'] != null) {
            return imageJson['img_url'] as String;
          }
          return null;
        })
            .where((url) => url != null)
            .cast<String>()
            .toList();
      }


      List<RecipeStepIngredient> ingredients = [];
      if (json['ingredients'] != null && json['ingredients'] is List) {
        ingredients = (json['ingredients'] as List)
            .map((ingredientJson) {
          try {
            return RecipeStepIngredient.fromJson(ingredientJson);
          } catch (e) {
            print("Error parsing step ingredient: $e");
            return null;
          }
        })
            .where((ingredient) => ingredient != null)
            .cast<RecipeStepIngredient>()
            .toList();
      }

      return RecipeStep(
        id: json['stp_id'] ?? 0,
        recipeId: json['stp_rcp_id'] ?? 0,
        title: json['stp_title'] ?? '',
        instruction: json['stp_instruction'] ?? '',
        imageUrls: imageUrls,
        ingredients: ingredients,
      );
    } catch (e) {
      print("Error parsing RecipeStep: $e");
      print("JSON data: $json");
      throw FormatException('Ошибка при парсинге шага рецепта: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'stp_id': id,
      'stp_rcp_id': recipeId,
      'stp_title': title,
      'stp_instruction': instruction,
      'images': imageUrls.map((url) => {'img_url': url}).toList(),
      'ingredients': ingredients.map((ingredient) => ingredient.toJson()).toList(),
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

  
  IngredientType? ingredientType;

  RecipeIngredient({
    required this.recipeId,
    required this.ingredientTypeId,
    this.quantity,
    this.quantityType,
    this.ingredientType,
  });

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

  String? get formattedQuantity {
    if (quantity == null || quantityType == null) return null;
    return '$quantity ${quantityType!.getShortName()}';
  }

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
    try {
      IngredientType? ingredientType;
      if (json['ingredient_type'] != null && json['ingredient_type'] is Map<String, dynamic>) {
        try {
          ingredientType = IngredientType.fromJson(json['ingredient_type']);
        } catch (e) {
          print("Error parsing ingredient_type: $e");
          ingredientType = null;
        }
      }

      int quantity = 0;
      try {
        var quantityValue = json['msi_quantity'] ?? 0;
        if (quantityValue is String) {
          quantity = int.tryParse(quantityValue) ?? 0;
        } else {
          quantity = quantityValue is int ? quantityValue : 0;
        }
      } catch (e) {
        print("Error parsing quantity: $e");
        quantity = 0;
      }

      QuantityType quantityType = QuantityType.grams;
      try {
        var quantityTypeValue = json['msi_quantity_type'] ?? 'grams';
        quantityType = QuantityType.fromString(quantityTypeValue);
      } catch (e) {
        print("Error parsing quantity type: $e");
        quantityType = QuantityType.grams;
      }

      return RecipeStepIngredient(
        id: json['msi_id'] ?? 0,
        stepId: json['msi_stp_id'] ?? 0,
        ingredientTypeId: json['msi_igt_id'] ?? ingredientType?.id ?? 0,
        quantity: quantity,
        quantityType: quantityType,
        ingredientType: ingredientType,
      );
    } catch (e) {
      print("Error parsing RecipeStepIngredient: $e");
      print("JSON data: $json");
      throw FormatException('Ошибка при парсинге ингредиента шага: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'msi_id': id,
      'msi_stp_id': stepId,
      'msi_igt_id': ingredientTypeId,
      'msi_quantity': quantity,
      'msi_quantity_type': quantityType.toString().split('.').last,
      if (ingredientType != null) 'ingredient_type': ingredientType!.toJson(),
    };
  }

  String get formattedQuantity {
    return '$quantity ${quantityType.getShortName()}';
  }

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