import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeatherState { clear, rainy, hot }

class AppSettings extends ChangeNotifier {
  static const _themePrefKey = 'app_theme_dark';

  ThemeMode _themeMode = ThemeMode.light;
  WeatherState _weatherState = WeatherState.clear;

  ThemeMode get themeMode => _themeMode;
  WeatherState get weatherState => _weatherState;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Call once at app startup to restore saved theme preference.
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_themePrefKey) ?? false;
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Toggle light/dark and persist the choice.
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, isDarkMode);
  }

  void setWeather(WeatherState state) {
    _weatherState = state;
    notifyListeners();
  }
}
