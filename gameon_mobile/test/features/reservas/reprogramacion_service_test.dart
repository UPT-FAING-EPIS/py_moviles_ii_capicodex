import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/features/reservas/services/reprogramacion_service.dart';

void main() {
  test(
    'usa una sola RPC, conserva el id y propaga la reserva actualizada',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          expect(request.url.path, '/rest/v1/rpc/reprogramar_reserva');
          expect(jsonDecode(request.body), {
            'p_reserva_id': 16,
            'p_fecha': '2027-01-02',
            'p_hora_inicio': '18:00:00',
          });
          return http.Response(
            jsonEncode({
              'id': 16,
              'id_usuario': 1,
              'area_deportiva_id': 2,
              'fecha': '2027-01-02',
              'hora_inicio': '18:00:00',
              'hora_fin': '19:00:00',
              'estado': 'Confirmada',
              'creado_en': '2026-10-01T12:00:00',
              'monto_pagado': 60,
              'metodo_pago': 'paypal',
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      final reserva = await ReprogramacionService(client).reprogramar(
        reservaId: 16,
        fecha: DateTime(2027, 1, 2),
        horaInicio: '18:00:00',
      );
      expect(reserva.id, 16);
      expect(reserva.montoPagado, 60);
      expect(reserva.horaInicio, '18:00:00');
      expect(requests, hasLength(1));
      await client.dispose();
    },
  );

  test('un conflicto de horario no se convierte en un éxito', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (request) async => http.Response(
          '{"code":"23P01","message":"conflict","details":null,"hint":null}',
          409,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
    await expectLater(
      ReprogramacionService(client).reprogramar(
        reservaId: 16,
        fecha: DateTime(2027, 1, 2),
        horaInicio: '18:00:00',
      ),
      throwsA(isA<PostgrestException>().having((e) => e.code, 'code', '23P01')),
    );
    await client.dispose();
  });
}
