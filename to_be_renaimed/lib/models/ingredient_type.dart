class IngredientType {
  final int id;
  final String name;
  final String? imageUrl;

  String? _category;

  IngredientType({
    required this.id,
    required this.name,
    this.imageUrl,
    String? category,
  }) {
    _category = category;
  }

  factory IngredientType.fromJson(Map<String, dynamic> json) {
    return IngredientType(
      id: json['igt_id'],
      name: json['igt_name'] ?? '',
      imageUrl: json['igt_img_url'],
      category: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'igt_id': id,
      'igt_name': name,
      if (imageUrl != null) 'igt_img_url': imageUrl,
    };
  }

  String? get category => _category;

  set category(String? value) {
    _category = value;
  }

  void determineCategory() {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('овощ') ||
        lowerName.contains('картош') ||
        lowerName.contains('морков') ||
        lowerName.contains('лук') ||
        lowerName.contains('помидор') ||
        lowerName.contains('огурец')) {
      _category = 'Овощи';
    } else if (lowerName.contains('фрукт') ||
        lowerName.contains('яблок') ||
        lowerName.contains('груш') ||
        lowerName.contains('банан')) {
      _category = 'Фрукты';
    } else if (lowerName.contains('мясо') ||
        lowerName.contains('курица') ||
        lowerName.contains('говядин') ||
        lowerName.contains('свинин')) {
      _category = 'Мясо';
    } else if (lowerName.contains('молок') ||
        lowerName.contains('сыр') ||
        lowerName.contains('творог') ||
        lowerName.contains('йогурт')) {
      _category = 'Молочные';
    } else if (lowerName.contains('крупа') ||
        lowerName.contains('рис') ||
        lowerName.contains('гречк') ||
        lowerName.contains('овес')) {
      _category = 'Крупы';
    } else if (lowerName.contains('напит') ||
        lowerName.contains('вода') ||
        lowerName.contains('сок')) {
      _category = 'Напитки';
    } else {
      _category = 'Другое';
    }
  }

  IngredientType copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? category,
  }) {
    return IngredientType(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? _category,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is IngredientType &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}