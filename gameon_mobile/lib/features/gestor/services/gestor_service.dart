import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class GestorService {
  final SupabaseClient? _client;

  GestorService({SupabaseClient? client}) : _client = client;

  SupabaseClient get db => _client ?? Supabase.instance.client;

  /// Verifica que las coordenadas geográficas correspondan a una ubicación válida.
  static bool validarUbicacion(num? latitud, num? longitud) {
    if (latitud == null || longitud == null) return false;
    final lat = latitud.toDouble();
    final lng = longitud.toDouble();
    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) {
      return false;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return false;
    }
    if (lat == 0 && lng == 0) return false;
    return true;
  }

  /// Valida rol/autorización del administrador, datos obligatorios y ubicación válida (US-20).
  static Map<String, dynamic> validarDatosInstalacion(
    int gestorId,
    Map<String, dynamic> values,
  ) {
    if (gestorId <= 0) {
      throw StateError(
        'No autorizado: solo un administrador autorizado puede registrar instalaciones.',
      );
    }

    final nombre = '${values['nombre'] ?? ''}'.trim();
    final direccion = '${values['direccion'] ?? ''}'.trim();
    final telefono = '${values['telefono'] ?? ''}'.trim();
    final email = '${values['email'] ?? ''}'.trim();
    final rucRaw = values['ruc'] == null ? '' : '${values['ruc']}'.trim();

    if (nombre.isEmpty) {
      throw ArgumentError('El nombre de la instalación es obligatorio.');
    }
    if (direccion.isEmpty) {
      throw ArgumentError('La dirección de la instalación es obligatoria.');
    }
    if (telefono.isEmpty || telefono.length < 6) {
      throw ArgumentError('El teléfono de contacto del administrador es obligatorio.');
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      throw ArgumentError('El correo de contacto del administrador no es válido.');
    }
    if (rucRaw.isNotEmpty && !RegExp(r'^\d{11}$').hasMatch(rucRaw)) {
      throw ArgumentError('El RUC debe contener 11 dígitos numéricos.');
    }

    final rawTarifa = values['tarifa'];
    final tarifa = rawTarifa is num
        ? rawTarifa.toDouble()
        : double.tryParse('$rawTarifa');
    if (tarifa == null || tarifa <= 0) {
      throw ArgumentError('La tarifa por hora debe ser un monto mayor a 0.');
    }

    final rawLat = values['latitud'];
    final rawLng = values['longitud'];
    final lat = rawLat is num ? rawLat.toDouble() : double.tryParse('$rawLat');
    final lng = rawLng is num ? rawLng.toDouble() : double.tryParse('$rawLng');
    if (!validarUbicacion(lat, lng)) {
      throw ArgumentError(
        'La ubicación seleccionada no es válida. Debe encontrarse dentro de coordenadas geográficas reales.',
      );
    }

    return {
      ...values,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'ruc': rucRaw.isEmpty ? null : rucRaw,
      'tarifa': tarifa,
      'latitud': lat,
      'longitud': lng,
      'estado': values['estado'] ?? 1,
    };
  }

  Future<String?> subirImagen() async {
    final user = db.auth.currentUser;
    if (user == null) throw StateError('Inicia sesión para subir imágenes');
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600,
    );
    if (picked == null) return null;
    final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
    await db.storage.from('gestor-imagenes').uploadBinary(
      path, await picked.readAsBytes(),
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    return db.storage.from('gestor-imagenes').getPublicUrl(path);
  }

  Future<List<Map<String, dynamic>>> centros(int gestorId) async {
    final rows = await db.from('instituciones_deportivas').select()
        .eq('usuario_instalacion_id', gestorId).order('nombre');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> deportes() async {
    final rows = await db.from('deportes').select('id,nombre').order('nombre');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> guardarCentro(int gestorId, Map<String, dynamic> values,
      {int? id}) async {
    final payload = validarDatosInstalacion(gestorId, values);
    if (id == null) {
      await db.from('instituciones_deportivas').insert({
        ...payload, 'usuario_instalacion_id': gestorId,
      });
    } else {
      await db.from('instituciones_deportivas').update(payload)
          .eq('id', id).eq('usuario_instalacion_id', gestorId);
    }
  }

  Future<List<Map<String, dynamic>>> areas(List<int> centroIds) async {
    if (centroIds.isEmpty) return [];
    final rows = await db.from('areas_deportivas')
        .select('*, deportes(nombre)')
        .inFilter('institucion_deportiva_id', centroIds).order('nombre_area');
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
    final existing = await db.from('instituciones_deportes')
        .select('deporte_id').eq('institucion_deportiva_id', centerId)
        .eq('deporte_id', sportId).maybeSingle();
    if (existing == null) {
      await db.from('instituciones_deportes').insert({
        'institucion_deportiva_id': centerId, 'deporte_id': sportId,
      });
    }
  }

  Future<List<Map<String, dynamic>>> horarios(int areaId) async {
    final rows = await db.from('areas_horarios').select()
        .eq('area_deportiva_id', areaId);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> guardarHorario(int areaId, String dia, String inicio,
      String fin, bool disponible, {int? id}) async {
    final values = {
      'area_deportiva_id': areaId, 'dia': dia,
      'hora_apertura': inicio, 'hora_cierre': fin,
      'disponible': disponible ? 1 : 0,
    };
    if (id == null) {
      await db.from('areas_horarios').insert(values);
    } else {
      await db.from('areas_horarios').update(values).eq('id', id)
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
    // La RPC autoriza cada área usando la sesión; los IDs solo son filtros.
    final result = <Map<String, dynamic>>[];
    const pageSize = 200;
    while (true) {
      final rows = await db.rpc(
        'consultar_reservas_gestor',
        params: {
          'p_area_ids': areaIds,
          'p_fecha': fecha,
          'p_offset': result.length,
          'p_limite': pageSize,
        },
      );
      final page = List<Map<String, dynamic>>.from(rows as List);
      result.addAll(page);
      if (page.length < pageSize) return result;
    }
  }
}
