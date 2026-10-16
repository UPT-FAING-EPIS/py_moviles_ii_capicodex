/// DTO que refleja la estructura devuelta por Supabase.
/// Se mantiene separado de la entidad de dominio para evitar acoplamiento.
class InstitucionDeportivaDto {
  final int id;
  final int usuarioInstalacionId;
  final String nombre;
  final String? ruc;
  final String direccion;
  final double latitud;
  final double longitud;
  final String? imagen;
  final double tarifa;
  final double calificacion;
  final String telefono;
  final String email;
  final String? descripcion;
  final int estado;

  const InstitucionDeportivaDto({
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

  factory InstitucionDeportivaDto.fromJson(Map<String, dynamic> json) {
    return InstitucionDeportivaDto(
      id: json['id'] as int,
      usuarioInstalacionId: json['usuario_instalacion_id'] as int,
      nombre: json['nombre'] as String,
      ruc: json['ruc'] as String?,
      direccion: json['direccion'] as String,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      imagen: json['imagen'] as String?,
      tarifa: (json['tarifa'] as num).toDouble(),
      calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0,
      telefono: json['telefono'] as String,
      email: json['email'] as String,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as int,
    );
  }
}
