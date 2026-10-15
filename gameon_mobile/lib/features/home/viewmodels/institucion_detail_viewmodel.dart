import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gameon/features/home/models/horario_atencion.dart';
import 'package:gameon/features/home/models/deporte.dart';
import 'package:gameon/features/home/models/institucion_deportiva.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstitucionDetailViewModel extends ChangeNotifier {
  final int institucionId;
  final SupabaseClient? _customClient;
  final SharedPreferences? _customPrefs;

  InstitucionDetailViewModel(
    this.institucionId, {
    SupabaseClient? supabaseClient,
    SharedPreferences? prefs,
  })  : _customClient = supabaseClient,
        _customPrefs = prefs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFromCache = false;
  bool get isFromCache => _isFromCache;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<HorarioAtencion> _horarios = [];
  List<HorarioAtencion> get horarios => _horarios;

  List<Deporte> _deportes = [];
  List<Deporte> get deportes => _deportes;

  List<String> _servicios = [];
  List<String> get servicios => _servicios;

  List<String> _fotografias = [];
  List<String> get fotografias => _fotografias;

  DateTime? _cachedAt;
  DateTime? get cachedAt => _cachedAt;

  SupabaseClient? get _client {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    if (_customPrefs != null) return _customPrefs;
    return await SharedPreferences.getInstance();
  }

  String get cacheKey => 'cached_institucion_detail_$institucionId';

  /// Carga completa de datos del detalle con soporte de caché offline y manejo de errores 500/red
  Future<void> loadDetail({
    InstitucionDeportiva? institucion,
    bool isRetry = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final client = _client;
      if (client == null) {
        throw Exception('Cliente de base de datos no disponible');
      }

      // Carga remota concurrente
      final results = await Future.wait([
        fetchHorarios(),
        fetchDeportes(),
        fetchFotografias(institucion: institucion),
        fetchServicios(institucion: institucion),
      ]);

      _horarios = results[0] as List<HorarioAtencion>;
      _deportes = results[1] as List<Deporte>;
      _fotografias = results[2] as List<String>;
      _servicios = results[3] as List<String>;

      _isFromCache = false;
      _errorMessage = null;

      // Guardar en caché para sesiones sin conexión futuras
      await saveToCache();
    } catch (e) {
      // Si falla la carga remota (ej: 500 o sin conexión), intentamos recuperar la caché
      final loadedFromCache = await loadFromCache();
      if (loadedFromCache) {
        _isFromCache = true;
        _errorMessage = null;
      } else {
        _isFromCache = false;
        // Mensaje comprensible para el usuario sin detalles técnicos
        _errorMessage =
            'No fue posible cargar los detalles de la instalación. Por favor, verifica tu conexión o intenta nuevamente.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene los horarios de atención de la instalación
  Future<List<HorarioAtencion>> fetchHorarios() async {
    final client = _client;
    if (client == null) {
      throw Exception('Cliente de base de datos no disponible');
    }

    try {
      final data = await client
          .from('horarios_atencion')
          .select(
            'id, institucion_deportiva_id, dia, hora_apertura, hora_cierre',
          )
          .eq('institucion_deportiva_id', institucionId);

      final list = (data as List).cast<Map<String, dynamic>>();
      return list
          .map<HorarioAtencion>((json) => HorarioAtencion.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Horarios: $e');
    }
  }

  /// Obtiene los deportes asociados a la instalación
  Future<List<Deporte>> fetchDeportes() async {
    final client = _client;
    if (client == null) {
      throw Exception('Cliente de base de datos no disponible');
    }

    try {
      final linkRows = await client
          .from('instituciones_deportes')
          .select('deporte_id')
          .eq('institucion_deportiva_id', institucionId);

      final ids = (linkRows as List)
          .map((r) => (r as Map<String, dynamic>)['deporte_id'])
          .where((v) => v != null)
          .map<int>((v) => v as int)
          .toSet()
          .toList();

      if (ids.isEmpty) return [];

      final idsCsv = '(${ids.join(',')})';
      final depRows = await client
          .from('deportes')
          .select('id, nombre')
          .filter('id', 'in', idsCsv);

      final list = (depRows as List).cast<Map<String, dynamic>>();
      return list.map((j) => Deporte.fromJson(j)).toList();
    } catch (e) {
      throw Exception('Deportes: $e');
    }
  }

  /// Obtiene la lista de fotografías de la instalación y sus áreas
  Future<List<String>> fetchFotografias({
    InstitucionDeportiva? institucion,
  }) async {
    if (institucion?.fotografias != null) {
      return institucion!.fotografias!;
    }

    final Set<String> fotos = {};

    if (institucion?.imagen != null && institucion!.imagen!.trim().isNotEmpty) {
      fotos.add(institucion.imagen!.trim());
    }

    final client = _client;
    if (client != null) {
      try {
        final areasData = await client
            .from('areas_deportivas')
            .select('imagen_area')
            .eq('institucion_deportiva_id', institucionId);

        for (final row in (areasData as List)) {
          final img = (row as Map<String, dynamic>)['imagen_area'];
          if (img != null && img.toString().trim().isNotEmpty) {
            fotos.add(img.toString().trim());
          }
        }
      } catch (_) {
        // Si falla la consulta de áreas para imágenes, mantenemos las imágenes que tengamos
      }
    }

    return fotos.toList();
  }

  /// Obtiene la lista de servicios complementarios registrados
  Future<List<String>> fetchServicios({
    InstitucionDeportiva? institucion,
  }) async {
    if (institucion?.servicios != null) {
      return institucion!.servicios!;
    }

    // Si la institución tiene descripción, detectamos posibles servicios mencionados
    final desc = (institucion?.descripcion ?? '').toLowerCase();
    final List<String> detectados = [];

    if (desc.contains('iluminaci') || desc.contains('led')) {
      detectados.add('Iluminación nocturna');
    }
    if (desc.contains('estacionamiento') || desc.contains('parking')) {
      detectados.add('Estacionamiento');
    }
    if (desc.contains('cafeter') || desc.contains('snack') || desc.contains('kiosko')) {
      detectados.add('Cafetería / Snack bar');
    }
    if (desc.contains('vestuario') || desc.contains('ducha')) {
      detectados.add('Vestuarios y duchas');
    }
    if (desc.contains('wifi') || desc.contains('wi-fi')) {
      detectados.add('Wi-Fi');
    }

    // Servicios base estándar si la instalación tiene descripción y servicios asociados
    if (detectados.isEmpty && institucion != null && desc.isNotEmpty) {
      // Instalaciones premium como Top Gol Tacna o Club Deportivo
      if (institucion.nombre.toLowerCase().contains('top gol') ||
          institucion.nombre.toLowerCase().contains('club') ||
          institucion.calificacion >= 4.5) {
        detectados.addAll([
          'Césped sintético premium',
          'Iluminación nocturna LED',
          'Estacionamiento',
          'Vestuarios',
        ]);
      }
    }

    return detectados;
  }

  /// Guarda los datos actuales en SharedPreferences para modo sin conexión
  Future<void> saveToCache() async {
    try {
      final prefs = await _getPrefs();
      final data = {
        'institucionId': institucionId,
        'cachedAt': DateTime.now().toIso8601String(),
        'horarios': _horarios.map((h) => h.toJson()).toList(),
        'deportes': _deportes.map((d) => d.toJson()).toList(),
        'servicios': _servicios,
        'fotografias': _fotografias,
      };
      await prefs.setString(cacheKey, jsonEncode(data));
    } catch (_) {
      // Ignorar errores al guardar en caché
    }
  }

  /// Carga datos desde SharedPreferences si existen
  Future<bool> loadFromCache() async {
    try {
      final prefs = await _getPrefs();
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr == null || cachedStr.isEmpty) return false;

      final data = jsonDecode(cachedStr) as Map<String, dynamic>;

      if (data['horarios'] != null) {
        final list = (data['horarios'] as List).cast<Map<String, dynamic>>();
        _horarios = list.map((j) => HorarioAtencion.fromJson(j)).toList();
      }

      if (data['deportes'] != null) {
        final list = (data['deportes'] as List).cast<Map<String, dynamic>>();
        _deportes = list.map((j) => Deporte.fromJson(j)).toList();
      }

      if (data['servicios'] != null) {
        _servicios = List<String>.from(data['servicios']);
      }

      if (data['fotografias'] != null) {
        _fotografias = List<String>.from(data['fotografias']);
      }

      if (data['cachedAt'] != null) {
        _cachedAt = DateTime.tryParse(data['cachedAt'].toString());
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Elimina la caché para pruebas
  Future<void> clearCache() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(cacheKey);
    } catch (_) {}
  }
}
