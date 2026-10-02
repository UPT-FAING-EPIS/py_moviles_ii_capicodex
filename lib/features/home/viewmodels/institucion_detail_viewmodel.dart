import 'package:gameon/features/home/models/horario_atencion.dart';
import 'package:gameon/features/home/models/deporte.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstitucionDetailViewModel {
  final int institucionId;
  InstitucionDetailViewModel(this.institucionId);

  Future<List<HorarioAtencion>> fetchHorarios() async {
    try {
      final data = await Supabase.instance.client
          .from('horarios_atencion')
          .select(
            'id, institucion_deportiva_id, dia, hora_apertura, hora_cierre',
          )
          .eq('institucion_deportiva_id', institucionId);

      final list = (data as List).cast<Map<String, dynamic>>();
      return list
          .map<HorarioAtencion>((json) => HorarioAtencion.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Horarios: $e');
    }
  }

  Future<List<Deporte>> fetchDeportes() async {
    try {
      // Paso 1: obtener IDs de deportes asociados
      final linkRows = await Supabase.instance.client
          .from('instituciones_deportes')
          .select('deporte_id')
          .eq('institucion_deportiva_id', institucionId);

      final ids = (linkRows as List)
          .map((r) => (r as Map<String, dynamic>)['deporte_id'])
          .where((v) => v != null)
          .map<int>((v) => v as int)
          .toSet()
          .toList();

      if (ids.isEmpty) return [];

      // Paso 2: traer deportes por IDs (forma compatible usando filter IN)
      final idsCsv = '(${ids.join(',')})';
      final depRows = await Supabase.instance.client
          .from('deportes')
          .select('id, nombre')
          .filter('id', 'in', idsCsv);

      final list = (depRows as List).cast<Map<String, dynamic>>();
      return list.map((j) => Deporte.fromJson(j)).toList();
    } catch (e) {
      throw Exception('Deportes: $e');
    }
  }
}
