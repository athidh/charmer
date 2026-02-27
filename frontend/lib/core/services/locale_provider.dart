import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's current [Locale] and persists the choice via
/// shared_preferences so it survives app restarts.
class LocaleProvider extends ChangeNotifier {
  static const _prefKey = 'app_locale';

  /// Supported locales — English, Tamil (Kongu), Malayalam only.
  static const supportedLocales = [Locale('en'), Locale('ta'), Locale('ml')];

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  /// Call once at app startup (before runApp or in initState).
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// Change the locale and persist the choice.
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
  }
}
