// Modelo que representa una instalación deportiva en la base de datos
class InstitucionDeportiva {
  // Identificador único de la instalación
  final int id;
  // ID del usuario responsable de la instalación
  final int usuarioInstalacionId;
  // Nombre de la instalación deportiva
  final String nombre;
  // RUC de la instalación (opcional)
  final String? ruc;
  // Dirección física de la instalación
  final String direccion;
  // Latitud geográfica
  final double latitud;
  // Longitud geográfica
  final double longitud;
  // URL de la imagen de la instalación (opcional)
  final String? imagen;
  // Tarifa de alquiler
  final double tarifa;
  // Calificación promedio
  final double calificacion;
  // Teléfono de contacto
  final String telefono;
  // Email de contacto
  final String email;
  // Descripción adicional (opcional)
  final String? descripcion;
  // Estado de la instalación (1 = activa)
  final int estado;

  // Constructor del modelo
  InstitucionDeportiva({
    required this.id,
    required this.usuarioInstalacionId,
    required this.nombre,
    this.ruc,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    this.imagen,
    required this.tarifa,
    required this.calificacion,
    required this.telefono,
    required this.email,
    this.descripcion,
    required this.estado,
  });

  // Método para crear una instancia del modelo a partir de un JSON
  factory InstitucionDeportiva.fromJson(Map<String, dynamic> json) {
    return InstitucionDeportiva(
      id: json['id'],
      usuarioInstalacionId: json['usuario_instalacion_id'],
      nombre: json['nombre'],
      ruc: json['ruc'],
      direccion: json['direccion'],
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      imagen: json['imagen'],
      tarifa: (json['tarifa'] as num).toDouble(),
      calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0.0,
      telefono: json['telefono'],
      email: json['email'],
      descripcion: json['descripcion'],
      estado: json['estado'],
    );
  }
}
