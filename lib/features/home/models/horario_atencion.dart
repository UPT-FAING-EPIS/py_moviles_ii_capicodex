// Modelo para los horarios de atención de la institución deportiva
class HorarioAtencion {
  final int id;
  final int institucionDeportivaId;
  final String dia;
  final String horaApertura;
  final String horaCierre;

  HorarioAtencion({
    required this.id,
    required this.institucionDeportivaId,
    required this.dia,
    required this.horaApertura,
    required this.horaCierre,
  });

  factory HorarioAtencion.fromJson(Map<String, dynamic> json) {
    return HorarioAtencion(
      id: json['id'],
      institucionDeportivaId: json['institucion_deportiva_id'],
      dia: json['dia'],
      horaApertura: json['hora_apertura'],
      horaCierre: json['hora_cierre'],
    );
  }
}
