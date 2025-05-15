class DateFormatter {
  
  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  
  static String formatDateISO(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  
  static String formatDateFull(DateTime date) {
    final day = date.day;
    final month = _getMonthName(date.month);
    final year = date.year;
    return '$day $month $year';
  }

  
  static String formatDateShort(DateTime date) {
    final day = date.day;
    final month = _getMonthName(date.month);
    return '$day $month';
  }

  
  static String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'января';
      case 2:
        return 'февраля';
      case 3:
        return 'марта';
      case 4:
        return 'апреля';
      case 5:
        return 'мая';
      case 6:
        return 'июня';
      case 7:
        return 'июля';
      case 8:
        return 'августа';
      case 9:
        return 'сентября';
      case 10:
        return 'октября';
      case 11:
        return 'ноября';
      case 12:
        return 'декабря';
      default:
        return '';
    }
  }

  
  static String _getMonthShortName(int month) {
    switch (month) {
      case 1:
        return 'янв';
      case 2:
        return 'фев';
      case 3:
        return 'мар';
      case 4:
        return 'апр';
      case 5:
        return 'май';
      case 6:
        return 'июн';
      case 7:
        return 'июл';
      case 8:
        return 'авг';
      case 9:
        return 'сен';
      case 10:
        return 'окт';
      case 11:
        return 'ноя';
      case 12:
        return 'дек';
      default:
        return '';
    }
  }

  
  static String formatDateMonth(DateTime date) {
    final day = date.day;
    final month = _getMonthShortName(date.month);
    return '$day $month';
  }

  
  static String formatDateMonthYear(DateTime date) {
    final day = date.day;
    final month = _getMonthShortName(date.month);
    final year = date.year;
    return '$day $month $year';
  }
}