import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_user.dart';

class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, ChatUser> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.participantIds,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, String id) {
    final participantsData =
        json['participants'] as Map<String, dynamic>? ?? {};
    final participants = participantsData.map(
      (key, value) =>
          MapEntry(key, ChatUser.fromJson(value as Map<String, dynamic>)),
    );

    return Conversation(
      id: id,
      participantIds: List<String>.from(json['participant_ids'] ?? []),
      participants: participants,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? (json['last_message_time'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      unreadCount: Map<String, int>.from(json['unread_count'] ?? {}),
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participant_ids': participantIds,
      'participants': participants.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'last_message_sender_id': lastMessageSenderId,
      'unread_count': unreadCount,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // Obtener el otro usuario en una conversación 1:1
  ChatUser? getOtherUser(String currentUserId) {
    return participants.values.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => participants.values.first,
    );
  }

  // Obtener el conteo de mensajes no leídos para un usuario específico
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }
}
