import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion.dart';

class NotificacionesViewModel extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final int usuarioId; // -1 when using string-based id
  String? usuarioIdString; // optional string-based id

  List<Notificacion> items = [];
  bool loading = false;
  String? error;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _usedFallback = false;
  bool _stringTypeFallbackTried = false;

  // Getter para obtener el número de notificaciones no leídas
  int get unreadCount => items.where((notif) => !notif.leido).length;

  NotificacionesViewModel({
    required this.usuarioId,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  // Constructor alternativo para usuarios cuyo id es string
  NotificacionesViewModel.forStringUser({
    required String usuarioIdString,
    FirebaseFirestore? firestore,
  }) : usuarioId = -1,
       usuarioIdString = usuarioIdString,
       firestore = firestore ?? FirebaseFirestore.instance;

  void start() {
    loading = true;
    error = null;
    notifyListeners();

    final equalToValue = usuarioIdString ?? usuarioId;
    final base = firestore
        .collection('notificaciones')
        .where('usuario_id', isEqualTo: equalToValue);

    final queryOrdered = base.orderBy('fecha', descending: true);

    _startSubscription(queryOrdered);
  }

  void _startSubscription(
    Query<Map<String, dynamic>> query, {
    bool sortClient = false,
  }) {
    _sub?.cancel();
    _sub = query.snapshots().listen(
      (snapshot) {
        // Si no hay documentos, intentar una suscripción alternativa por tipo
        if (snapshot.docs.isEmpty && !_stringTypeFallbackTried) {
          _stringTypeFallbackTried = true;
          // Si originalmente usamos int, intentar con string
          if (usuarioIdString == null && usuarioId != -1) {
            final q = firestore
                .collection('notificaciones')
                .where('usuario_id', isEqualTo: usuarioId.toString());
            // Intentar con ordenamiento; si falla, el onError manejará fallback
            _startSubscription(q.orderBy('fecha', descending: true));
            return;
          }
          // Si originalmente usamos string y es parseable a int, intentar con int
          if (usuarioIdString != null) {
            final idInt = int.tryParse(usuarioIdString!);
            if (idInt != null) {
              final q = firestore
                  .collection('notificaciones')
                  .where('usuario_id', isEqualTo: idInt);
              _startSubscription(q.orderBy('fecha', descending: true));
              return;
            }
          }
        }

        var list = snapshot.docs.map((d) => Notificacion.fromDoc(d)).toList();
        if (sortClient) {
          list.sort((a, b) {
            final af = a.fecha?.millisecondsSinceEpoch ?? 0;
            final bf = b.fecha?.millisecondsSinceEpoch ?? 0;
            return bf.compareTo(af);
          });
        }
        items = list;
        loading = false;
        notifyListeners();
      },
      onError: (e) {
        if (!_usedFallback &&
            e is FirebaseException &&
            e.code == 'failed-precondition') {
          _usedFallback = true;
          final equalToValue = usuarioIdString ?? usuarioId;
          final q = firestore
              .collection('notificaciones')
              .where('usuario_id', isEqualTo: equalToValue);
          // Reiniciar suscripción sin orderBy y ordenar en cliente
          _startSubscription(q, sortClient: true);
          return;
        }
        error = e.toString();
        loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> marcarLeido(String id) async {
    try {
      await firestore.collection('notificaciones').doc(id).update({
        'leido': true,
      });
    } catch (e) {
      // Silenciar errores en UI, opcionalmente notificar
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
