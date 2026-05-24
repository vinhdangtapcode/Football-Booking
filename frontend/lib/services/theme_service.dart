import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = "theme_mode";
  bool _isModernMode = false;

  ThemeProvider() {
    _loadTheme();
  }

  bool get isModernMode => _isModernMode;

  ThemeData get themeData => _isModernMode ? modernTheme : lightTheme;

  Color get accentColor => _isModernMode ? const Color(0xFF00E676) : Colors.amber[800]!;

  void toggleTheme() async {
    _isModernMode = !_isModernMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isModernMode);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isModernMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  // Giao diện hiện tại (Light/Amber)
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.amber,
    primaryColor: Colors.amberAccent,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.amberAccent,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
    ),
  );

  // Giao diện Đen Trắng Hiện đại (Black & White Modern)
  static final ThemeData modernTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: const Color(0xFF0A0B0E),
    cardColor: const Color(0xFF16181D), // Đen xám nhẹ cho Card
    hintColor: Colors.grey,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0B0E),
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.white24,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white),
      ),
      labelStyle: TextStyle(color: Colors.white70),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white12,
      thickness: 0.5,
    ),
  );
}



