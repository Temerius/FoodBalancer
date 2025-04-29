class User {
  final int? id;
  final String name;
  final String email;
  final int? height;
  final int? weight;
  final int? age;
  final String? gender;
  final int? caloriesPerDay;
  final List<int>? allergenIds; // IDs аллергенов
  final List<int>? equipmentIds; // IDs оборудования

  User({
    this.id,
    required this.name,
    required this.email,
    this.height,
    this.weight,
    this.age,
    this.gender,
    this.caloriesPerDay,
    this.allergenIds,
    this.equipmentIds,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['usr_id'],
      name: json['usr_name'] ?? '',
      email: json['usr_mail'] ?? '',
      height: json['usr_height'],
      weight: json['usr_weight'],
      age: json['usr_age'],
      gender: json['usr_gender'],
      caloriesPerDay: json['usr_cal_day'],
      allergenIds: json['allergenIds'] != null
          ? List<int>.from(json['allergenIds'])
          : null,
      equipmentIds: json['equipmentIds'] != null
          ? List<int>.from(json['equipmentIds'])
          : null,
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
      if (gender != null) 'usr_gender': gender,
      if (caloriesPerDay != null) 'usr_cal_day': caloriesPerDay,
      if (allergenIds != null) 'allergenIds': allergenIds,
      if (equipmentIds != null) 'equipmentIds': equipmentIds,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    int? height,
    int? weight,
    int? age,
    String? gender,
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