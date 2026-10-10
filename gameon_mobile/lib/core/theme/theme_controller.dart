import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste la preferencia visual elegida desde el perfil.
class ThemeController extends ChangeNotifier {
  static const _preferenceKey = 'dark_mode_enabled';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDarkMode => _mode == ThemeMode.dark;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool(_preferenceKey);
    _mode = enabled == null
        ? ThemeMode.system
        : enabled
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _mode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, enabled);
  }
}
