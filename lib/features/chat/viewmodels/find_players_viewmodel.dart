import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_user.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../services/user_sync_service.dart';

/// Modelo para representar un jugador encontrado en la búsqueda
class PlayerSearchResult {
  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;
  final String? deporte;
  final String? nivelHabilidad;
  final bool hasExistingConversation;
  final String? existingConversationId;

  PlayerSearchResult({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
    this.deporte,
    this.nivelHabilidad,
    this.hasExistingConversation = false,
    this.existingConversationId,
  });
}

/// ViewModel para buscar jugadores y crear conversaciones.
///
/// Características:
/// - Búsqueda de usuarios en Supabase
/// - Filtrado por deporte y nivel de habilidad
/// - Detección de conversaciones existentes
/// - Creación de nuevas conversaciones
/// - Sincronización automática de usuarios a Firebase
class FindPlayersViewModel extends ChangeNotifier {
  final ChatService _chatService;
  final UserSyncService _userSyncService;
  final supabase = Supabase.instance.client;

  // Estado
  List<PlayerSearchResult> _searchResults = [];
  List<dynamic> _deportes = [];
  bool _loading = false;
  bool _creatingConversation = false;
  String? _error;
  String _searchQuery = '';
  int? _selectedDeporteId;
  String? _selectedNivelHabilidad;
  String? _selectedGenero;
  int? _minAge;
  int? _maxAge;

  // Getters
  List<PlayerSearchResult> get searchResults => _searchResults;
  List<dynamic> get deportes => _deportes;
  bool get loading => _loading;
  bool get creatingConversation => _creatingConversation;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int? get selectedDeporteId => _selectedDeporteId;
  String? get selectedNivelHabilidad => _selectedNivelHabilidad;
  String? get selectedGenero => _selectedGenero;
  int? get minAge => _minAge;
  int? get maxAge => _maxAge;
  bool get hasResults => _searchResults.isNotEmpty;
  bool get hasFilters =>
      _selectedDeporteId != null ||
      _selectedNivelHabilidad != null ||
      _selectedGenero != null ||
      _minAge != null ||
      _maxAge != null;

  String get currentUserId {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    return user.id;
  }

  FindPlayersViewModel({
    ChatService? chatService,
    UserSyncService? userSyncService,
  }) : _chatService = chatService ?? ChatService(),
       _userSyncService = userSyncService ?? UserSyncService();

