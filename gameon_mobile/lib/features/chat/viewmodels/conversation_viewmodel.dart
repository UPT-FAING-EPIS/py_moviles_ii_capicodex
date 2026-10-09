import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/chat_user.dart';
import '../services/chat_service.dart';

/// ViewModel para gestionar una conversación individual.
///
/// Características:
/// - Stream en tiempo real de mensajes
/// - Envío de mensajes de texto e imágenes
/// - Marcado automático de mensajes como leídos
/// - Gestión de estados de carga y errores
class ConversationViewModel extends ChangeNotifier {
  final String conversationId;
  final ChatService _chatService;
  final supabase = Supabase.instance.client;

  // Estado
  List<Message> _messages = [];
  Conversation? _conversation;
  bool _loading = false;
  bool _sendingMessage = false;
  String? _error;
  bool? _otherUserOnline;
  DateTime? _otherUserLastSeen;

  // Estado de subida de imagen
  double _uploadProgress = 0.0;
  bool _uploadingImage = false;

  // Streams
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<Conversation?>? _conversationSubscription;
  StreamSubscription<Map<String, dynamic>?>? _presenceSubscription;

  // Getters
  List<Message> get messages => _messages;
  Conversation? get conversation => _conversation;
  bool get loading => _loading;
  bool get sendingMessage => _sendingMessage;
  String? get error => _error;
  bool get hasMessages => _messages.isNotEmpty;
  bool? get otherUserOnline => _otherUserOnline;
  DateTime? get otherUserLastSeen => _otherUserLastSeen;
  double get uploadProgress => _uploadProgress;
  bool get uploadingImage => _uploadingImage;

  String get currentUserId {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    return user.id;
  }

  ConversationViewModel({
    required this.conversationId,
    ChatService? chatService,
  }) : _chatService = chatService ?? ChatService();

  /// Inicializa los streams de mensajes y conversación
  Future<void> start() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      // Cargar información de la conversación
      await _loadConversation();

      // Suscribirse al stream de mensajes
      _messagesSubscription = _chatService
          .getMessages(conversationId)
          .listen(
            (messages) {
              _messages = messages;
              _loading = false;
              _error = null;
              notifyListeners();

              // Marcar mensajes como leídos automáticamente
              _markMessagesAsRead();
            },
            onError: (error) {
              developer.log(
                'Error en stream de mensajes',
                error: error,
                name: 'ConversationViewModel',
              );
              _error = 'Error al cargar mensajes: ${error.toString()}';
              _loading = false;
              notifyListeners();
            },
          );

      // Suscribirse al stream de la conversación para obtener updates
      _conversationSubscription = _chatService
          .getConversation(conversationId)
          .listen(
            (conversation) async {
              _conversation = conversation;
              final other = conversation?.getOtherUser(currentUserId);
              final otherId = other?.id;

              if (otherId != null) {
                // 1. Suscribirse a presencia
                _presenceSubscription?.cancel();
                _presenceSubscription = _chatService
                    .getUserPresence(otherId)
                    .listen((data) {
                      _otherUserOnline = data?['is_online'] as bool?;
                      final ts = data?['last_seen'];
                      if (ts is Timestamp) {
                        _otherUserLastSeen = ts.toDate();
                      } else {
                        _otherUserLastSeen = null;
                      }
                      notifyListeners();
                    });

                // 2. Actualizar foto del OTRO usuario si no tiene o si queremos asegurar la última
                // Esto asegura que veas su foto incluso si él no ha entrado al chat
                try {
                  final response = await supabase
                      .from('usuarios_deportistas')
                      .select('nombre, apellidos, imagen_perfil')
                      .eq('auth_id', otherId)
                      .maybeSingle();

                  if (response != null) {
                    final nombre = response['nombre'] as String? ?? '';
                    final apellidos = response['apellidos'] as String? ?? '';
                    final nombreCompleto = '$nombre $apellidos'.trim();
                    final imagenPerfil = response['imagen_perfil'] as String?;

                    // Solo actualizar si hay cambios para evitar escrituras innecesarias
                    if (other?.fotoPerfil != imagenPerfil ||
                        other?.nombre != nombreCompleto) {
                      final updatedOtherUser = ChatUser(
                        id: otherId,
                        nombre: nombreCompleto.isEmpty
                            ? 'Usuario'
                            : nombreCompleto,
                        fotoPerfil: imagenPerfil,
                      );

                      await _chatService.updateParticipantInfo(
                        conversationId: conversationId,
                        user: updatedOtherUser,
                      );
                      developer.log(
                        'Info del otro usuario actualizada',
                        name: 'ConversationViewModel',
                      );
                    }
                  }
                } catch (e) {
                  developer.log(
                    'Error actualizando info del otro usuario',
                    error: e,
                  );
                }
              }
              notifyListeners();
            },
            onError: (error) {
              developer.log(
                'Error en stream de conversación',
                error: error,
                name: 'ConversationViewModel',
              );
            },
          );

