import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.red,
    scaffoldBackgroundColor: Colors.red,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.red,
      onPrimary: Colors.white,
      secondary: Colors.redAccent,
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF212121),
      outlineVariant: Color(0xFFE0E0E0),
      scrim: Colors.black54,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.red,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.red,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.white,
      onPrimary: Colors.white,
      secondary: Colors.redAccent,
      onSecondary: Colors.greenAccent,
      error: Colors.redAccent,
      onError: Colors.redAccent,
      surface: Color(0xFF1A1A2E),
      onSurface: Colors.white,
      outlineVariant: Color(0xFF16213E),
      scrim: Color(0xFF0F3460),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF16213E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF16213E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF16213E),
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
  );

  static const Map<String, Color> typeColors = {
    'Normal': Color(0xFFA8A878),
    'Fire': Color(0xFFF08030),
    'Water': Color(0xFF6890F0),
    'Electric': Color(0xFFF8D030),
    'Grass': Color(0xFF78C850),
    'Ice': Color(0xFF98D8D8),
    'Fighting': Color(0xFFC03028),
    'Poison': Color(0xFFA040A0),
    'Ground': Color(0xFFE0C068),
    'Flying': Color(0xFFA890F0),
    'Psychic': Color(0xFFF85888),
    'Bug': Color(0xFFA8B820),
    'Rock': Color(0xFFB8A038),
    'Ghost': Color(0xFF705898),
    'Dragon': Color(0xFF7038F8),
    'Dark': Color(0xFF705848),
    'Steel': Color(0xFFB8B8D0),
    'Fairy': Color(0xFFEE99AC),
  };
}
