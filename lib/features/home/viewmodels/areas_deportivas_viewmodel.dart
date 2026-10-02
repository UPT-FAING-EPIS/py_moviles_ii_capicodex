import 'package:gameon/features/home/models/area_deportiva.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AreasDeportivasViewModel {
  final int institucionId;
  AreasDeportivasViewModel(this.institucionId);

  Future<List<AreaDeportiva>> fetchAreas() async {
    final data = await Supabase.instance.client
        .from('areas_deportivas')
        .select()
        .eq('institucion_deportiva_id', institucionId);
    return (data as List).map((json) => AreaDeportiva.fromJson(json)).toList();
  }
}
