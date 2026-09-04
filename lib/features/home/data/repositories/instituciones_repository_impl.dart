import '../../domain/entities/institucion_deportiva.dart';
import '../../domain/repositories/instituciones_repository.dart';
import '../datasources/instituciones_remote_datasource.dart';
import '../mappers/institucion_deportiva_mapper.dart';

class InstitucionesRepositoryImpl implements InstitucionesRepository {
  final InstitucionesRemoteDataSource remoteDataSource;

  InstitucionesRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<InstitucionDeportiva>> obtenerInstitucionesActivas() async {
    final dtos = await remoteDataSource.obtenerInstitucionesActivas();
    return dtos
        .map(InstitucionDeportivaMapper.toDomain)
        .toList(growable: false);
  }
}
