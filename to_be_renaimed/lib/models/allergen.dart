class Allergen {
  final int id;
  final String name;
  bool isSelected;

  Allergen({
    required this.id,
    required this.name,
    this.isSelected = false,
  });

  factory Allergen.fromJson(Map<String, dynamic> json) {
    return Allergen(
      id: json['alg_id'],
      name: json['alg_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alg_id': id,
      'alg_name': name,
    };
  }

  Allergen copyWith({
    int? id,
    String? name,
    bool? isSelected,
  }) {
    return Allergen(
      id: id ?? this.id,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Allergen &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}