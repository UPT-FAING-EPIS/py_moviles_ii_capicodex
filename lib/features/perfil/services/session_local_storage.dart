import 'package:shared_preferences/shared_preferences.dart';

/// Guarda únicamente el identificador de la sesión autenticada.
/// El token sigue siendo administrado y persistido por Supabase Flutter.
class SessionLocalStorage {
  static const _authIdKey = 'authenticated_user_id';

  Future<void> saveAuthenticatedUserId(String authId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_authIdKey, authId);
  }

  Future<String?> readAuthenticatedUserId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_authIdKey);
  }

  Future<void> clearAuthenticatedUserId() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_authIdKey);
  }
}
