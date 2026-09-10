import '../entities/institucion_deportiva.dart';
import '../repositories/instituciones_repository.dart';

/// Caso de uso ligero para la funcionalidad de consulta de instalaciones.
class ObtenerInstitucionesActivas {
  final InstitucionesRepository repository;

  const ObtenerInstitucionesActivas(this.repository);

  Future<List<InstitucionDeportiva>> call() {
    return repository.obtenerInstitucionesActivas();
  }
}
