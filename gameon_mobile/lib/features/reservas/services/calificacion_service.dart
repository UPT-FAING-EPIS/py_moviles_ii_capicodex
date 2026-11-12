import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/calificacion_instalacion.dart';

class CalificacionService {
  final SupabaseClient _client;

  CalificacionService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<CalificacionInstalacion?> obtenerMiCalificacion(int reservaId) async {
    final data = await _client.rpc(
      'mi_calificacion_reserva',
      params: {'p_reserva_id': reservaId},
    );
    if (data is! List || data.isEmpty) return null;
    return CalificacionInstalacion.fromJson(data.first as Map<String, dynamic>);
  }

  Future<CalificacionInstalacion> guardar({
    required int reservaId,
    required int puntuacion,
    String? comentario,
  }) async {
    final data = await _client.rpc(
      'guardar_calificacion_instalacion',
      params: {
        'p_reserva_id': reservaId,
        'p_puntuacion': puntuacion,
        'p_comentario': comentario,
      },
    );
    if (data is! List || data.isEmpty) {
      throw StateError('No se pudo guardar la calificación');
    }
    return CalificacionInstalacion.fromJson(data.first as Map<String, dynamic>);
  }
}
