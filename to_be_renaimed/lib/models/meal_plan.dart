import 'package:to_be_renaimed/models/enums.dart';
import 'package:to_be_renaimed/models/ingredient.dart';
import 'package:to_be_renaimed/models/recipe.dart';

class WeeklyMealPlan {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final int userId;

  
  List<DailyMealPlan> dailyPlans = [];

  WeeklyMealPlan({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.userId,
    List<DailyMealPlan>? dailyPlans,
  }) : dailyPlans = dailyPlans ?? [];

  factory WeeklyMealPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyMealPlan(
      id: json['wmp_id'],
      startDate: DateTime.parse(json['wmp_start']),
      endDate: DateTime.parse(json['wmp_end']),
      userId: json['wmp_usr_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wmp_id': id,
      'wmp_start': startDate.toIso8601String().split('T')[0],
      'wmp_end': endDate.toIso8601String().split('T')[0],
      'wmp_usr_id': userId,
    };
  }

  
  bool containsDate(DateTime date) {
    final dayOnly = DateTime(date.year, date.month, date.day);
    return !dayOnly.isBefore(startDate) && !dayOnly.isAfter(endDate);
  }

  
  DailyMealPlan? getDailyPlan(DateTime date) {
    final dayOnly = DateTime(date.year, date.month, date.day);
    return dailyPlans.firstWhere(
          (plan) => plan.date.year == dayOnly.year &&
          plan.date.month == dayOnly.month &&
          plan.date.day == dayOnly.day,
      orElse: () => throw Exception('No meal plan for this date'),
    );
  }

