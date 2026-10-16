// Modelo para los deportes que se pueden practicar en la institución deportiva
class Deporte {
  final int id;
  final String nombre;

  Deporte({required this.id, required this.nombre});

  factory Deporte.fromJson(Map<String, dynamic> json) {
    return Deporte(id: json['id'], nombre: json['nombre']);
  }
}
