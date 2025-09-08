import 'package:flutter/material.dart';

class AppTheme {
  // Основні кольори
  static const Color primaryColor = Color(0xFF8B0000); // Темно-червоний
  static const Color primaryLightColor = Color(
    0xFFB22222,
  ); // Світліший червоний
  static const Color primaryDarkColor = Color(0xFF660000); // Темніший червоний

  // Додаткові кольори
  static const Color secondaryColor = Color(0xFF2E8B57); // Морська зелень
  static const Color accentColor = Color(0xFFFFD700); // Золотий

  // Світла тема
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      primaryContainer: primaryLightColor,
      secondary: secondaryColor,
      secondaryContainer: Color(0xFF98FB98),
      surface: Colors.white,
      background: Color(0xFFF5F5F5),
      error: Color(0xFFB71C1C),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1C1C1C),
      onBackground: Color(0xFF1C1C1C),
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: primaryColor),
    ),
  );

  // Темна тема
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: primaryDarkColor,
      secondary: secondaryColor,
      secondaryContainer: Color(0xFF2E8B57),
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      error: Color(0xFFCF6679),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Color(0xFF000000),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDarkColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2D2D2D),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: primaryColor),
      fillColor: const Color(0xFF2D2D2D),
      filled: true,
    ),
  );
}
