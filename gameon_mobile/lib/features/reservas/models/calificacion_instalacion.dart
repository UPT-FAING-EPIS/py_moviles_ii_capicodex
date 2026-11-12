class CalificacionInstalacion {
  final int id;
  final int reservaId;
  final int institucionDeportivaId;
  final int puntuacion;
  final String? comentario;

  const CalificacionInstalacion({
    required this.id,
    required this.reservaId,
    required this.institucionDeportivaId,
    required this.puntuacion,
    this.comentario,
  });

  factory CalificacionInstalacion.fromJson(Map<String, dynamic> json) =>
      CalificacionInstalacion(
        id: (json['id'] as num).toInt(),
        reservaId: (json['reserva_id'] as num).toInt(),
        institucionDeportivaId: (json['institucion_deportiva_id'] as num)
            .toInt(),
        puntuacion: (json['puntuacion'] as num).toInt(),
        comentario: json['comentario'] as String?,
      );
}