  bool _isDisposed = false;
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Inicializa el ViewModel cargando los deportes disponibles
  Future<void> start() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await loadDeportes();
    // Cargar todos los jugadores al inicio
    await searchPlayers();
  }

  /// Carga la lista de deportes desde Supabase
  Future<void> loadDeportes() async {
    try {
      final response = await supabase
          .from('deportes')
          .select('id, nombre')
          .order('nombre');

      _deportes = response;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Error al cargar deportes',
        error: e,
        name: 'FindPlayersViewModel',
      );
      notifyListeners();
    }
  }

  /// Realiza la búsqueda de jugadores
  Future<void> searchPlayers() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      // Construir query base
      dynamic query = supabase
          .from('usuarios_deportistas')
          .select(
            'id, auth_id, nombre, apellidos, nivel_habilidad, username, fecha_nacimiento, genero, imagen_perfil',
          )
          .neq('auth_id', currentUserId); // Excluir al usuario actual

      // Aplicar filtro de búsqueda por nombre/username
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.trim();
        final parts = q
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .toList();
        if (parts.length >= 2) {
          final p1 = parts[0];
          final p2 = parts[1];
          query = query.or(
            'and(nombre.ilike.%$p1%,apellidos.ilike.%$p2%),and(nombre.ilike.%$p2%,apellidos.ilike.%$p1%),nombre.ilike.%$q%,apellidos.ilike.%$q%,username.ilike.%$q%',
          );
        } else {
          query = query.or(
            'nombre.ilike.%$q%,apellidos.ilike.%$q%,username.ilike.%$q%',
          );
        }
      }

      // Aplicar filtro de deporte
      if (_selectedDeporteId != null) {
        final selectedDeporteId = _selectedDeporteId!;
        final usuariosDeporte = await supabase
            .from('usuarios_deportes')
            .select('usuario_id')
            .eq('deporte_id', selectedDeporteId)
            .limit(1000);

        final ids = (usuariosDeporte as List)
            .map((e) => e['usuario_id'] as int)
            .toList();

        if (ids.isEmpty) {
          _searchResults = [];
          _loading = false;
          notifyListeners();
          return;
        }

        final inValues = '(${ids.join(',')})';
        query = query.filter('id', 'in', inValues);
      }

      // Aplicar filtro de nivel de habilidad
      if (_selectedNivelHabilidad != null) {
        query = query.eq('nivel_habilidad', _selectedNivelHabilidad!);
      }

      // Aplicar filtro de género
      if (_selectedGenero != null) {
        query = query.eq('genero', _selectedGenero!);
      }

      // Limitar resultados
      query = query.limit(50);

      final response = await query;

      // Filtrar por edad si se especificó (se hace en memoria porque requiere cálculo)
      List<dynamic> filteredByAge = response as List;
      if (_minAge != null || _maxAge != null) {
        final now = DateTime.now();
        filteredByAge = filteredByAge.where((user) {
          final fechaNacStr = user['fecha_nacimiento'] as String?;
          if (fechaNacStr == null) return false;

          try {
            final fechaNac = DateTime.parse(fechaNacStr);
            final age =
                now.year -
                fechaNac.year -
                ((now.month > fechaNac.month ||
                        (now.month == fechaNac.month &&
                            now.day >= fechaNac.day))
                    ? 0
                    : 1);

            if (_minAge != null && age < _minAge!) return false;
            if (_maxAge != null && age > _maxAge!) return false;
            return true;
          } catch (e) {
            return false;
          }
        }).toList();
      }

      // Obtener conversaciones existentes del usuario
      List<Conversation> conversationsQuery = [];
      try {
        conversationsQuery = await _chatService
            .getConversations(currentUserId)
            .first
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        developer.log(
          'No se pudieron cargar conversaciones existentes (continuando sin ellas)',
          error: e,
          name: 'FindPlayersViewModel',
        );
        // Continuar sin verificar conversaciones existentes
      }

      // Procesar resultados
      _searchResults = filteredByAge.map((user) {
        final userId = user['auth_id'] as String;
        final nombre = user['nombre'] as String? ?? '';
        final apellidos = user['apellidos'] as String? ?? '';
        final nombreCompleto = '$nombre $apellidos'.trim();
        final username = user['username'] as String?;

        // Verificar si ya existe una conversación con este usuario
        // IMPORTANTE: Debe verificar que AMBOS usuarios estén en la conversación
        Conversation? existingConv;
        try {
          existingConv = conversationsQuery.firstWhere(
            (conv) =>
                conv.participantIds.contains(userId) &&
                conv.participantIds.contains(currentUserId),
          );
        } catch (e) {
          existingConv = null;
        }

        final hasConversation = existingConv != null;

        return PlayerSearchResult(
          id: userId,
          name: nombreCompleto.isEmpty ? 'Usuario' : nombreCompleto,
          username: username,
          avatarUrl: user['imagen_perfil'] as String?,
          deporte: null,
          nivelHabilidad: user['nivel_habilidad'] as String?,
          hasExistingConversation: hasConversation,
          existingConversationId: hasConversation ? existingConv.id : null,
        );
      }).toList();

      _loading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Error al buscar jugadores',
        error: e,
        name: 'FindPlayersViewModel',
      );
      _error = 'Error al buscar jugadores: ${e.toString()}';
      _loading = false;
      notifyListeners();
    }
  }

  /// Actualiza el query de búsqueda y realiza la búsqueda
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();

    // Búsqueda automática
    searchPlayers();
  }

  /// Actualiza el filtro de deporte
  void setDeporteFilter(int? deporteId) {
    _selectedDeporteId = deporteId;
    notifyListeners();

    // Buscar automáticamente al cambiar filtro
    searchPlayers();
  }

  /// Actualiza el filtro de nivel de habilidad
  void setNivelHabilidadFilter(String? nivel) {
    _selectedNivelHabilidad = nivel;
    notifyListeners();

    // Buscar automáticamente al cambiar filtro
    searchPlayers();
  }

  /// Actualiza el filtro de género
  void setGeneroFilter(String? genero) {
    _selectedGenero = genero;
    notifyListeners();

    // Buscar automáticamente al cambiar filtro
    searchPlayers();
  }

  /// Actualiza el filtro de edad mínima
  void setMinAgeFilter(int? age) {
    _minAge = age;
    notifyListeners();

    // Buscar automáticamente al cambiar filtro
    searchPlayers();
  }

  /// Actualiza el filtro de edad máxima
  void setMaxAgeFilter(int? age) {
    _maxAge = age;
    notifyListeners();

    // Buscar automáticamente al cambiar filtro
    searchPlayers();
  }

  /// Limpia todos los filtros
  /// Limpia todos los filtros
  void clearFilters() {
    _searchQuery = '';
    _selectedDeporteId = null;
    _selectedNivelHabilidad = null;
    _selectedGenero = null;
    _minAge = null;
    _maxAge = null;
    notifyListeners();

    // Recargar la lista completa
    searchPlayers();
  }

  /// Crea una nueva conversación con un jugador
  /// Retorna el ID de la conversación (nueva o existente)
  Future<String> createConversation(PlayerSearchResult player) async {
    try {
      if (!_isDisposed) {
        _creatingConversation = true;
        _error = null;
        notifyListeners();
      }

      // Si ya existe una conversación, retornar su ID
      if (player.hasExistingConversation &&
          player.existingConversationId != null) {
        if (!_isDisposed) {
          _creatingConversation = false;
          notifyListeners();
        }
        return player.existingConversationId!;
      }

      String resolvedName = 'Usuario';
      String? resolvedPhoto;
      try {
        final profile = await supabase
            .from('usuarios_deportistas')
            .select('nombre, apellidos, imagen_perfil')
            .eq('auth_id', currentUserId)
            .maybeSingle();
        final nombre = profile?['nombre'] as String? ?? '';
        final apellidos = profile?['apellidos'] as String? ?? '';
        final fullName = ('$nombre $apellidos').trim();
        resolvedPhoto = profile?['imagen_perfil'] as String?;
        if (fullName.isNotEmpty) {
          resolvedName = fullName;
        } else {
          final meta = supabase.auth.currentUser?.userMetadata ?? {};
          final mNombre = meta['nombre'] as String? ?? '';
          final mApellidos = meta['apellidos'] as String? ?? '';
          final metaFull = ('$mNombre $mApellidos').trim();
          if (metaFull.isNotEmpty) {
            resolvedName = metaFull;
          } else {
            final chatUser = await _chatService.getChatUser(currentUserId);
            if (chatUser != null && chatUser.nombre.isNotEmpty) {
              resolvedName = chatUser.nombre;
            }
          }
        }
      } catch (_) {}

      final currentUser = ChatUser(
        id: currentUserId,
        nombre: resolvedName,
        fotoPerfil: resolvedPhoto,
      );

      // Crear ChatUser del otro usuario
      final otherUser = ChatUser(
        id: player.id,
        nombre: player.name,
        fotoPerfil: player.avatarUrl,
      );

      // Usar el método del servicio para crear o recuperar la conversación
      final conversationId = await _chatService.getOrCreateConversation(
        currentUserId: currentUserId,
        otherUserId: player.id,
        currentUser: currentUser,
        otherUser: otherUser,
      );

      if (!_isDisposed) {
        _creatingConversation = false;
        notifyListeners();
      }

      return conversationId;
    } catch (e) {
      developer.log(
        'Error al crear conversación',
        error: e,
        name: 'FindPlayersViewModel',
      );
      if (!_isDisposed) {
        _error = 'Error al crear conversación: ${e.toString()}';
        _creatingConversation = false;
        notifyListeners();
      }
      rethrow;
    }
  }

  /// Obtiene el ID determinístico de conversación para navegación inmediata
  String getConversationIdForPlayer(PlayerSearchResult player) {
    final ids = [currentUserId, player.id]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
