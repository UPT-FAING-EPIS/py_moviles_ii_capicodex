/// Entidad de dominio que representa una instalación deportiva activa.
///
/// No depende de Supabase, Flutter ni de clases de infraestructura.
class InstitucionDeportiva {
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

  const InstitucionDeportiva({
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
}
