import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, system }

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderNombre;
  final String? senderFotoPerfil;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? role; // 'user' | 'assistant' | 'system' - para contexto de IA

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderNombre,
    this.senderFotoPerfil,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.role,
  });

  factory Message.fromJson(Map<String, dynamic> json, String id) {
    return Message(
      id: id,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderNombre: json['sender_nombre'] as String,
      senderFotoPerfil: json['sender_foto_perfil'] as String?,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isRead: json['is_read'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_nombre': senderNombre,
      'sender_foto_perfil': senderFotoPerfil,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'is_read': isRead,
      'image_url': imageUrl,
      if (role != null) 'role': role,
    };
  }
}
