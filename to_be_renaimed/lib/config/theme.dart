  import 'package:flutter/material.dart';

  class AppColors {
    static const Color primaryBlue = Color(0xFF1A73E8);
    static const Color lightBlue = Color(0xFF4285F4);
    static const Color skyBlue = Color(0xFF8AB4F8);
    static const Color paleBlue = Color(0xFFD2E3FC);
    static const Color darkBlue = Color(0xFF0D47A1);

    static const Color background = Colors.white;
    static const Color surface = Colors.white;
    static const Color error = Color(0xFFB00020);

    static const Color textDark = Color(0xFF202124);
    static const Color textMedium = Color(0xFF5F6368);
    static const Color textLight = Color(0xFF9AA0A6);
  }


  final ThemeData appTheme = ThemeData(
    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: AppColors.background,

    colorScheme: ColorScheme(
      primary: AppColors.primaryBlue,
      primaryContainer: AppColors.darkBlue,
      secondary: AppColors.skyBlue,
      secondaryContainer: AppColors.paleBlue,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: AppColors.textDark,
      onSurface: AppColors.textDark,
      onBackground: AppColors.textDark,
      onError: Colors.white,
      brightness: Brightness.light,
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textMedium,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.textLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.textLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: AppColors.textLight),
      labelStyle: TextStyle(color: AppColors.textMedium),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );