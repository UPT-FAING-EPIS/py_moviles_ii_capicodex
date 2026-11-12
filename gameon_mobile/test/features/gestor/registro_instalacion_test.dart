import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/gestor/services/gestor_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _EmptyGotrueAsyncStorage extends GotrueAsyncStorage {
  const _EmptyGotrueAsyncStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}

void main() {
  group(
    'US-20: Como administrador quiero registrar una instalacion para publicarla en el catalogo',
    () {
      final datosValidos = <String, dynamic>{
        'nombre': 'Complejo Deportivo Los Olivos',
        'ruc': '20601234567',
        'direccion': 'Av. Bolognesi 1230, Tacna',
        'tarifa': 60.0,
        'telefono': '952123456',
        'email': 'admin@losolivos.pe',
        'descripcion': 'Canchas sinteticas iluminadas',
        'latitud': -18.006567,
        'longitud': -70.246274,
        'estado': 1,
      };

      test(
        'Rechaza el registro cuando el usuario no es un administrador autorizado (gestorId <= 0)',
        () {
          expect(
            () => GestorService.validarDatosInstalacion(0, datosValidos),
            throwsA(isA<StateError>()),
          );
          expect(
            () => GestorService.validarDatosInstalacion(-5, datosValidos),
            throwsA(isA<StateError>()),
          );
        },
      );

      test(
        'Rechaza el registro cuando faltan datos obligatorios o el contacto del administrador es invalido',
        () {
          expect(
            () => GestorService.validarDatosInstalacion(10, {
              ...datosValidos,
              'nombre': '   ',
            }),
            throwsArgumentError,
          );
          expect(
            () => GestorService.validarDatosInstalacion(10, {
              ...datosValidos,
              'direccion': '',
            }),
            throwsArgumentError,
          );
          expect(
            () => GestorService.validarDatosInstalacion(10, {
              ...datosValidos,
              'telefono': '123',
            }),
            throwsArgumentError,
          );
          expect(
            () => GestorService.validarDatosInstalacion(10, {
              ...datosValidos,
              'email': 'correo-invalido',
            }),
            throwsArgumentError,
          );
          expect(
            () => GestorService.validarDatosInstalacion(10, {
              ...datosValidos,
              'tarifa': 0,
            }),
            throwsArgumentError,
          );
          expect(
            () => GestorService.validarDatosInstalacion(10, {
              ...datosValidos,
              'ruc': '12345',
            }),
            throwsArgumentError,
          );
        },
      );

      test(
        'Valida que la ubicacion geografica este dentro de rangos reales y no sea nula',
        () {
          expect(GestorService.validarUbicacion(null, -70.24), isFalse);
          expect(GestorService.validarUbicacion(-18.00, null), isFalse);
          expect(GestorService.validarUbicacion(0, 0), isFalse);
          expect(GestorService.validarUbicacion(-95.0, -70.24), isFalse);
          expect(GestorService.validarUbicacion(-18.00, 190.0), isFalse);
          expect(
            GestorService.validarUbicacion(-18.006567, -70.246274),
            isTrue,
          );

          expect(
            () => GestorService.validarDatosInstalacion(10, {
              ...datosValidos,
              'latitud': null,
              'longitud': null,
            }),
            throwsArgumentError,
          );
        },
      );

      test(
        'Administrador autorizado registra instalacion con datos obligatorios y ubicacion valida en el catalogo',
        () async {
          Map<String, dynamic>? insertedPayload;

          final mockHttp = MockClient((request) async {
            if (request.url.path.endsWith('/instituciones_deportivas') &&
                request.method == 'POST') {
              final decoded = jsonDecode(request.body);
              insertedPayload = decoded is List
                  ? Map<String, dynamic>.from(decoded.first as Map)
                  : Map<String, dynamic>.from(decoded as Map);
              return http.Response(
                jsonEncode([insertedPayload]),
                201,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            return http.Response(
              jsonEncode([]),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          });

          final supabase = SupabaseClient(
            'https://example.supabase.co',
            'dummy-anon-key',
            authOptions: const AuthClientOptions(
              autoRefreshToken: false,
              pkceAsyncStorage: _EmptyGotrueAsyncStorage(),
            ),
            httpClient: mockHttp,
          );

          final service = GestorService(client: supabase);
          await service.guardarCentro(42, datosValidos);

          expect(insertedPayload, isNotNull);
          expect(insertedPayload!['usuario_instalacion_id'], 42);
          expect(
            insertedPayload!['nombre'],
            'Complejo Deportivo Los Olivos',
          );
          expect(insertedPayload!['direccion'], 'Av. Bolognesi 1230, Tacna');
          expect(insertedPayload!['telefono'], '952123456');
          expect(insertedPayload!['email'], 'admin@losolivos.pe');
          expect(insertedPayload!['latitud'], -18.006567);
          expect(insertedPayload!['longitud'], -70.246274);
          expect(insertedPayload!['estado'], 1);
        },
      );
    },
  );
}
