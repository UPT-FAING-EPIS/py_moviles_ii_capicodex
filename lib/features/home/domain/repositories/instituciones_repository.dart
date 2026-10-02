import '../entities/institucion_deportiva.dart';

/// Contrato definido por la capa de dominio.
abstract class InstitucionesRepository {
  Future<List<InstitucionDeportiva>> obtenerInstitucionesActivas();
}
