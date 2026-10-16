class HorarioArea {
  final int id;
  final int areaDeportivaId;
  final String dia; // Ej: Lunes, Martes
  final String horaApertura; // HH:mm:ss
  final String horaCierre; // HH:mm:ss
  final bool disponible;

  HorarioArea({
    required this.id,
    required this.areaDeportivaId,
    required this.dia,
    required this.horaApertura,
    required this.horaCierre,
    required this.disponible,
  });

  factory HorarioArea.fromJson(Map<String, dynamic> json) => HorarioArea(
    id: json['id'] as int,
    areaDeportivaId: json['area_deportiva_id'] as int,
    dia: json['dia'] as String,
    horaApertura: json['hora_apertura'] as String,
    horaCierre: json['hora_cierre'] as String,
    disponible: (json['disponible'] ?? 1) == 1,
  );
}

String normalizarDia(DateTime date) {
  // DateTime weekday: 1=Lunes ... 7=Domingo
  const nombres = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miercoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sabado',
    7: 'Domingo',
  };
  return nombres[date.weekday]!;
}
