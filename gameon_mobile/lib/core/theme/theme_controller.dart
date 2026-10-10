import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// Persiste la preferencia visual elegida desde el perfil.
class ThemeController extends ChangeNotifier {
  static const _preferenceKey = 'visual_theme';
  AppVisualTheme _selection = AppVisualTheme.light;

  AppVisualTheme get selection => _selection;
  bool get isDarkMode => _selection == AppVisualTheme.dark;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_preferenceKey);
    final legacyDarkMode = preferences.getBool('dark_mode_enabled');
    _selection = AppVisualTheme.values.where((item) => item.name == saved).firstOrNull ??
        (legacyDarkMode == true ? AppVisualTheme.dark : AppVisualTheme.light);
    notifyListeners();
  }

  Future<void> select(AppVisualTheme selection) async {
    _selection = selection;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, selection.name);
  }
}
