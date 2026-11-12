import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/reservas/models/calificacion_instalacion.dart';

void main() {
  test('convierte la respuesta de la función de calificación', () {
    final calificacion = CalificacionInstalacion.fromJson({
      'id': 7,
      'reserva_id': 21,
      'institucion_deportiva_id': 4,
      'puntuacion': 5,
      'comentario': 'Muy buena cancha',
    });

    expect(calificacion.id, 7);
    expect(calificacion.reservaId, 21);
    expect(calificacion.institucionDeportivaId, 4);
    expect(calificacion.puntuacion, 5);
    expect(calificacion.comentario, 'Muy buena cancha');
  });
}