  WeeklyMealPlan copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
    List<DailyMealPlan>? dailyPlans,
  }) {
    return WeeklyMealPlan(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
      dailyPlans: dailyPlans ?? List.from(this.dailyPlans),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WeeklyMealPlan &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DailyMealPlan {
  final int id;
  final DateTime date;
  final int caloriesPerDay;
  final int weeklyMealPlanId;

  
  List<Meal> meals = [];
  List<DailyMealPlanIngredient> ingredients = [];

  DailyMealPlan({
    required this.id,
    required this.date,
    required this.caloriesPerDay,
    required this.weeklyMealPlanId,
    List<Meal>? meals,
    List<DailyMealPlanIngredient>? ingredients,
  }) :
        meals = meals ?? [],
        ingredients = ingredients ?? [];

  factory DailyMealPlan.fromJson(Map<String, dynamic> json) {
    return DailyMealPlan(
      id: json['dmp_id'],
      date: DateTime.parse(json['dmp_date']),
      caloriesPerDay: json['dmp_cal_day'] ?? 0,
      weeklyMealPlanId: json['dmp_wmp_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dmp_id': id,
      'dmp_date': date.toIso8601String().split('T')[0],
      'dmp_cal_day': caloriesPerDay,
      'dmp_wmp_id': weeklyMealPlanId,
    };
  }

  
  int get totalCalories {
    int total = 0;
    for (var meal in meals) {
      for (var recipe in meal.recipes) {
        if (recipe.recipe != null) {
          total += recipe.recipe!.calories;
        }
      }
    }
    return total;
  }

  DailyMealPlan copyWith({
    int? id,
    DateTime? date,
    int? caloriesPerDay,
    int? weeklyMealPlanId,
    List<Meal>? meals,
    List<DailyMealPlanIngredient>? ingredients,
  }) {
    return DailyMealPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      caloriesPerDay: caloriesPerDay ?? this.caloriesPerDay,
      weeklyMealPlanId: weeklyMealPlanId ?? this.weeklyMealPlanId,
      meals: meals ?? List.from(this.meals),
      ingredients: ingredients ?? List.from(this.ingredients),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DailyMealPlan &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DailyMealPlanIngredient {
  final int dailyMealPlanId;
  final int ingredientId;
  final int quantity;
  final QuantityType quantityType;

  
  Ingredient? ingredient;

  DailyMealPlanIngredient({
    required this.dailyMealPlanId,
    required this.ingredientId,
    required this.quantity,
    required this.quantityType,
    this.ingredient,
  });

  factory DailyMealPlanIngredient.fromJson(Map<String, dynamic> json) {
    return DailyMealPlanIngredient(
      dailyMealPlanId: json['mid_dmp_id'],
      ingredientId: json['mid_ing_id'],
      quantity: json['mid_quantity'] ?? 0,
      quantityType: QuantityType.fromString(json['mid_quantity_type'] ?? 'grams'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mid_dmp_id': dailyMealPlanId,
      'mid_ing_id': ingredientId,
      'mid_quantity': quantity,
      'mid_quantity_type': quantityType.toString().split('.').last,
    };
  }

  
  String get formattedQuantity {
    return '$quantity ${quantityType.getShortName()}';
  }

  DailyMealPlanIngredient copyWith({
    int? dailyMealPlanId,
    int? ingredientId,
    int? quantity,
    QuantityType? quantityType,
    Ingredient? ingredient,
  }) {
    return DailyMealPlanIngredient(
      dailyMealPlanId: dailyMealPlanId ?? this.dailyMealPlanId,
      ingredientId: ingredientId ?? this.ingredientId,
      quantity: quantity ?? this.quantity,
      quantityType: quantityType ?? this.quantityType,
      ingredient: ingredient ?? this.ingredient,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DailyMealPlanIngredient &&
              runtimeType == other.runtimeType &&
              dailyMealPlanId == other.dailyMealPlanId &&
              ingredientId == other.ingredientId;

  @override
  int get hashCode => Object.hash(dailyMealPlanId, ingredientId);
}

class Meal {
  final int id;
  final DateTime date;
  final int userId;
  final String type;
  final String time;

  
  List<MealRecipe> recipes = [];
  List<MealIngredient> ingredients = [];

  Meal({
    required this.id,
    required this.date,
    required this.userId,
    required this.type,
    required this.time,
    List<MealRecipe>? recipes,
    List<MealIngredient>? ingredients,
  }) :
        recipes = recipes ?? [],
        ingredients = ingredients ?? [];

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['adm_id'],
      date: DateTime.parse(json['adm_date']),
      userId: json['adm_usr_id'],
      type: json['type'] ?? 'Прием пищи',
      time: json['time'] ?? '12:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adm_id': id,
      'adm_date': date.toIso8601String().split('T')[0],
      'adm_usr_id': userId,
      'type': type,
      'time': time,
    };
  }

  
  int get totalCalories {
    int total = 0;
    for (var recipe in recipes) {
      if (recipe.recipe != null) {
        total += recipe.recipe!.calories;
      }
    }
    for (var ingredient in ingredients) {
      if (ingredient.ingredient != null) {
        
        final baseCalories = ingredient.ingredient!.calories;
        final baseWeight = ingredient.ingredient!.weight;
        if (baseWeight > 0 && ingredient.quantity > 0) {
          total += (baseCalories * ingredient.quantity) ~/ baseWeight;
        }
      }
    }
    return total;
  }

  Meal copyWith({
    int? id,
    DateTime? date,
    int? userId,
    String? type,
    String? time,
    List<MealRecipe>? recipes,
    List<MealIngredient>? ingredients,
  }) {
    return Meal(
      id: id ?? this.id,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      time: time ?? this.time,
      recipes: recipes ?? List.from(this.recipes),
      ingredients: ingredients ?? List.from(this.ingredients),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Meal &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MealRecipe {
  final int mealId;
  final int recipeId;

  
  Recipe? recipe;

  MealRecipe({
    required this.mealId,
    required this.recipeId,
    this.recipe,
  });

  factory MealRecipe.fromJson(Map<String, dynamic> json) {
    return MealRecipe(
      mealId: json['mra_adm_id'],
      recipeId: json['mra_rcp_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mra_adm_id': mealId,
      'mra_rcp_id': recipeId,
    };
  }

  MealRecipe copyWith({
    int? mealId,
    int? recipeId,
    Recipe? recipe,
  }) {
    return MealRecipe(
      mealId: mealId ?? this.mealId,
      recipeId: recipeId ?? this.recipeId,
      recipe: recipe ?? this.recipe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MealRecipe &&
              runtimeType == other.runtimeType &&
              mealId == other.mealId &&
              recipeId == other.recipeId;

  @override
  int get hashCode => Object.hash(mealId, recipeId);
}

class MealIngredient {
  final int mealId;
  final int ingredientId;
  final int quantity;
  final QuantityType quantityType;

  
  Ingredient? ingredient;

  MealIngredient({
    required this.mealId,
    required this.ingredientId,
    required this.quantity,
    required this.quantityType,
    this.ingredient,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> json) {
    return MealIngredient(
      mealId: json['mia_adm_id'],
      ingredientId: json['mia_ing_id'],
      quantity: json['mia_quantity'] ?? 0,
      quantityType: QuantityType.fromString(json['mia_quantity_type'] ?? 'grams'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mia_adm_id': mealId,
      'mia_ing_id': ingredientId,
      'mia_quantity': quantity,
      'mia_quantity_type': quantityType.toString().split('.').last,
    };
  }

  
  String get formattedQuantity {
    return '$quantity ${quantityType.getShortName()}';
  }

  MealIngredient copyWith({
    int? mealId,
    int? ingredientId,
    int? quantity,
    QuantityType? quantityType,
    Ingredient? ingredient,
  }) {
    return MealIngredient(
      mealId: mealId ?? this.mealId,
      ingredientId: ingredientId ?? this.ingredientId,
      quantity: quantity ?? this.quantity,
      quantityType: quantityType ?? this.quantityType,
      ingredient: ingredient ?? this.ingredient,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MealIngredient &&
              runtimeType == other.runtimeType &&
              mealId == other.mealId &&
              ingredientId == other.ingredientId;

  @override
  int get hashCode => Object.hash(mealId, ingredientId);
}