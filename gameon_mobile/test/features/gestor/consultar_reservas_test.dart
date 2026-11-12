import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/features/gestor/services/gestor_service.dart';

void main() {
  test('consulta la RPC autorizada y recupera más de 200 reservas', () async {
    var calls = 0;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/rest/v1/rpc/consultar_reservas_gestor');
        final params = jsonDecode(request.body) as Map<String, dynamic>;
        expect(params, {
          'p_area_ids': [10, 20],
          'p_fecha': '2026-11-12',
          'p_offset': calls * 200,
          'p_limite': 200,
        });
        final offset = calls++ * 200;
        return http.Response(
          jsonEncode(
            List.generate(
              offset == 0 ? 200 : 1,
              (i) => {'id': offset + i, 'area_deportiva_id': 10},
            ),
          ),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final rows = await GestorService(
      client: client,
    ).reservas([10, 20], fecha: '2026-11-12');
    expect(rows, hasLength(201));
    expect(rows.last['id'], 200);
    expect(calls, 2);
  });

  test('sin áreas no realiza solicitudes', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((_) async => throw StateError('No consultar')),
    );
    addTearDown(client.dispose);
    expect(await GestorService(client: client).reservas([]), isEmpty);
  });

  test('propaga denegación sin recurrir a la tabla de reservas', () async {
    var calls = 0;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        calls++;
        expect(request.url.path, '/rest/v1/rpc/consultar_reservas_gestor');
        return http.Response(
          '{"code":"42501","message":"No autorizado"}',
          403,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    await expectLater(
      GestorService(client: client).reservas([99]),
      throwsA(isA<PostgrestException>().having((e) => e.code, 'code', '42501')),
    );
    expect(calls, 1);
  });
}
