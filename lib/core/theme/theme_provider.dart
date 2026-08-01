import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'mwallet_theme_mode';
  static const String _keyDensityMode = 'mwallet_density_mode';

  ThemeMode _themeMode = ThemeMode.dark;
  bool _isCompactDensity = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isCompactDensity => _isCompactDensity;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_keyThemeMode) ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _isCompactDensity = prefs.getBool(_keyDensityMode) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyThemeMode, _themeMode == ThemeMode.dark);
  }

  Future<void> toggleDensity() async {
    _isCompactDensity = !_isCompactDensity;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDensityMode, _isCompactDensity);
  }
}
