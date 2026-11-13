import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/gestor/services/gestor_service.dart';
import 'package:gameon/features/reservas/models/horario_area.dart';
import 'package:gameon/features/reservas/viewmodels/reserva_calendario_viewmodel.dart';
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

SupabaseClient _buildMockSupabase(
  Future<http.Response> Function(http.Request request) handler,
) {
  return SupabaseClient(
    'https://example.supabase.co',
    'dummy-anon-key',
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      pkceAsyncStorage: _EmptyGotrueAsyncStorage(),
    ),
    httpClient: MockClient(handler),
  );
}

void main() {
  group(
    'US-23: Como administrador quiero bloquear horarios no disponibles para evitar reservas invalidas',
    () {
      test(
        'Rechaza gestionar o bloquear horarios cuando la cuenta no es un administrador autorizado (gestorId <= 0)',
        () async {
          expect(
            () => GestorService.validarDatosHorario(0, {
              'area_deportiva_id': 10,
              'dia': 'lunes',
              'hora_apertura': '08:00:00',
              'hora_cierre': '22:00:00',
              'disponible': 0,
            }),
            throwsA(isA<StateError>()),
          );

          final supabase = _buildMockSupabase(
            (_) async => throw StateError('No debe consultar la red'),
          );
          addTearDown(supabase.dispose);
          final service = GestorService(client: supabase);

          await expectLater(
            service.cambiarDisponibilidadHorario(-1, {
              'id': 5,
              'area_deportiva_id': 10,
              'dia': 'lunes',
              'hora_apertura': '08:00:00',
              'hora_cierre': '22:00:00',
              'disponible': 1,
            }, false),
            throwsA(isA<StateError>()),
          );

          await expectLater(
            service.borrarHorario(5, gestorId: 0),
            throwsA(isA<StateError>()),
          );
        },
      );

      test(
        'Valida la integridad de area, dia de la semana y rango horario (apertura < cierre)',
        () {
          expect(
            () => GestorService.validarDatosHorario(10, {
              'area_deportiva_id': 0,
              'dia': 'lunes',
              'hora_apertura': '08:00:00',
              'hora_cierre': '22:00:00',
              'disponible': 0,
            }),
            throwsArgumentError,
          );
          expect(
            () => GestorService.validarDatosHorario(10, {
              'area_deportiva_id': 15,
              'dia': 'feriado',
              'hora_apertura': '08:00:00',
              'hora_cierre': '22:00:00',
              'disponible': 0,
            }),
            throwsArgumentError,
          );
          expect(
            () => GestorService.validarDatosHorario(10, {
              'area_deportiva_id': 15,
              'dia': 'martes',
              'hora_apertura': '20:00:00',
              'hora_cierre': '18:00:00',
              'disponible': 0,
            }),
            throwsArgumentError,
          );
          expect(
            () => GestorService.validarDatosHorario(10, {
              'area_deportiva_id': 15,
              'dia': 'martes',
              'hora_apertura': '10:00:00',
              'hora_cierre': '10:00:00',
              'disponible': 0,
            }),
            throwsArgumentError,
          );

          final validado = GestorService.validarDatosHorario(10, {
            'area_deportiva_id': 15,
            'dia': 'Miércoles',
            'hora_apertura': '08:00',
            'hora_cierre': '21:30',
            'disponible': false,
          });
          expect(validado, {
            'area_deportiva_id': 15,
            'dia': 'miercoles',
            'hora_apertura': '08:00:00',
            'hora_cierre': '21:30:00',
            'disponible': 0,
          });
        },
      );

      test(
        'El bloqueo impide nuevas reservas en el servicio y en el calendario de reservas',
        () {
          final horarios = [
            {
              'id': 1,
              'area_deportiva_id': 10,
              'dia': 'lunes',
              'hora_apertura': '08:00:00',
              'hora_cierre': '22:00:00',
              'disponible': 0, // Bloqueado
            },
            {
              'id': 2,
              'area_deportiva_id': 10,
              'dia': 'martes',
              'hora_apertura': '09:00:00',
              'hora_cierre': '18:00:00',
              'disponible': 1, // Disponible hasta las 18:00
            },
          ];

          final lunes = DateTime(2026, 11, 9); // Lunes
          final martes = DateTime(2026, 11, 10); // Martes

          // Día bloqueado rechaza nuevas reservas
          expect(
            GestorService.horarioPermiteReserva(
              horarios: horarios,
              fecha: lunes,
              horaInicio: '10:00:00',
              horaFin: '11:00:00',
              areaId: 10,
            ),
            isFalse,
          );

          // Turno fuera de las horas habilitadas es rechazado
          expect(
            GestorService.horarioPermiteReserva(
              horarios: horarios,
              fecha: martes,
              horaInicio: '18:00:00',
              horaFin: '19:00:00',
              areaId: 10,
            ),
            isFalse,
          );

          // Turno dentro de horario habilitado es permitido
          expect(
            GestorService.horarioPermiteReserva(
              horarios: horarios,
              fecha: martes,
              horaInicio: '10:00:00',
              horaFin: '11:00:00',
              areaId: 10,
            ),
            isTrue,
          );

          // Verificación en ReservaCalendarioViewModel: día bloqueado no genera slots ni permite reservar
          final vm = ReservaCalendarioViewModel(areaId: 10);
          vm.horarios = horarios.map(HorarioArea.fromJson).toList();

          expect(vm.diaDisponible(lunes), isFalse);
          vm.seleccionarDia(lunes);
          expect(vm.slots, isEmpty);
          expect(vm.tieneRangoValido, isFalse);

          expect(vm.diaDisponible(martes), isTrue);
          vm.seleccionarDia(martes);
          expect(vm.slots, isNotEmpty);
        },
      );

      test(
        'Impide bloquear o recortar un horario con reservas activas si no hay confirmacion explicita',
        () async {
          var llamadasRed = 0;
          final supabase = _buildMockSupabase((request) async {
            llamadasRed++;
            return http.Response(
              jsonEncode([]),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          });
          addTearDown(supabase.dispose);
          final service = GestorService(client: supabase);

          final reservasExistentes = [
            {
              'id': 101,
              'area_deportiva_id': 10,
              'fecha': '2026-11-16', // Lunes
              'hora_inicio': '19:00:00',
              'hora_fin': '20:00:00',
              'estado': 'confirmada',
            },
            {
              'id': 102,
              'area_deportiva_id': 10,
              'fecha': '2026-11-16', // Lunes
              'hora_inicio': '10:00:00',
              'hora_fin': '11:00:00',
              'estado': 'cancelada',
            },
          ];

          final afectadas = GestorService.detectarReservasAfectadasPorBloqueo(
            areaId: 10,
            dia: 'lunes',
            horaApertura: '08:00:00',
            horaCierre: '22:00:00',
            disponible: false,
            reservasExistentes: reservasExistentes,
          );
          expect(afectadas, hasLength(1));
          expect(afectadas.first['id'], 101);

          // Bloqueo completo sin confirmación debe fallar sin tocar la BD
          await expectLater(
            service.cambiarDisponibilidadHorario(
              42,
              {
                'id': 7,
                'area_deportiva_id': 10,
                'dia': 'lunes',
                'hora_apertura': '08:00:00',
                'hora_cierre': '22:00:00',
                'disponible': 1,
              },
              false,
              reservasExistentes: reservasExistentes,
              confirmarConReservasExistentes: false,
            ),
            throwsA(isA<StateError>()),
          );

          // Recorte de cierre a 18:00 (dejando fuera la reserva de 19:00–20:00) sin confirmación también falla
          await expectLater(
            service.guardarHorario(
              10,
              'lunes',
              '08:00:00',
              '18:00:00',
              true,
              id: 7,
              gestorId: 42,
              reservasExistentes: reservasExistentes,
              confirmarConReservasExistentes: false,
            ),
            throwsA(isA<StateError>()),
          );

          expect(llamadasRed, 0);
        },
      );

      test(
        'Al confirmar el bloqueo actualiza areas_horarios y no elimina ni modifica las reservas existentes',
        () async {
          Map<String, dynamic>? horarioActualizado;
          var tocoTablaReservas = false;

          final supabase = _buildMockSupabase((request) async {
            if (request.url.path.contains('/reservas')) {
              tocoTablaReservas = true;
            }
            if (request.url.path.endsWith('/areas_horarios') &&
                request.method == 'PATCH') {
              final decoded = jsonDecode(request.body);
              horarioActualizado = decoded is List
                  ? Map<String, dynamic>.from(decoded.first as Map)
                  : Map<String, dynamic>.from(decoded as Map);
              return http.Response(
                jsonEncode([horarioActualizado]),
                200,
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
          addTearDown(supabase.dispose);
          final service = GestorService(client: supabase);

          final reservasExistentes = [
            {
              'id': 101,
              'area_deportiva_id': 10,
              'fecha': '2026-11-16', // Lunes
              'hora_inicio': '19:00:00',
              'hora_fin': '20:00:00',
              'estado': 'confirmada',
            },
          ];

          await service.cambiarDisponibilidadHorario(
            42,
            {
              'id': 7,
              'area_deportiva_id': 10,
              'dia': 'lunes',
              'hora_apertura': '08:00:00',
              'hora_cierre': '22:00:00',
              'disponible': 1,
            },
            false,
            reservasExistentes: reservasExistentes,
            confirmarConReservasExistentes: true,
          );

          expect(horarioActualizado, isNotNull);
          expect(horarioActualizado!['area_deportiva_id'], 10);
          expect(horarioActualizado!['dia'], 'lunes');
          expect(horarioActualizado!['disponible'], 0);
          expect(tocoTablaReservas, isFalse);
          expect(reservasExistentes, hasLength(1));
          expect(reservasExistentes.first['estado'], 'confirmada');
        },
      );
    },
  );
}
