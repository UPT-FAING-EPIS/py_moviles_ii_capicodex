import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../models/chat_user.dart';
import '../services/chat_service.dart';
import '../services/user_sync_service.dart';

/// ViewModel para gestionar la lista de conversaciones del usuario.
///
/// Características:
/// - Stream en tiempo real de conversaciones desde Firestore
/// - Sincronización automática de usuarios de Supabase a Firebase
/// - Búsqueda y filtrado de conversaciones
/// - Gestión de estados de carga y errores
class ChatListViewModel extends ChangeNotifier {
  final ChatService _chatService;
  final UserSyncService _userSyncService;
  final supabase = Supabase.instance.client;

  // Estado
  List<Conversation> _conversations = [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';

  // Mapa para rastrear el estado en línea de los usuarios
  final Map<String, bool> _userOnlineStatus = {};
  final Map<String, StreamSubscription<Map<String, dynamic>?>>
  _presenceSubscriptions = {};

  // Stream subscription
  StreamSubscription<List<Conversation>>? _conversationsSubscription;
  StreamSubscription<dynamic>? _authSubscription;

  // Getters
  List<Conversation> get conversations {
    if (_searchQuery.isEmpty) {
      return _conversations;
    }

    // Filtrar conversaciones por nombre del otro usuario
    return _conversations.where((conv) {
      final otherUser = conv.getOtherUser(currentUserId);
      final otherUserName = otherUser?.nombre.toLowerCase() ?? '';
      return otherUserName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  bool get loading => _loading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get hasConversations => _conversations.isNotEmpty;
  int get unreadCount {
    int total = 0;
    for (var conv in _conversations) {
      total += conv.getUnreadCountForUser(currentUserId);
    }
    return total;
  }

  String get currentUserId {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    return user.id;
  }

  /// Obtiene el estado en línea de un usuario
  bool isUserOnline(String userId) {
    return _userOnlineStatus[userId] ?? false;
  }

  ChatListViewModel({
    ChatService? chatService,
    UserSyncService? userSyncService,
  }) : _chatService = chatService ?? ChatService(),
       _userSyncService = userSyncService ?? UserSyncService() {
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session?.user == null) {
        _conversationsSubscription?.cancel();
        _conversationsSubscription = null;
        _cancelAllPresenceSubscriptions();
        _conversations = [];
        _searchQuery = '';
        _loading = false;
        _error = null;
        notifyListeners();
      } else {
        if (_conversationsSubscription == null) {
          start();
        }
      }
    });
  }

  /// Inicializa el stream de conversaciones
  Future<void> start() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      // Sincronizar usuario actual si no existe en Firebase
      await _syncCurrentUser();

      // Suscribirse al stream de conversaciones
      _conversationsSubscription = _chatService
          .getConversations(currentUserId)
          .listen(
            (conversations) {
              _conversations = conversations;

              // Suscribirse al estado de presencia de cada usuario
              _subscribeToUserPresences(conversations);

              _loading = false;
              _error = null;
              notifyListeners();
            },
            onError: (error) {
              developer.log(
                'Error en stream de conversaciones',
                error: error,
                name: 'ChatListViewModel',
              );
              _error = 'Error al cargar conversaciones: ${error.toString()}';
              _loading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      developer.log(
        'Error al iniciar ChatListViewModel',
        error: e,
        name: 'ChatListViewModel',
      );
      _error = 'Error al iniciar: ${e.toString()}';
      _loading = false;
      notifyListeners();
    }
  }

  /// Suscribe a los cambios de presencia de los usuarios en las conversaciones
  void _subscribeToUserPresences(List<Conversation> conversations) {
    // Obtener todos los IDs de usuarios únicos (excepto el usuario actual)
    final Set<String> userIds = {};
    for (var conv in conversations) {
      for (var userId in conv.participantIds) {
        if (userId != currentUserId) {
          userIds.add(userId);
        }
      }
    }

    // Cancelar suscripciones de usuarios que ya no están en las conversaciones
    final idsToRemove = _presenceSubscriptions.keys
        .where((id) => !userIds.contains(id))
        .toList();
    for (var id in idsToRemove) {
      _presenceSubscriptions[id]?.cancel();
      _presenceSubscriptions.remove(id);
      _userOnlineStatus.remove(id);
    }

    // Suscribirse a nuevos usuarios
    for (var userId in userIds) {
      if (!_presenceSubscriptions.containsKey(userId)) {
        _presenceSubscriptions[userId] = _chatService
            .getUserPresence(userId)
            .listen((data) {
              if (data != null) {
                final isOnline = data['is_online'] as bool? ?? false;
                if (_userOnlineStatus[userId] != isOnline) {
                  _userOnlineStatus[userId] = isOnline;
                  notifyListeners();
                }
              }
            });
      }
    }
  }

  /// Cancela todas las suscripciones de presencia
  void _cancelAllPresenceSubscriptions() {
    for (var subscription in _presenceSubscriptions.values) {
      subscription.cancel();
    }
    _presenceSubscriptions.clear();
    _userOnlineStatus.clear();
  }

  /// Sincroniza el usuario actual de Supabase a Firebase si no existe
  Future<void> _syncCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Verificar si el usuario ya existe en Firebase
      final existingUser = await _chatService.getChatUser(user.id);
      if (existingUser != null) return;

      // Si no existe, sincronizarlo desde Supabase usando UserSyncService
      await _userSyncService.syncCurrentUser();

      developer.log(
        'Usuario sincronizado a Firebase correctamente',
        name: 'ChatListViewModel',
      );
    } catch (e) {
      developer.log(
        'Error al sincronizar usuario actual',
        error: e,
        name: 'ChatListViewModel',
      );
    }
  }

  /// Actualiza el query de búsqueda
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Limpia el query de búsqueda
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Elimina una conversación
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _chatService.deleteConversation(conversationId);
      // El stream se actualizará automáticamente
    } catch (e) {
      developer.log(
        'Error al eliminar conversación',
        error: e,
        name: 'ChatListViewModel',
      );
      _error = 'Error al eliminar conversación: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Marca una conversación como leída
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _chatService.markMessagesAsRead(
        conversationId: conversationId,
        userId: currentUserId,
      );
    } catch (e) {
      developer.log(
        'Error al marcar conversación como leída',
        error: e,
        name: 'ChatListViewModel',
      );
    }
  }

  /// Obtiene información del otro usuario en una conversación
  ChatUser? getOtherUser(Conversation conversation) {
    return conversation.getOtherUser(currentUserId);
  }

  /// Recarga las conversaciones
  Future<void> refresh() async {
    // El stream se encargará de actualizar automáticamente
    // Solo necesitamos sincronizar el usuario actual
    await _syncCurrentUser();
    notifyListeners();
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _authSubscription?.cancel();
    _cancelAllPresenceSubscriptions();
    super.dispose();
  }
}
