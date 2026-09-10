// Modelo para las áreas deportivas de una institución
class AreaDeportiva {
  final int id;
  final int institucionDeportivaId;
  final int deporteId;
  final String nombreArea;
  final String? descripcion;
  final int? capacidadJugadores;
  final double tarifaPorHora;
  final String estado;
  final String? imagenArea;

  AreaDeportiva({
    required this.id,
    required this.institucionDeportivaId,
    required this.deporteId,
    required this.nombreArea,
    this.descripcion,
    this.capacidadJugadores,
    required this.tarifaPorHora,
    required this.estado,
    this.imagenArea,
  });

  factory AreaDeportiva.fromJson(Map<String, dynamic> json) {
    return AreaDeportiva(
      id: json['id'],
      institucionDeportivaId: json['institucion_deportiva_id'],
      deporteId: json['deporte_id'],
      nombreArea: json['nombre_area'],
      descripcion: json['descripcion'],
      capacidadJugadores: json['capacidad_jugadores'],
      tarifaPorHora: (json['tarifa_por_hora'] as num).toDouble(),
      estado: json['estado'] ?? 'activa',
      imagenArea: json['imagen_area'],
    );
  }
}
