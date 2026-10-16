import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/perfil/services/session_local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el cierre limpia el identificador local de la cuenta', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = SessionLocalStorage();
    await storage.saveAuthenticatedUserId('usuario-123');

    expect(await storage.readAuthenticatedUserId(), 'usuario-123');
    await storage.clearAuthenticatedUserId();
    expect(await storage.readAuthenticatedUserId(), isNull);
  });

  test('la limpieza no borra preferencias ajenas a la sesión', () async {
    SharedPreferences.setMockInitialValues({'notifications_sound': false});
    final storage = SessionLocalStorage();
    await storage.saveAuthenticatedUserId('usuario-123');

    await storage.clearAuthenticatedUserId();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('notifications_sound'), isFalse);
    expect(await storage.readAuthenticatedUserId(), isNull);
  });
}
