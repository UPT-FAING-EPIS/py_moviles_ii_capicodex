import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/chat/views/conversation_view.dart';
import '../../features/reservas/views/reservas_list/reserva_detail_view.dart';

/// Servicio encargado de manejar la navegación desde notificaciones
///
/// Este servicio contiene toda la lógica para navegar a las pantallas
/// correspondientes cuando el usuario interactúa con una notificación.
class NotificationNavigationService {
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationNavigationService(this.navigatorKey);

  // ==========================================================================
  // MÉTODOS PÚBLICOS
  // ==========================================================================

  /// Maneja el tap en una notificación y navega a la pantalla correspondiente
  ///
  /// [data] contiene la información de la notificación:
  /// - tipo: 'mensaje' o 'reserva'
  /// - conversation_id: ID de la conversación (para mensajes)
  /// - referencia_id/reserva_id: ID de la reserva
  void handleNotificationTap(Map<String, dynamic> data) {
    final tipo = data['tipo'] ?? '';

    if (tipo == 'mensaje') {
      navigateToConversation(data['conversation_id']);
    } else {
      // Notificaciones de reserva
      navigateToReserva(data['referencia_id'] ?? data['reserva_id']);
    }
  }

  // ==========================================================================
  // NAVEGACIÓN A RESERVAS
  // ==========================================================================

  /// Navega a la vista de detalle de una reserva
  void navigateToReserva(String? reservaIdStr) {
    final id = int.tryParse(reservaIdStr ?? '');
    if (id == null) {
      debugPrint('[NotificationNav] ID de reserva inválido: $reservaIdStr');
      return;
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ReservaDetailView.fromId(reservaId: id),
      ),
    );
  }

  // ==========================================================================
  // NAVEGACIÓN A CONVERSACIONES
  // ==========================================================================

  /// Navega a la vista de conversación de chat
  ///
  /// Obtiene los datos de la conversación desde Firestore y navega
  /// a ConversationView con la información del otro usuario.
  Future<void> navigateToConversation(String? conversationId) async {
    if (conversationId == null || conversationId.isEmpty) {
      debugPrint(
        '[NotificationNav] ID de conversación inválido: $conversationId',
      );
      return;
    }

    debugPrint('[NotificationNav] Navegando a conversación: $conversationId');

    try {
      // Obtener datos de la conversación desde Firestore
      final conversationDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        debugPrint(
          '[NotificationNav] Conversación no encontrada: $conversationId',
        );
        return;
      }

      final data = conversationDoc.data()!;
      final participants = data['participants'] as Map<String, dynamic>?;

      if (participants == null) {
        debugPrint('[NotificationNav] No hay participantes en la conversación');
        return;
      }

      // Obtener el ID del usuario actual
      final currentUser = Supabase.instance.client.auth.currentUser;
      final currentUserId = currentUser?.id;

      if (currentUserId == null) {
        debugPrint('[NotificationNav] Usuario no autenticado');
        return;
      }

      // Encontrar el otro usuario (el que NO es el usuario actual)
      String? otherUserName;
      String? otherUserAvatar;

      for (var entry in participants.entries) {
        if (entry.key != currentUserId) {
          final otherUser = entry.value as Map<String, dynamic>;
          otherUserName = otherUser['nombre'] as String?;
          otherUserAvatar = otherUser['foto_perfil'] as String?;
          break;
        }
      }

      if (otherUserName == null) {
        debugPrint('[NotificationNav] No se pudo identificar al otro usuario');
        return;
      }

      // Navegar a la vista de conversación
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ConversationView(
            conversationId: conversationId,
            otherUserName: otherUserName!,
            otherUserAvatar: otherUserAvatar,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationNav] Error al navegar a conversación: $e');
    }
  }
}
