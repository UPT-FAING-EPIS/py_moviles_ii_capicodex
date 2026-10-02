import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/institucion_deportiva_dto.dart';

abstract class InstitucionesRemoteDataSource {
  Future<List<InstitucionDeportivaDto>> obtenerInstitucionesActivas();
}

class SupabaseInstitucionesRemoteDataSource
    implements InstitucionesRemoteDataSource {
  final SupabaseClient client;

  SupabaseInstitucionesRemoteDataSource(this.client);

  @override
  Future<List<InstitucionDeportivaDto>> obtenerInstitucionesActivas() async {
    final data = await client
        .from('instituciones_deportivas')
        .select()
        .eq('estado', 1);

    return (data as List)
        .map(
          (item) => InstitucionDeportivaDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }
}
