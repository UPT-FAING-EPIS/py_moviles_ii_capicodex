import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/chat_user.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecciones
  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';
  static const String _usersCollection = 'users';

  // ==================== CONVERSACIONES ====================

  /// Crear o recuperar una conversación entre dos usuarios
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
    required ChatUser currentUser,
    required ChatUser otherUser,
  }) async {
    // Clave determinística para conversación: ids ordenados
    final sorted = [currentUserId, otherUserId]..sort();
    final conversationKey = '${sorted[0]}_${sorted[1]}';

    final docRef = _firestore
        .collection(_conversationsCollection)
        .doc(conversationKey);
    final existing = await docRef.get();
    if (existing.exists) {
      // Actualizar información de participantes si la conversación ya existe
      await docRef.update({
        'participants.${currentUser.id}': currentUser.toJson(),
        'participants.${otherUser.id}': otherUser.toJson(),
      });
      return conversationKey;
    }

    await docRef.set({
      'participant_ids': [currentUserId, otherUserId],
      'participants': {
        currentUserId: currentUser.toJson(),
        otherUserId: otherUser.toJson(),
      },
      'last_message': null,
      'last_message_time': null,
      'last_message_sender_id': null,
      'unread_count': {currentUserId: 0, otherUserId: 0},
      'has_messages': false,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return conversationKey;
  }

  /// Obtener conversaciones del usuario actual (excluye conversaciones con bots)
  Stream<List<Conversation>> getConversations(String userId) {
    return _firestore
        .collection(_conversationsCollection)
        .where('participant_ids', arrayContains: userId)
        .where('has_messages', isEqualTo: true)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) {
                // Filtrar conversaciones con bots
                final data = doc.data();
                final isBotConversation = data['is_bot_conversation'] == true;
                return !isBotConversation;
              })
              .map((doc) => Conversation.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<Map<String, dynamic>?> getUserPresence(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  /// Obtener una conversación específica
  Stream<Conversation?> getConversation(String conversationId) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return Conversation.fromJson(doc.data()!, doc.id);
        });
  }

  /// Actualizar información de usuario en una conversación específica
  Future<void> updateParticipantInfo({
    required String conversationId,
    required ChatUser user,
  }) async {
    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .update({'participants.${user.id}': user.toJson()});
  }

  // ==================== MENSAJES ====================

  /// Enviar un mensaje
  Future<String> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderNombre,
    String? senderFotoPerfil,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? lastMessageContent,
  }) async {
    final message = Message(
      id: '',
      conversationId: conversationId,
      senderId: senderId,
      senderNombre: senderNombre,
      senderFotoPerfil: senderFotoPerfil,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      imageUrl: imageUrl,
    );

    // Agregar mensaje a la subcolección
    final messageRef = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .add(message.toJson());

    // Actualizar la conversación con el último mensaje
    final conversationDoc = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .get();

    final participantIds = List<String>.from(
      conversationDoc.data()?['participant_ids'] ?? [],
    );

    final unreadCount = Map<String, int>.from(
      conversationDoc.data()?['unread_count'] ?? {},
    );

    // Incrementar el contador de no leídos para todos excepto el remitente
    for (var participantId in participantIds) {
      if (participantId != senderId) {
        unreadCount[participantId] = (unreadCount[participantId] ?? 0) + 1;
      }
    }

    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .update({
          'last_message': lastMessageContent ?? content,
          'last_message_time': FieldValue.serverTimestamp(),
          'last_message_sender_id': senderId,
          'unread_count': unreadCount,
          'has_messages': true,
          'updated_at': FieldValue.serverTimestamp(),
          // Actualizar info del remitente en el mapa de participantes
          'participants.$senderId': {
            'id': senderId,
            'nombre': senderNombre,
            'foto_perfil': senderFotoPerfil,
          },
        });

    return messageRef.id;
  }

  /// Obtener mensajes de una conversación
  Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Message.fromJson(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Marcar mensajes como leídos
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    // Obtener todos los mensajes no leídos que no son del usuario actual
    final messagesSnapshot = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .where('sender_id', isNotEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    // Marcar cada mensaje como leído
    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {'is_read': true});
    }

    // Resetear el contador de no leídos del usuario
    batch.update(
      _firestore.collection(_conversationsCollection).doc(conversationId),
      {'unread_count.$userId': 0},
    );

    await batch.commit();
  }

  /// Eliminar un mensaje
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .doc(messageId)
        .delete();

    // Actualizar el último mensaje si es necesario
    final messagesSnapshot = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (messagesSnapshot.docs.isNotEmpty) {
      final lastMessage = Message.fromJson(
        messagesSnapshot.docs.first.data(),
        messagesSnapshot.docs.first.id,
      );

      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
            'last_message': lastMessage.content,
            'last_message_time': Timestamp.fromDate(lastMessage.timestamp),
            'last_message_sender_id': lastMessage.senderId,
          });
    } else {
      // Si no quedan mensajes, limpiar el último mensaje
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
            'last_message': null,
            'last_message_time': null,
            'last_message_sender_id': null,
          });
    }
  }

  // ==================== ESTADO DEL USUARIO ====================

  /// Obtener información de un usuario
  Future<ChatUser?> getChatUser(String userId) async {
    final doc = await _firestore.collection(_usersCollection).doc(userId).get();

    if (!doc.exists) return null;

    return ChatUser.fromJson(doc.data()!);
  }

  // ==================== CONVERSACIONES CON BOT ====================

  /// Crear o recuperar conversación con el bot
  Future<String> getOrCreateBotConversation({
    required String userId,
    required ChatUser user,
  }) async {
    final conversationId = '${userId}_bot_assistant';

    final docRef = _firestore
        .collection(_conversationsCollection)
        .doc(conversationId);

    final existing = await docRef.get();
    if (existing.exists) {
      return conversationId;
    }

    // Bot como ChatUser especial
    final botUser = ChatUser(
      id: 'bot_assistant',
      nombre: 'Asistente GameOn',
      fotoPerfil: null,
    );

    await docRef.set({
      'participant_ids': [userId, 'bot_assistant'],
      'participants': {
        userId: user.toJson(),
        'bot_assistant': {...botUser.toJson(), 'is_bot': true},
      },
      'last_message': null,
      'last_message_time': null,
      'last_message_sender_id': null,
      'unread_count': {userId: 0, 'bot_assistant': 0},
      'has_messages': false,
      'is_bot_conversation': true,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return conversationId;
  }

  /// Enviar mensaje en conversación con bot (incluye role para IA)
  Future<String> sendBotMessage({
    required String conversationId,
    required String senderId,
    required String senderNombre,
    String? senderFotoPerfil,
    required String content,
    required String role, // 'user' | 'assistant' | 'system'
  }) async {
    final message = Message(
      id: '',
      conversationId: conversationId,
      senderId: senderId,
      senderNombre: senderNombre,
      senderFotoPerfil: senderFotoPerfil,
      content: content,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
      role: role,
    );

    // Agregar mensaje a la subcolección
    final messageRef = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .add(message.toJson());

    // Actualizar la conversación con el último mensaje
    final conversationDoc = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .get();

    final participantIds = List<String>.from(
      conversationDoc.data()?['participant_ids'] ?? [],
    );

    final unreadCount = Map<String, int>.from(
      conversationDoc.data()?['unread_count'] ?? {},
    );

    // Incrementar el contador de no leídos para todos excepto el remitente
    for (var participantId in participantIds) {
      if (participantId != senderId) {
        unreadCount[participantId] = (unreadCount[participantId] ?? 0) + 1;
      }
    }

    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .update({
          'last_message': content,
          'last_message_time': FieldValue.serverTimestamp(),
          'last_message_sender_id': senderId,
          'unread_count': unreadCount,
          'has_messages': true,
          'updated_at': FieldValue.serverTimestamp(),
        });

    return messageRef.id;
  }

  // ==================== ELIMINACIÓN ====================

  /// Eliminar una conversación completa
  Future<void> deleteConversation(String conversationId) async {
    // Eliminar todos los mensajes
    final messagesSnapshot = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .get();

    final batch = _firestore.batch();

    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Eliminar la conversación
    batch.delete(
      _firestore.collection(_conversationsCollection).doc(conversationId),
    );

    await batch.commit();
  }
}
