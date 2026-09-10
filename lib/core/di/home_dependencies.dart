import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/data/datasources/instituciones_remote_datasource.dart';
import '../../features/home/data/repositories/instituciones_repository_impl.dart';
import '../../features/home/domain/usecases/obtener_instituciones_activas.dart';
import '../../features/home/viewmodels/home_viewmodel.dart';

/// Composition root de la funcionalidad Home.
/// La vista solicita un ViewModel ya ensamblado; el ViewModel no conoce Supabase.
class HomeDependencies {
  const HomeDependencies._();

  static HomeViewModel createHomeViewModel() {
    final dataSource = SupabaseInstitucionesRemoteDataSource(
      Supabase.instance.client,
    );
    final repository = InstitucionesRepositoryImpl(dataSource);
    final useCase = ObtenerInstitucionesActivas(repository);
    return HomeViewModel(obtenerInstitucionesActivas: useCase);
  }
}
