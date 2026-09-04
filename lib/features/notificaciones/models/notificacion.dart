import 'package:cloud_firestore/cloud_firestore.dart';

class Notificacion {
  final String id;
  final int usuarioId;
  final String titulo;
  final String mensaje;
  final String tipo;
  final int? referenciaId;
  final DateTime? fecha;
  final bool leido;

  Notificacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    this.referenciaId,
    this.fecha,
    required this.leido,
  });

  factory Notificacion.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final usuarioIdRaw = data['usuario_id'];
    final usuarioId = usuarioIdRaw is int
        ? usuarioIdRaw
        : int.tryParse('${usuarioIdRaw ?? ''}') ?? 0;

    final referenciaIdRaw = data['referencia_id'];
    final referenciaId = referenciaIdRaw == null
        ? null
        : (referenciaIdRaw is int
              ? referenciaIdRaw
              : int.tryParse('${referenciaIdRaw}'));

    final fechaRaw = data['fecha'];
    DateTime? fecha;
    if (fechaRaw is Timestamp) {
      fecha = fechaRaw.toDate();
    } else if (fechaRaw is DateTime) {
      fecha = fechaRaw;
    }

    return Notificacion(
      id: doc.id,
      usuarioId: usuarioId,
      titulo: (data['titulo'] ?? '').toString(),
      mensaje: (data['mensaje'] ?? '').toString(),
      tipo: (data['tipo'] ?? 'general').toString(),
      referenciaId: referenciaId,
      fecha: fecha,
      leido: data['leido'] == true,
    );
  }
}
