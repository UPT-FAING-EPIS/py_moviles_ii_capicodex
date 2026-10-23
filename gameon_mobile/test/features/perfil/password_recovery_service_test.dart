import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gameon/features/perfil/services/password_recovery_service.dart';

PasswordRecoveryService service(
  Future<http.Response> Function(http.Request) handler,
) => PasswordRecoveryService(
  supabaseUrl: 'https://example.supabase.co',
  anonKey: 'public-test-key',
  client: MockClient(handler),
);

void main() {
  for (final status in [200, 400, 404, 422]) {
    test(
      'solicitud responde igual sin revelar la cuenta con HTTP $status',
      () async {
        final s = service((r) async {
          expect(r.url.path, '/auth/v1/recover');
          expect(jsonDecode(r.body), {'email': 'persona@example.com'});
          return http.Response('{}', status);
        });
        await s.solicitarCodigo(' persona@example.com ');
        s.dispose();
      },
    );
  }
  test(
    'respeta límite de intentos sin exponer la respuesta del servidor',
    () async {
      final s = service((_) async => http.Response('detalles privados', 429));
      await expectLater(
        s.solicitarCodigo('persona@example.com'),
        throwsA(
          isA<RecoveryException>().having(
            (e) => e.message,
            'mensaje',
            contains('Espera'),
          ),
        ),
      );
      s.dispose();
    },
  );
  test('no cambia contraseña con token inválido o expirado', () async {
    var requests = 0;
    final s = service((r) async {
      requests++;
      expect(r.url.path, '/auth/v1/verify');
      expect(jsonDecode(r.body)['type'], 'recovery');
      return http.Response('{"error":"expired"}', 403);
    });
    await expectLater(
      s.confirmarCambio(
        email: 'persona@example.com',
        codigo: '123456',
        password: 'NuevaClave123!',
      ),
      throwsA(isA<RecoveryException>()),
    );
    expect(requests, 1);
    s.dispose();
  });
  test(
    'verifica token antes de actualizar y revoca solo la sesión temporal',
    () async {
      final paths = <String>[];
      final s = service((r) async {
        paths.add(r.url.path);
        if (r.url.path.endsWith('verify')) {
          expect(jsonDecode(r.body), {
            'email': 'persona@example.com',
            'token': '123456',
            'type': 'recovery',
          });
          return http.Response('{"access_token":"temporary-token"}', 200);
        }
        expect(r.headers['Authorization'], 'Bearer temporary-token');
        if (r.url.path.endsWith('user')) {
          expect(r.method, 'PUT');
          expect(jsonDecode(r.body), {'password': ' Clave con espacios '});
        } else {
          expect(r.url.queryParameters['scope'], 'local');
        }
        return http.Response('{}', 200);
      });
      await s.confirmarCambio(
        email: 'persona@example.com',
        codigo: '123456',
        password: ' Clave con espacios ',
      );
      expect(paths, ['/auth/v1/verify', '/auth/v1/user', '/auth/v1/logout']);
      s.dispose();
    },
  );
  test('si falla el cambio, también limpia la sesión temporal', () async {
    final paths = <String>[];
    final s = service((r) async {
      paths.add(r.url.path);
      if (r.url.path.endsWith('verify')) {
        return http.Response('{"access_token":"temporary-token"}', 200);
      }
      return http.Response('{}', r.url.path.endsWith('user') ? 422 : 200);
    });
    await expectLater(
      s.confirmarCambio(
        email: 'persona@example.com',
        codigo: '123456',
        password: 'Clave123!',
      ),
      throwsA(isA<RecoveryException>()),
    );
    expect(paths.last, '/auth/v1/logout');
    s.dispose();
  });
  test('no expone excepciones técnicas ni tokens en errores de red', () async {
    final s = service((_) async => throw Exception('secret-token'));
    await expectLater(
      s.solicitarCodigo('persona@example.com'),
      throwsA(
        isA<RecoveryException>().having(
          (e) => e.message,
          'mensaje',
          isNot(contains('secret-token')),
        ),
      ),
    );
    s.dispose();
  });
}
