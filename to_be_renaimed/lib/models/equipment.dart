class Equipment {
  final int id;
  final String type;
  final int power;
  final int capacity;
  final String? imageUrl;
  bool isSelected; // Local property for UI state
  String? customName; // For user-added equipment names

  Equipment({
    required this.id,
    required this.type,
    required this.power,
    required this.capacity,
    this.imageUrl,
    this.isSelected = false,
    this.customName,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['eqp_id'],
      type: json['eqp_type'] ?? '',
      power: json['eqp_power'] ?? 0,
      capacity: json['eqp_capacity'] ?? 0,
      imageUrl: json['eqp_img_url'],
      customName: json['custom_name'], // Optional field for user's custom naming
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eqp_id': id,
      'eqp_type': type,
      'eqp_power': power,
      'eqp_capacity': capacity,
      if (imageUrl != null) 'eqp_img_url': imageUrl,
      if (customName != null) 'custom_name': customName,
    };
  }

  String get displayName => customName ?? type;

  Equipment copyWith({
    int? id,
    String? type,
    int? power,
    int? capacity,
    String? imageUrl,
    bool? isSelected,
    String? customName,
  }) {
    return Equipment(
      id: id ?? this.id,
      type: type ?? this.type,
      power: power ?? this.power,
      capacity: capacity ?? this.capacity,
      imageUrl: imageUrl ?? this.imageUrl,
      isSelected: isSelected ?? this.isSelected,
      customName: customName ?? this.customName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Equipment &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}