class IngredientType {
  final int id;
  final String name;
  final String? imageUrl;
  String? category; // Added for categorization (like 'Овощи', 'Фрукты', etc.)

  IngredientType({
    required this.id,
    required this.name,
    this.imageUrl,
    this.category,
  });

  factory IngredientType.fromJson(Map<String, dynamic> json) {
    return IngredientType(
      id: json['igt_id'],
      name: json['igt_name'] ?? '',
      imageUrl: json['igt_img_url'],
      category: json['category'], // May come from external mapping or API extension
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'igt_id': id,
      'igt_name': name,
      if (imageUrl != null) 'igt_img_url': imageUrl,
      if (category != null) 'category': category,
    };
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
      category: category ?? this.category,
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