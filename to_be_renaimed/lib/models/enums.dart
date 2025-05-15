
enum QuantityType {
  grams,
  milliliters,
  liters,
  pieces,
  tablespoons,
  teaspoons,
  cups;

  factory QuantityType.fromString(String value) {
    return QuantityType.values.firstWhere(
          (e) => e.toString().split('.').last == value.toLowerCase(),
      orElse: () => QuantityType.grams,
    );
  }

  String toDisplayString() {
    switch (this) {
      case QuantityType.grams:
        return 'Граммы (г)';
      case QuantityType.milliliters:
        return 'Миллилитры (мл)';
      case QuantityType.liters:
        return 'Литры (л)';
      case QuantityType.pieces:
        return 'Штуки (шт)';
      case QuantityType.tablespoons:
        return 'Столовые ложки (ст. л.)';
      case QuantityType.teaspoons:
        return 'Чайные ложки (ч. л.)';
      case QuantityType.cups:
        return 'Стаканы';
    }
  }

  String getShortName() {
    switch (this) {
      case QuantityType.grams:
        return 'г';
      case QuantityType.milliliters:
        return 'мл';
      case QuantityType.liters:
        return 'л';
      case QuantityType.pieces:
        return 'шт';
      case QuantityType.tablespoons:
        return 'ст. л.';
      case QuantityType.teaspoons:
        return 'ч. л.';
      case QuantityType.cups:
        return 'стак.';
    }
  }
}


enum Gender {
  male,
  female;

  factory Gender.fromString(String value) {
    return Gender.values.firstWhere(
          (e) => e.toString().split('.').last == value.toLowerCase(),
      orElse: () => Gender.male,
    );
  }

  String toDisplayString() {
    switch (this) {
      case Gender.male:
        return 'Мужской';
      case Gender.female:
        return 'Женский';
    }
  }

  String toPostgreSqlValue() {
    final value = toString().split('.').last;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}