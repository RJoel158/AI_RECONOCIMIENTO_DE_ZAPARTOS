import 'package:flutter/material.dart';
import 'screens/welcome/welcome_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHOESLY - Reconocimiento de Calzado',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Seguir el modo del sistema
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false, // Ocultar banner de debug
    );
  }
}