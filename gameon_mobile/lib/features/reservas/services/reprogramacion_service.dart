import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reserva.dart';

/// La validación definitiva y el UPDATE del mismo registro ocurren en la BD.
class ReprogramacionService {
  final SupabaseClient client;
  ReprogramacionService(this.client);

  Future<Reserva> reprogramar({
    required int reservaId,
    required DateTime fecha,
    required String horaInicio,
  }) async {
    final result = await client.rpc(
      'reprogramar_reserva',
      params: {
        'p_reserva_id': reservaId,
        'p_fecha': fecha.toIso8601String().split('T').first,
        'p_hora_inicio': horaInicio,
      },
    );
    return Reserva.fromJson(Map<String, dynamic>.from(result as Map));
  }
}
