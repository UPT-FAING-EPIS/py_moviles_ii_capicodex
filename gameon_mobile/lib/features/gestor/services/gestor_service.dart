import 'package:gameon/core/validation/coordenadas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class GestorService {
  final SupabaseClient? _client;

  GestorService({SupabaseClient? client}) : _client = client;

  SupabaseClient get db => _client ?? Supabase.instance.client;

  /// Verifica que las coordenadas geográficas correspondan a una ubicación válida.
  static bool validarUbicacion(num? latitud, num? longitud) {
    return validarCoordenadas(latitud, longitud);
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

  static const List<String> diasSemana = [
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo',
  ];

  /// Normaliza el nombre del día de la semana en minúsculas y sin tildes.
  static String normalizarDiaSemana(String dia) {
    return dia
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  /// Convierte una hora `HH:mm` o `HH:mm:ss` a minutos desde las 00:00, o `null` si es inválida.
  static int? parsearMinutosHora(String? valor) {
    if (valor == null) return null;
    final partes = valor.trim().split(':');
    if (partes.length < 2 || partes.length > 3) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    final s = partes.length == 3 ? int.tryParse(partes[2]) : 0;
    if (h == null || m == null || s == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59 || s < 0 || s > 59) return null;
    return h * 60 + m;
  }

  static String _formatearHoraSql(String valor) {
    final partes = valor.trim().split(':');
    final h = int.parse(partes[0]).toString().padLeft(2, '0');
    final m = int.parse(partes[1]).toString().padLeft(2, '0');
    final s = partes.length == 3
        ? int.parse(partes[2]).toString().padLeft(2, '0')
        : '00';
    return '$h:$m:$s';
  }

  /// Valida autorización del administrador e integridad del horario o bloqueo (US-23).
  static Map<String, dynamic> validarDatosHorario(
    int gestorId,
    Map<String, dynamic> values,
  ) {
    if (gestorId <= 0) {
      throw StateError(
        'No autorizado: solo un administrador autorizado puede gestionar o bloquear horarios.',
      );
    }

    final rawAreaId = values['area_deportiva_id'];
    final areaId = rawAreaId is num
        ? rawAreaId.toInt()
        : int.tryParse('${rawAreaId ?? ''}');
    if (areaId == null || areaId <= 0) {
      throw ArgumentError('El área deportiva es obligatoria y debe ser válida.');
    }

    final dia = normalizarDiaSemana('${values['dia'] ?? ''}');
    if (!diasSemana.contains(dia)) {
      throw ArgumentError('El día de la semana no es válido.');
    }

    final aperturaRaw = '${values['hora_apertura'] ?? ''}'.trim();
    final cierreRaw = '${values['hora_cierre'] ?? ''}'.trim();
    final aperturaMin = parsearMinutosHora(aperturaRaw);
    final cierreMin = parsearMinutosHora(cierreRaw);
    if (aperturaMin == null || cierreMin == null) {
      throw ArgumentError(
        'Las horas de apertura y cierre deben tener un formato válido (HH:mm).',
      );
    }
    if (aperturaMin >= cierreMin) {
      throw ArgumentError(
        'La hora de cierre debe ser posterior a la hora de apertura.',
      );
    }

    final rawDisp = values['disponible'];
    final disponible = rawDisp is bool
        ? (rawDisp ? 1 : 0)
        : (rawDisp == 0 || '${rawDisp ?? ''}'.trim().toLowerCase() == 'false')
        ? 0
        : 1;

    return {
      'area_deportiva_id': areaId,
      'dia': dia,
      'hora_apertura': _formatearHoraSql(aperturaRaw),
      'hora_cierre': _formatearHoraSql(cierreRaw),
      'disponible': disponible,
    };
  }

  /// Identifica reservas activas que quedarían afectadas al bloquear o recortar un horario (US-23).
  /// Nunca modifica ni elimina las reservas existentes.
  static List<Map<String, dynamic>> detectarReservasAfectadasPorBloqueo({
    required int areaId,
    required String dia,
    required String horaApertura,
    required String horaCierre,
    required bool disponible,
    required List<Map<String, dynamic>> reservasExistentes,
  }) {
    final diaNorm = normalizarDiaSemana(dia);
    final aperturaMin = parsearMinutosHora(horaApertura) ?? 0;
    final cierreMin = parsearMinutosHora(horaCierre) ?? (24 * 60);

    return reservasExistentes.where((r) {
      final rAreaRaw = r['area_deportiva_id'];
      final rArea = rAreaRaw is num
          ? rAreaRaw.toInt()
          : int.tryParse('${rAreaRaw ?? ''}');
      if (rArea != areaId) return false;

      final estado = '${r['estado'] ?? ''}'.trim().toLowerCase();
      if (estado == 'cancelada' || estado == 'completada') return false;

      String? diaReserva;
      if (r['dia'] != null && '${r['dia']}'.trim().isNotEmpty) {
        diaReserva = normalizarDiaSemana('${r['dia']}');
      } else if (r['fecha'] != null) {
        final fecha = DateTime.tryParse('${r['fecha']}'.trim());
        if (fecha != null) {
          diaReserva = diasSemana[fecha.weekday - 1];
        }
      }
      if (diaReserva != diaNorm) return false;

      if (!disponible) return true;

      final resInicio = parsearMinutosHora('${r['hora_inicio'] ?? ''}');
      final resFin = parsearMinutosHora('${r['hora_fin'] ?? ''}');
      if (resInicio == null || resFin == null) return false;

      return resInicio < aperturaMin || resFin > cierreMin;
    }).toList();
  }

  /// Verifica si los horarios vigentes permiten una nueva reserva en la fecha y rango indicados (US-23).
  static bool horarioPermiteReserva({
    required List<Map<String, dynamic>> horarios,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    int? areaId,
  }) {
    final inicioMin = parsearMinutosHora(horaInicio);
    final finMin = parsearMinutosHora(horaFin);
    if (inicioMin == null || finMin == null || inicioMin >= finMin) {
      return false;
    }
    final diaFecha = diasSemana[fecha.weekday - 1];
    return horarios.any((h) {
      if (areaId != null) {
        final hAreaRaw = h['area_deportiva_id'];
        final hArea = hAreaRaw is num
            ? hAreaRaw.toInt()
            : int.tryParse('${hAreaRaw ?? ''}');
        if (hArea != areaId) return false;
      }
      final disp = h['disponible'];
      final estaDisponible = disp == 1 || disp == true || '$disp' == '1';
      if (!estaDisponible) return false;

      final hDia = normalizarDiaSemana('${h['dia'] ?? ''}');
      if (hDia != diaFecha) return false;

      final hApertura = parsearMinutosHora('${h['hora_apertura'] ?? ''}');
      final hCierre = parsearMinutosHora('${h['hora_cierre'] ?? ''}');
      if (hApertura == null || hCierre == null) return false;

      return inicioMin >= hApertura && finMin <= hCierre;
    });
  }

  Future<List<Map<String, dynamic>>> horarios(int areaId) async {
    final rows = await db.from('areas_horarios').select()
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
    int gestorId = 1,
    List<Map<String, dynamic>> reservasExistentes = const [],
    bool confirmarConReservasExistentes = false,
  }) async {
    final values = validarDatosHorario(gestorId, {
      'area_deportiva_id': areaId,
      'dia': dia,
      'hora_apertura': inicio,
      'hora_cierre': fin,
      'disponible': disponible ? 1 : 0,
    });
    final afectadas = detectarReservasAfectadasPorBloqueo(
      areaId: areaId,
      dia: '${values['dia']}',
      horaApertura: '${values['hora_apertura']}',
      horaCierre: '${values['hora_cierre']}',
      disponible: disponible,
      reservasExistentes: reservasExistentes,
    );
    if (afectadas.isNotEmpty && !confirmarConReservasExistentes) {
      throw StateError(
        'Existen ${afectadas.length} reserva(s) activa(s) en este horario. Se requiere confirmación del administrador; el bloqueo no eliminará las reservas existentes.',
      );
    }
    if (id == null) {
      await db.from('areas_horarios').insert(values);
    } else {
      await db.from('areas_horarios').update(values).eq('id', id)
          .eq('area_deportiva_id', areaId);
    }
  }

  Future<void> cambiarDisponibilidadHorario(
    int gestorId,
    Map<String, dynamic> horario,
    bool disponible, {
    List<Map<String, dynamic>> reservasExistentes = const [],
    bool confirmarConReservasExistentes = false,
  }) async {
    final rawAreaId = horario['area_deportiva_id'];
    final areaId = rawAreaId is num
        ? rawAreaId.toInt()
        : int.tryParse('${rawAreaId ?? ''}') ?? 0;
    final rawId = horario['id'];
    final id = rawId is num ? rawId.toInt() : int.tryParse('${rawId ?? ''}');
    await guardarHorario(
      areaId,
      '${horario['dia'] ?? ''}',
      '${horario['hora_apertura'] ?? ''}',
      '${horario['hora_cierre'] ?? ''}',
      disponible,
      id: id,
      gestorId: gestorId,
      reservasExistentes: reservasExistentes,
      confirmarConReservasExistentes: confirmarConReservasExistentes,
    );
  }

  Future<void> borrarHorario(
    int id, {
    int gestorId = 1,
    int? areaId,
    String? dia,
    List<Map<String, dynamic>> reservasExistentes = const [],
    bool confirmarConReservasExistentes = false,
  }) async {
    if (gestorId <= 0) {
      throw StateError(
        'No autorizado: solo un administrador autorizado puede eliminar o bloquear horarios.',
      );
    }
    if (areaId != null && dia != null) {
      final afectadas = detectarReservasAfectadasPorBloqueo(
        areaId: areaId,
        dia: dia,
        horaApertura: '00:00:00',
        horaCierre: '23:59:00',
        disponible: false,
        reservasExistentes: reservasExistentes,
      );
      if (afectadas.isNotEmpty && !confirmarConReservasExistentes) {
        throw StateError(
          'Existen ${afectadas.length} reserva(s) activa(s) en este horario. Se requiere confirmación del administrador; las reservas existentes no serán eliminadas.',
        );
      }
    }
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