      // Actualizar información del participante al entrar
      try {
        final user = supabase.auth.currentUser;
        if (user != null) {
          final response = await supabase
              .from('usuarios_deportistas')
              .select('nombre, apellidos, imagen_perfil')
              .eq('auth_id', user.id)
              .maybeSingle();

          final nombreUser = response?['nombre'] as String? ?? '';
          final apellidosUser = response?['apellidos'] as String? ?? '';
          final nombreCompleto = '$nombreUser $apellidosUser'.trim();
          final imagenPerfil = response?['imagen_perfil'] as String?;

          final currentUser = ChatUser(
            id: user.id,
            nombre: nombreCompleto.isEmpty ? 'Usuario' : nombreCompleto,
            fotoPerfil: imagenPerfil,
          );

          await _chatService.updateParticipantInfo(
            conversationId: conversationId,
            user: currentUser,
          );
        }
      } catch (e) {
        developer.log('Error al actualizar info de participante', error: e);
      }
    } catch (e) {
      developer.log(
        'Error al iniciar ConversationViewModel',
        error: e,
        name: 'ConversationViewModel',
      );
      _error = 'Error al iniciar: ${e.toString()}';
      _loading = false;
      notifyListeners();
    }
  }

  /// Marca los mensajes no leídos como leídos
  Future<void> _markMessagesAsRead() async {
    try {
      await _chatService.markMessagesAsRead(
        conversationId: conversationId,
        userId: currentUserId,
      );
    } catch (e) {
      developer.log(
        'Error al marcar mensajes como leídos',
        error: e,
        name: 'ConversationViewModel',
      );
    }
  }

  /// Carga la información inicial de la conversación
  Future<void> _loadConversation() async {
    try {
      // El stream se encargará de cargar la conversación
      // Esta función está aquí por si necesitamos hacer alguna inicialización adicional
    } catch (e) {
      developer.log(
        'Error al cargar conversación',
        error: e,
        name: 'ConversationViewModel',
      );
    }
  }

  /// Envía un mensaje de texto
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      _sendingMessage = true;
      _error = null;
      notifyListeners();

      // Obtener información del usuario actual
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener perfil del usuario
      final response = await supabase
          .from('usuarios_deportistas')
          .select('nombre, apellidos, imagen_perfil')
          .eq('auth_id', user.id)
          .maybeSingle();

      developer.log(
        'Perfil obtenido de Supabase: $response',
        name: 'ConversationViewModel',
      );

      final nombreUser = response?['nombre'] as String? ?? '';
      final apellidosUser = response?['apellidos'] as String? ?? '';
      final nombreCompleto = '$nombreUser $apellidosUser'.trim();
      final imagenPerfil = response?['imagen_perfil'] as String?;

      developer.log(
        'Enviando mensaje con foto: $imagenPerfil',
        name: 'ConversationViewModel',
      );

      await _chatService.sendMessage(
        conversationId: conversationId,
        senderId: currentUserId,
        senderNombre: nombreCompleto.isEmpty ? 'Usuario' : nombreCompleto,
        senderFotoPerfil: imagenPerfil,
        content: text.trim(),
        type: MessageType.text,
      );

      _sendingMessage = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Error al enviar mensaje',
        error: e,
        name: 'ConversationViewModel',
      );
      _error = 'Error al enviar mensaje: ${e.toString()}';
      _sendingMessage = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Envía un mensaje con imagen
  Future<void> sendImageMessage(String imageUrl) async {
    try {
      _sendingMessage = true;
      _error = null;
      notifyListeners();

      // Obtener información del usuario actual
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener perfil del usuario
      final response = await supabase
          .from('usuarios_deportistas')
          .select('nombre, apellidos, imagen_perfil')
          .eq('auth_id', user.id)
          .maybeSingle();

      final nombreUser = response?['nombre'] as String? ?? '';
      final apellidosUser = response?['apellidos'] as String? ?? '';
      final nombreCompleto = '$nombreUser $apellidosUser'.trim();
      final imagenPerfil = response?['imagen_perfil'] as String?;

      await _chatService.sendMessage(
        conversationId: conversationId,
        senderId: currentUserId,
        senderNombre: nombreCompleto.isEmpty ? 'Usuario' : nombreCompleto,
        senderFotoPerfil: imagenPerfil,
        content: '',
        type: MessageType.image,
        imageUrl: imageUrl,
        lastMessageContent: '🖼️ Imagen',
      );

      _sendingMessage = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Error al enviar imagen',
        error: e,
        name: 'ConversationViewModel',
      );
      _error = 'Error al enviar imagen: ${e.toString()}';
      _sendingMessage = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sube una imagen a Firebase Storage y retorna la URL de descarga
  Future<String?> uploadImage(String localPath) async {
    try {
      _uploadingImage = true;
      _uploadProgress = 0.0;
      notifyListeners();

      // 1. Crear referencia al archivo
      final file = File(localPath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(localPath)}';
      final storageRef = FirebaseStorage.instance.ref().child(
        'chat-images/$currentUserId/$fileName',
      );

      // 2. Configurar metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': currentUserId,
          'conversation_id': conversationId,
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );

      // 3. Subir archivo con seguimiento de progreso
      final uploadTask = storageRef.putFile(file, metadata);

      // Escuchar progreso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
      });

      // 4. Esperar a que termine
      final snapshot = await uploadTask;

      // 5. Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();

      developer.log(
        'Image uploaded successfully',
        name: 'ConversationViewModel',
      );

      return downloadUrl;
    } catch (e) {
      developer.log(
        'Error uploading image',
        error: e,
        name: 'ConversationViewModel',
      );
      return null;
    } finally {
      _uploadingImage = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Elimina una imagen de Firebase Storage (opcional, para limpieza)
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
      developer.log(
        'Image deleted successfully',
        name: 'ConversationViewModel',
      );
    } catch (e) {
      developer.log(
        'Error deleting image',
        error: e,
        name: 'ConversationViewModel',
      );
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _conversationSubscription?.cancel();
    _presenceSubscription?.cancel();
    super.dispose();
  }
}
