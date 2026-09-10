import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import '../models/message.dart';
import '../models/chat_user.dart';

class BotConversationViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  final ChatService _chatService = ChatService();

  String? _conversationId;
  String? _userId;
  String? _userName;
  String? _userPhoto;
  StreamSubscription<List<Message>>? _messagesSubscription;

  final List<Message> _messages = [];
  bool _busy = false;
  bool _isTyping = false;
  String? _error;
  bool _initialized = false;
  bool _disposed = false;

  List<Message> get messages => _messages;
  bool get busy => _busy;
  bool get isTyping => _isTyping;
  String? get error => _error;
  bool get initialized => _initialized;

  /// Inicializar conversación con el bot
  Future<void> initialize({
    required String userId,
    required String userName,
    String? userPhoto,
  }) async {
    if (_initialized) return;

    _userId = userId;
    _userName = userName;
    _userPhoto = userPhoto;

    try {
      // Crear o recuperar conversación con el bot
      final user = ChatUser(
        id: userId,
        nombre: userName,
        fotoPerfil: userPhoto,
      );

      _conversationId = await _chatService.getOrCreateBotConversation(
        userId: userId,
        user: user,
      );

      // Escuchar mensajes en tiempo real
      _listenToMessages();

      _initialized = true;
      if (!_disposed) notifyListeners();
    } catch (e) {
      _error = 'Error al inicializar conversación: $e';
      if (!_disposed) notifyListeners();
    }
  }

  /// Escuchar mensajes en tiempo real desde Firestore
  void _listenToMessages() {
    if (_conversationId == null) return;

    _messagesSubscription = _chatService
        .getMessages(_conversationId!)
        .listen(
          (messages) {
            if (!_disposed) {
              _messages.clear();
              _messages.addAll(messages);
              notifyListeners();
            }
          },
          onError: (error) {
            if (!_disposed) {
              _error = 'Error al cargar mensajes: $error';
              notifyListeners();
            }
          },
        );
  }

  /// Enviar mensaje del usuario
  Future<void> sendMessage(String text) async {
    final t = text.trim();
    if (t.isEmpty || _conversationId == null || _userId == null) return;

    _busy = true;
    _error = null;
    if (!_disposed) notifyListeners();

    try {
      // 1. Guardar mensaje del usuario en Firestore
      await _chatService.sendBotMessage(
        conversationId: _conversationId!,
        senderId: _userId!,
        senderNombre: _userName ?? 'Usuario',
        senderFotoPerfil: _userPhoto,
        content: t,
        role: 'user',
      );

      // 2. Mostrar animación de escribiendo
      _isTyping = true;
      notifyListeners();

      // 3. Llamar al bot
      final reply = await _callBot(t);

      // 4. Ocultar animación de escribiendo
      _isTyping = false;

      // 5. Guardar respuesta del bot en Firestore
      await _chatService.sendBotMessage(
        conversationId: _conversationId!,
        senderId: 'bot_assistant',
        senderNombre: 'Asistente GameOn',
        content: reply ?? 'No se pudo obtener respuesta',
        role: 'assistant',
      );
    } catch (e) {
      _error = 'Error al enviar mensaje: $e';
      _isTyping = false;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Llamar al bot via Edge Function
  Future<String?> _callBot(String prompt) async {
    try {
      final session = supabase.auth.currentSession;
      final accessToken = session?.accessToken;
      final res = await supabase.functions.invoke(
        'chat-bot',
        body: {'message': prompt, 'conversation_id': _conversationId!},
        headers: {
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      );
      final data = res.data;
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }
      if (data is Map) {
        final reply = data['reply'] ?? data['result'] ?? data['message'];
        if (reply is String && reply.trim().isNotEmpty) {
          return reply;
        }
      }
      _error = 'Respuesta del bot sin contenido';
      return null;
    } catch (e) {
      _error = 'Error llamando al bot: $e';
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> clearConversation() async {
    if (_conversationId == null || _userId == null) return;
    _busy = true;
    _isTyping = false;
    notifyListeners();
    try {
      await _chatService.deleteConversation(_conversationId!);
      final user = ChatUser(
        id: _userId!,
        nombre: _userName ?? 'Usuario',
        fotoPerfil: _userPhoto,
      );
      _conversationId = await _chatService.getOrCreateBotConversation(
        userId: _userId!,
        user: user,
      );
      _messages.clear();
      _messagesSubscription?.cancel();
      _listenToMessages();
      _error = null;
    } catch (e) {
      _error = 'Error al limpiar conversación: $e';
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }
}
