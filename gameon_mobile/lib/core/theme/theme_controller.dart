import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';

/// Persiste la preferencia visual elegida desde el perfil.
class ThemeController extends ChangeNotifier {
  static const _preferenceKey = 'visual_theme';
  static const _legacyOwnerKey = 'visual_theme_owner';
  AppVisualTheme _selection = AppVisualTheme.light;
  StreamSubscription<AuthState>? _authSubscription;
  int _loadVersion = 0;

  ThemeController() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      _,
    ) {
      load();
    });
  }

  String _keyFor(String? userId) =>
      userId == null ? '${_preferenceKey}_guest' : '${_preferenceKey}_$userId';

  AppVisualTheme get selection => _selection;
  bool get isDarkMode => _selection == AppVisualTheme.dark;

  Future<void> load() async {
    final version = ++_loadVersion;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final preferences = await SharedPreferences.getInstance();
    var saved = preferences.getString(_keyFor(uid));
    if (saved == null && preferences.getString(_legacyOwnerKey) == null) {
      saved = preferences.getString(_preferenceKey);
      if (uid != null && saved != null) {
        await preferences.setString(_keyFor(uid), saved);
        await preferences.setString(_legacyOwnerKey, uid);
      }
    }
    if (version != _loadVersion) return;
    final legacyDarkMode =
        uid == null || preferences.getString(_legacyOwnerKey) == null
        ? preferences.getBool('dark_mode_enabled')
        : false;
    _selection =
        AppVisualTheme.values.where((item) => item.name == saved).firstOrNull ??
        (legacyDarkMode == true ? AppVisualTheme.dark : AppVisualTheme.light);
    notifyListeners();
  }

  Future<void> select(AppVisualTheme selection) async {
    ++_loadVersion;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    _selection = selection;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_keyFor(uid), selection.name);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
