import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reserva.dart';

class AreaLite {
  final int id;
  final String nombre;
  final int institucionId;
  final double tarifaPorHora;
  final String? imagenArea;
  AreaLite({
    required this.id,
    required this.nombre,
    required this.institucionId,
    required this.tarifaPorHora,
    this.imagenArea,
  });
}

class InstitucionLite {
  final int id;
  final String nombre;
  final String direccion;
  InstitucionLite({
    required this.id,
    required this.nombre,
    required this.direccion,
  });
}

class ReservasListViewModel extends ChangeNotifier {
  final _client = Supabase.instance.client;
  bool cargando = false;
  String? error;
  List<Reserva> reservas = [];
  final Map<int, AreaLite> _areasCache = {};
  final Map<int, InstitucionLite> _instCache = {};

  // Instancia estática para actualización automática
  static ReservasListViewModel? _instance;

  static void setInstance(ReservasListViewModel vm) {
    _instance = vm;
  }

  static void clearInstance() {
    _instance = null;
  }

  static Future<void> refreshIfActive(int userId) async {
    if (_instance != null) {
      developer.log('[ReservasListVM] Auto-refresh triggered for user $userId');
      await _instance!.cargarReservasUsuario(idUsuario: userId);
    }
  }

  Future<void> cargarReservasUsuario({required int idUsuario}) async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      developer.log('[ReservasListVM] Cargando reservas idUsuario=$idUsuario');
      final data = await _client
          .from('reservas')
          .select()
          .eq('id_usuario', idUsuario)
          .order('fecha', ascending: false)
          .order('hora_inicio', ascending: false);
      reservas = (data as List)
          .map((j) => Reserva.fromJson(j as Map<String, dynamic>))
          .toList();
      developer.log('[ReservasListVM] cargadas=${reservas.length}');
      // Pre-cargar info básica de áreas de forma batch para mejorar UI
      await _preloadAreas();
    } on PostgrestException catch (e, st) {
      error = e.message;
      developer.log(
        '[ReservasListVM][ERROR] ${e.message}',
        error: e,
        stackTrace: st,
      );
    } catch (e, st) {
      error = 'Error inesperado';
      developer.log('[ReservasListVM][ERROR] $e', error: e, stackTrace: st);
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> _preloadAreas() async {
    try {
      final ids = reservas
          .map((r) => r.areaDeportivaId)
          .toSet()
          .where((id) => !_areasCache.containsKey(id))
          .toList();
      if (ids.isEmpty) return;
      final data = await _client
          .from('areas_deportivas')
          .select(
            'id,nombre_area,institucion_deportiva_id,tarifa_por_hora,imagen_area',
          )
          .inFilter('id', ids);
      for (final row in (data as List)) {
        final a = AreaLite(
          id: row['id'] as int,
          nombre: row['nombre_area'] as String,
          institucionId: row['institucion_deportiva_id'] as int,
          tarifaPorHora: (row['tarifa_por_hora'] as num).toDouble(),
          imagenArea: row['imagen_area'] as String?,
        );
        _areasCache[a.id] = a;
      }
    } catch (e, st) {
      developer.log(
        '[ReservasListVM][WARN] preloadAreas $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<AreaLite?> getArea(int id) async {
    if (_areasCache.containsKey(id)) return _areasCache[id];
    try {
      final row = await _client
          .from('areas_deportivas')
          .select(
            'id,nombre_area,institucion_deportiva_id,tarifa_por_hora,imagen_area',
          )
          .eq('id', id)
          .maybeSingle();
      if (row != null) {
        final a = AreaLite(
          id: row['id'] as int,
          nombre: row['nombre_area'] as String,
          institucionId: row['institucion_deportiva_id'] as int,
          tarifaPorHora: (row['tarifa_por_hora'] as num).toDouble(),
          imagenArea: row['imagen_area'] as String?,
        );
        _areasCache[a.id] = a;
        return a;
      }
    } catch (e, st) {
      developer.log(
        '[ReservasListVM][WARN] getArea $e',
        error: e,
        stackTrace: st,
      );
    }
    return null;
  }

  Future<InstitucionLite?> getInstitucion(int id) async {
    if (_instCache.containsKey(id)) return _instCache[id];
    try {
      final row = await _client
          .from('instituciones_deportivas')
          .select('id,nombre,direccion')
          .eq('id', id)
          .maybeSingle();
      if (row != null) {
        final i = InstitucionLite(
          id: row['id'] as int,
          nombre: row['nombre'] as String,
          direccion: row['direccion'] as String,
        );
        _instCache[i.id] = i;
        return i;
      }
    } catch (e, st) {
      developer.log(
        '[ReservasListVM][WARN] getInstitucion $e',
        error: e,
        stackTrace: st,
      );
    }
    return null;
  }

  Future<Reserva?> getReservaById(int id) async {
    try {
      final row = await _client
          .from('reservas')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row != null) {
        return Reserva.fromJson(row as Map<String, dynamic>);
      }
    } on PostgrestException catch (e, st) {
      developer.log(
        '[ReservasListVM][ERROR] getReservaById ${e.message}',
        error: e,
        stackTrace: st,
      );
    } catch (e, st) {
      developer.log(
        '[ReservasListVM][ERROR] getReservaById $e',
        error: e,
        stackTrace: st,
      );
    }
    return null;
  }

  /// Obtiene una reserva con todos sus detalles (área e institución) en una sola query
  /// usando JOIN. Esto reduce el tiempo de carga de 3 llamadas a 1.
  /// Retorna un record con (reserva, area, institucion) o null si no se encuentra.
  Future<({Reserva reserva, AreaLite area, InstitucionLite institucion})?>
  getReservaWithDetails(int id) async {
    try {
      final row = await _client
          .from('reservas')
          .select('''
            *,
            areas_deportivas!inner(
              id,
              nombre_area,
              institucion_deportiva_id,
              tarifa_por_hora,
              imagen_area,
              instituciones_deportivas!inner(
                id,
                nombre,
                direccion
              )
            )
          ''')
          .eq('id', id)
          .maybeSingle();

      if (row != null) {
        // Parsear la reserva
        final reserva = Reserva.fromJson(row);

        // Parsear el área deportiva
        final areaData = row['areas_deportivas'] as Map<String, dynamic>;
        final area = AreaLite(
          id: areaData['id'] as int,
          nombre: areaData['nombre_area'] as String,
          institucionId: areaData['institucion_deportiva_id'] as int,
          tarifaPorHora: (areaData['tarifa_por_hora'] as num).toDouble(),
          imagenArea: areaData['imagen_area'] as String?,
        );

        // Cachear el área
        _areasCache[area.id] = area;

        // Parsear la institución
        final instData =
            areaData['instituciones_deportivas'] as Map<String, dynamic>;
        final institucion = InstitucionLite(
          id: instData['id'] as int,
          nombre: instData['nombre'] as String,
          direccion: instData['direccion'] as String,
        );

        // Cachear la institución
        _instCache[institucion.id] = institucion;

        // Retornar un record con los 3 valores
        return (reserva: reserva, area: area, institucion: institucion);
      }
    } on PostgrestException catch (e, st) {
      developer.log(
        '[ReservasListVM][ERROR] getReservaWithDetails ${e.message}',
        error: e,
        stackTrace: st,
      );
    } catch (e, st) {
      developer.log(
        '[ReservasListVM][ERROR] getReservaWithDetails $e',
        error: e,
        stackTrace: st,
      );
    }
    return null;
  }
}
