import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class YapeService {
  final SupabaseClient client;
  YapeService(this.client);

  Future<Map<String, dynamic>?> cobroDelCentro(int centroId) async {
    final center = await client.from('instituciones_deportivas')
        .select('usuario_instalacion_id').eq('id', centroId).single();
    return await client.from('gestor_cobros').select()
        .eq('gestor_id', center['usuario_instalacion_id']).maybeSingle();
  }

  Future<int?> subirEvidenciaYReservar({
    required int areaId,
    required DateTime fecha,
    required String inicio,
    required String fin,
  }) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Inicia sesión para reservar');
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600,
    );
    if (picked == null) return null;
    final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.jpg';
    await client.storage.from('yape-evidencias').uploadBinary(
      path, await picked.readAsBytes(),
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    try {
      final id = await client.rpc('crear_reserva_yape', params: {
        'p_area_id': areaId,
        'p_fecha': fecha.toIso8601String().split('T').first,
        'p_inicio': inicio,
        'p_fin': fin,
        'p_ruta': path,
      });
      return (id as num).toInt();
    } catch (_) {
      try { await client.storage.from('yape-evidencias').remove([path]); } catch (_) {}
      rethrow;
    }
  }
}
