import 'package:flutter/material.dart';

class AppTheme {
  // Colors based on SHOESLY minimalist Figma design
  static const Color primaryBlack = Color(0xFF000000);
  static const Color secondaryWhite = Color(0xFFFFFFFF);
  static const Color accentGray = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlack,
      scaffoldBackgroundColor: secondaryWhite,
      colorScheme: ColorScheme.light(
        primary: primaryBlack,
        secondary: primaryBlack,
        surface: secondaryWhite,
        background: secondaryWhite,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
          letterSpacing: -1.0,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textDark,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textLight,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryWhite,
        foregroundColor: primaryBlack,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: secondaryWhite,
      scaffoldBackgroundColor: primaryBlack,
      colorScheme: ColorScheme.dark(
        primary: secondaryWhite,
        secondary: secondaryWhite,
        surface: primaryBlack,
        background: primaryBlack,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: secondaryWhite,
          letterSpacing: -1.0,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: secondaryWhite,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlack,
        foregroundColor: secondaryWhite,
        elevation: 0,
      ),
    );
  }
}
