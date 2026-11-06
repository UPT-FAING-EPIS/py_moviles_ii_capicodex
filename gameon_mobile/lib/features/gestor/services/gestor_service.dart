import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class GestorService {
  final SupabaseClient db = Supabase.instance.client;

  Future<String?> subirImagen() async {
    final user = db.auth.currentUser;
    if (user == null) throw StateError('Inicia sesión para subir imágenes');
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return null;
    final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
    await db.storage
        .from('gestor-imagenes')
        .uploadBinary(
          path,
          await picked.readAsBytes(),
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return db.storage.from('gestor-imagenes').getPublicUrl(path);
  }

  Future<List<Map<String, dynamic>>> centros(int gestorId) async {
    final rows = await db
        .from('instituciones_deportivas')
        .select()
        .eq('usuario_instalacion_id', gestorId)
        .order('nombre');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> deportes() async {
    final rows = await db.from('deportes').select('id,nombre').order('nombre');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> guardarCentro(
    int gestorId,
    Map<String, dynamic> values, {
    int? id,
  }) async {
    if (id == null) {
      await db.from('instituciones_deportivas').insert({
        ...values,
        'usuario_instalacion_id': gestorId,
      });
    } else {
      await db
          .from('instituciones_deportivas')
          .update(values)
          .eq('id', id)
          .eq('usuario_instalacion_id', gestorId);
    }
  }

  Future<List<Map<String, dynamic>>> areas(List<int> centroIds) async {
    if (centroIds.isEmpty) return [];
    final rows = await db
        .from('areas_deportivas')
        .select('*, deportes(nombre)')
        .inFilter('institucion_deportiva_id', centroIds)
        .order('nombre_area');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> guardarArea(Map<String, dynamic> values, {int? id}) async {
    if (id == null) {
      await db.from('areas_deportivas').insert(values);
    } else {
      await db.from('areas_deportivas').update(values).eq('id', id);
    }
    // La ficha pública del centro obtiene sus deportes de esta relación.
    final centerId = values['institucion_deportiva_id'];
    final sportId = values['deporte_id'];
    final existing = await db
        .from('instituciones_deportes')
        .select('deporte_id')
        .eq('institucion_deportiva_id', centerId)
        .eq('deporte_id', sportId)
        .maybeSingle();
    if (existing == null) {
      await db.from('instituciones_deportes').insert({
        'institucion_deportiva_id': centerId,
        'deporte_id': sportId,
      });
    }
  }

  Future<List<Map<String, dynamic>>> horarios(int areaId) async {
    final rows = await db
        .from('areas_horarios')
        .select()
        .eq('area_deportiva_id', areaId);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> guardarHorario(
    int areaId,
    String dia,
    String inicio,
    String fin,
    bool disponible, {
    int? id,
  }) async {
    final values = {
      'area_deportiva_id': areaId,
      'dia': dia,
      'hora_apertura': inicio,
      'hora_cierre': fin,
      'disponible': disponible ? 1 : 0,
    };
    if (id == null) {
      await db.from('areas_horarios').insert(values);
    } else {
      await db
          .from('areas_horarios')
          .update(values)
          .eq('id', id)
          .eq('area_deportiva_id', areaId);
    }
  }

  Future<void> borrarHorario(int id) async {
    await db.from('areas_horarios').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> reservas(
    List<int> areaIds, {
    String? fecha,
  }) async {
    if (areaIds.isEmpty) return [];
    var query = db
        .from('reservas')
        .select(
          'id,area_deportiva_id,fecha,hora_inicio,hora_fin,estado,monto_pagado,metodo_pago,yape_evidencia_ruta,yape_monto_esperado',
        )
        .inFilter('area_deportiva_id', areaIds);
    if (fecha != null) query = query.eq('fecha', fecha);
    final rows = await query.order('fecha', ascending: false).limit(200);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> reservasYapePendientes(
    List<int> areaIds,
  ) async {
    if (areaIds.isEmpty) return [];
    final rows = await db
        .from('reservas')
        .select(
          'id,area_deportiva_id,fecha,hora_inicio,hora_fin,estado,monto_pagado,metodo_pago,yape_evidencia_ruta,yape_monto_esperado',
        )
        .inFilter('area_deportiva_id', areaIds)
        .ilike('estado', 'pendiente')
        .ilike('metodo_pago', 'yape')
        .order('fecha', ascending: true)
        .limit(200);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> cobroYape(int gestorId) async =>
      db.from('gestor_cobros').select().eq('gestor_id', gestorId).maybeSingle();

  Future<void> guardarCobroYape(
    int gestorId,
    String url,
    String titular,
    String celular,
  ) async {
    await db.from('gestor_cobros').upsert({
      'gestor_id': gestorId,
      'yape_qr_url': url,
      'yape_titular': titular,
      'yape_celular': celular,
      'actualizado_en': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'gestor_id');
  }

  Future<String> evidenciaYape(String path) =>
      db.storage.from('yape-evidencias').createSignedUrl(path, 300);

  Future<void> resolverYape(int reservaId, bool aprobar) async {
    await db.rpc(
      'resolver_reserva_yape',
      params: {'p_id': reservaId, 'p_aprobar': aprobar},
    );
  }
}
