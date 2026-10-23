import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gameon/features/perfil/services/password_recovery_service.dart';
import 'package:gameon/features/perfil/views/password_recovery_view.dart';

void main() {
  testWidgets('valida el correo antes de solicitar el código', (tester) async {
    var requests = 0;
    final s = PasswordRecoveryService(
      supabaseUrl: 'https://example.supabase.co',
      anonKey: 'test',
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: PasswordRecoveryView(service: s)),
    );
    await tester.tap(find.text('Solicitar código'));
    await tester.pump();
    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(requests, 0);
    s.dispose();
  });
  testWidgets('muestra confirmación genérica y exige contraseñas iguales', (
    tester,
  ) async {
    var requests = 0;
    final s = PasswordRecoveryService(
      supabaseUrl: 'https://example.supabase.co',
      anonKey: 'test',
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PasswordRecoveryView(
          initialEmail: 'persona@example.com',
          service: s,
        ),
      ),
    );
    await tester.tap(find.text('Solicitar código'));
    await tester.pumpAndSettle();
    expect(find.text(PasswordRecoveryService.mensajeEnvio), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código del correo'),
      '123456',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nueva contraseña'),
      'Clave123!',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar contraseña'),
      'Distinta123!',
    );
    await tester.ensureVisible(find.text('Cambiar contraseña'));
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(requests, 1);
    s.dispose();
  });
}
