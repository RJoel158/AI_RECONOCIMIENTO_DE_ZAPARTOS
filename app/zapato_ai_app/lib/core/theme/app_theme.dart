import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ink = Color(0xFF101010);
  static const Color bone = Color(0xFFF7F5F1);
  static const Color fog = Color(0xFFEBE7E0);
  static const Color citrus = Color(0xFFE5A23A);
  static const Color teal = Color(0xFF0E8A7C);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF6F6A64);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ink,
      scaffoldBackgroundColor: bone,
      colorScheme: ColorScheme.light(
        primary: ink,
        secondary: teal,
        surface: bone,
        onSurface: ink,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.8,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyMedium: const TextStyle(fontSize: 14, color: textLight),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bone,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: bone,
      scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.dark(
        primary: bone,
        secondary: teal,
        surface: ink,
        background: ink,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: bone,
          letterSpacing: -0.8,
        ),
        bodyMedium: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ink,
        foregroundColor: bone,
        elevation: 0,
      ),
    );
  }
}
