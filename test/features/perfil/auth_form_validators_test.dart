import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/perfil/services/auth_form_validators.dart';

void main() {
  group('inicio de sesión', () {
    test(
      'rechaza correo o contraseña ausentes antes de consultar el servidor',
      () {
        expect(AuthFormValidators.correo('  '), 'Ingresa tu correo');
        expect(AuthFormValidators.contrasena(null), 'Ingresa tu contraseña');
      },
    );

    test('rechaza correo inválido y contraseña corta', () {
      expect(
        AuthFormValidators.correo('persona.example.com'),
        'Correo inválido',
      );
      expect(AuthFormValidators.contrasena('12345'), 'Mínimo 6 caracteres');
    });

    test('acepta credenciales con el formato esperado', () {
      expect(AuthFormValidators.correo(' persona@example.com '), isNull);
      expect(AuthFormValidators.contrasena('clave-segura'), isNull);
    });
  });

  group('registro', () {
    test('rechaza nombre demasiado corto y confirmación diferente', () {
      expect(
        AuthFormValidators.nombre(' Jo '),
        'El nombre debe tener al menos 3 caracteres',
      );
      expect(
        AuthFormValidators.confirmarContrasena('otra-clave', 'clave-segura'),
        'Las contraseñas no coinciden',
      );
    });

    test('acepta nombre, correo y contraseña coincidente', () {
      expect(AuthFormValidators.nombre(' Gabriela '), isNull);
      expect(AuthFormValidators.correo('gabriela@example.com'), isNull);
      expect(AuthFormValidators.contrasena('clave-segura'), isNull);
      expect(
        AuthFormValidators.confirmarContrasena('clave-segura', 'clave-segura'),
        isNull,
      );
    });
  });
}
