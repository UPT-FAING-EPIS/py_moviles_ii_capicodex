import '../../domain/entities/institucion_deportiva.dart';
import '../models/institucion_deportiva_dto.dart';

class InstitucionDeportivaMapper {
  const InstitucionDeportivaMapper._();

  static InstitucionDeportiva toDomain(InstitucionDeportivaDto dto) {
    return InstitucionDeportiva(
      id: dto.id,
      usuarioInstalacionId: dto.usuarioInstalacionId,
      nombre: dto.nombre,
      ruc: dto.ruc,
      direccion: dto.direccion,
      latitud: dto.latitud,
      longitud: dto.longitud,
      imagen: dto.imagen,
      tarifa: dto.tarifa,
      calificacion: dto.calificacion,
      telefono: dto.telefono,
      email: dto.email,
      descripcion: dto.descripcion,
      estado: dto.estado,
    );
  }
}
