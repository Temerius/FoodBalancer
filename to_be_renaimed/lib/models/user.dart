import 'package:to_be_renaimed/models/allergen.dart';
import 'package:to_be_renaimed/models/equipment.dart';
import 'package:to_be_renaimed/models/enums.dart';
import 'package:to_be_renaimed/models/ingredient.dart';
import 'package:to_be_renaimed/models/recipe.dart';
import 'package:to_be_renaimed/models/meal_plan.dart';
import 'package:to_be_renaimed/models/shopping_list.dart';

class User {
  final int? id;
  final String name;
  final String email;
  final int? height;
  final int? weight;
  final int? age;
  final Gender? gender;
  final int? caloriesPerDay;
  List<int> allergenIds = []; // Changed to be mutable with default empty list
  List<int> equipmentIds = []; // Changed to be mutable with default empty list

  // Runtime properties that will be filled after initial loading
  List<Allergen> allergens = [];
  List<Equipment> equipment = [];
  List<UserIngredient> refrigeratorItems = [];
  List<Recipe> favoriteRecipes = [];
  WeeklyMealPlan? currentMealPlan;
  ShoppingList? shoppingList;

  User({
    this.id,
    required this.name,
    required this.email,
    this.height,
    this.weight,
    this.age,
    this.gender,
    this.caloriesPerDay,
    List<int>? allergenIds,
    List<int>? equipmentIds,
  }) {
    this.allergenIds = allergenIds ?? [];
    this.equipmentIds = equipmentIds ?? [];
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['usr_id'],
      name: json['usr_name'] ?? '',
      email: json['usr_mail'] ?? '',
      height: json['usr_height'],
      weight: json['usr_weight'],
      age: json['usr_age'],
      gender: json['usr_gender'] != null
          ? Gender.fromString(json['usr_gender'])
          : null,
      caloriesPerDay: json['usr_cal_day'],
      allergenIds: json['allergenIds'] != null
          ? List<int>.from(json['allergenIds'])
          : [],
      equipmentIds: json['equipmentIds'] != null
          ? List<int>.from(json['equipmentIds'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'usr_id': id,
      'usr_name': name,
      'usr_mail': email,
      if (height != null) 'usr_height': height,
      if (weight != null) 'usr_weight': weight,
      if (age != null) 'usr_age': age,
      if (gender != null) 'usr_gender': gender.toString().split('.').last,
      if (caloriesPerDay != null) 'usr_cal_day': caloriesPerDay,
      'allergenIds': allergenIds,
      'equipmentIds': equipmentIds,
    };
  }

  // Calculate BMI (Body Mass Index)
  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }

  // Get BMI category
  String get bmiCategory {
    final currentBmi = bmi;
    if (currentBmi == null) return 'Неизвестно';

    if (currentBmi < 18.5) return 'Недостаточный вес';
    if (currentBmi < 25) return 'Нормальный вес';
    if (currentBmi < 30) return 'Избыточный вес';
    return 'Ожирение';
  }

  // Calculate daily calorie needs based on height, weight, age, gender
  int calculateDailyCalories() {
    if (height == null || weight == null || age == null || gender == null) {
      return 2000; // Default value
    }

    // Basic Harris-Benedict equation
    double bmr;
    if (gender == Gender.male) {
      bmr = 88.362 + (13.397 * weight!) + (4.799 * height!) - (5.677 * age!);
    } else {
      bmr = 447.593 + (9.247 * weight!) + (3.098 * height!) - (4.330 * age!);
    }

    // Assuming moderate activity level (1.55 multiplier)
    return (bmr * 1.55).round();
  }

  // Get expiring products in refrigerator (within 3 days)
  List<UserIngredient> get expiringProducts {
    final now = DateTime.now();
    return refrigeratorItems.where((item) {
      if (item.ingredient?.expiryDate == null) return false;

      final daysLeft = item.ingredient!.expiryDate!.difference(now).inDays;
      return daysLeft >= 0 && daysLeft <= 3;
    }).toList();
  }

  // Get daily meal plan for today
  DailyMealPlan? get todayMealPlan {
    if (currentMealPlan == null) return null;

    final today = DateTime.now();
    try {
      return currentMealPlan!.getDailyPlan(today);
    } catch (e) {
      return null;
    }
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    int? height,
    int? weight,
    int? age,
    Gender? gender,
    int? caloriesPerDay,
    List<int>? allergenIds,
    List<int>? equipmentIds,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      caloriesPerDay: caloriesPerDay ?? this.caloriesPerDay,
      allergenIds: allergenIds ?? this.allergenIds,
      equipmentIds: equipmentIds ?? this.equipmentIds,
    );
  }
}