import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/home/models/deporte.dart';
import 'package:gameon/features/home/models/horario_atencion.dart';
import 'package:gameon/features/home/models/institucion_deportiva.dart';
import 'package:gameon/features/home/viewmodels/institucion_detail_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InstitucionDetailViewModel - Pruebas Unitarias', () {
    test('Caché: guarda y recupera horarios, deportes, servicios y fotografías', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final vm = InstitucionDetailViewModel(42, prefs: prefs);
      vm.horarios.add(
        HorarioAtencion(
          id: 10,
          institucionDeportivaId: 42,
          dia: 'Miércoles',
          horaApertura: '08:00:00',
          horaCierre: '23:00:00',
        ),
      );
      vm.deportes.add(Deporte(id: 1, nombre: 'Básquet'));
      vm.servicios.addAll(['Wi-Fi', 'Estacionamiento']);
      vm.fotografias.addAll(['https://img.com/1.png', 'https://img.com/2.png']);

      // Guardar en caché
      await vm.saveToCache();

      // Nuevo viewmodel leyendo de la misma caché
      final vm2 = InstitucionDetailViewModel(42, prefs: prefs);
      final exito = await vm2.loadFromCache();

      expect(exito, isTrue);
      expect(vm2.horarios.length, equals(1));
      expect(vm2.horarios.first.dia, equals('Miércoles'));
      expect(vm2.deportes.length, equals(1));
      expect(vm2.deportes.first.nombre, equals('Básquet'));
      expect(vm2.servicios, containsAll(['Wi-Fi', 'Estacionamiento']));
      expect(vm2.fotografias.length, equals(2));
      expect(vm2.cachedAt, isNotNull);
    });

    test('fetchServicios: detecta servicios desde descripcion o utiliza los registrados', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final vm = InstitucionDetailViewModel(1, prefs: prefs);

      // Con servicios explícitos
      final instExplicito = InstitucionDeportiva(
        id: 1,
        usuarioInstalacionId: 1,
        nombre: 'Cancha Pro',
        direccion: 'Calle 1',
        latitud: 0,
        longitud: 0,
        tarifa: 50,
        calificacion: 5,
        telefono: '123',
        email: 'a@a.com',
        estado: 1,
        servicios: ['Duchas', 'Cafetería'],
      );
      final servicios = await vm.fetchServicios(institucion: instExplicito);
      expect(servicios, equals(['Duchas', 'Cafetería']));

      // Sin servicios y sin descripción
      final instVacio = InstitucionDeportiva(
        id: 2,
        usuarioInstalacionId: 1,
        nombre: 'Cancha Básica',
        direccion: 'Calle 2',
        latitud: 0,
        longitud: 0,
        tarifa: 20,
        calificacion: 3,
        telefono: '123',
        email: 'b@b.com',
        estado: 1,
        descripcion: null,
      );
      final serviciosVacio = await vm.fetchServicios(institucion: instVacio);
      expect(serviciosVacio, isEmpty);
    });

    test('fetchFotografias: incluye imagen principal y evita duplicados', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final vm = InstitucionDetailViewModel(1, prefs: prefs);

      final inst = InstitucionDeportiva(
        id: 1,
        usuarioInstalacionId: 1,
        nombre: 'Cancha Foto',
        direccion: 'Calle 3',
        latitud: 0,
        longitud: 0,
        tarifa: 30,
        calificacion: 4,
        telefono: '123',
        email: 'c@c.com',
        estado: 1,
        imagen: 'https://img.com/principal.jpg',
      );

      final fotos = await vm.fetchFotografias(institucion: inst);
      expect(fotos, contains('https://img.com/principal.jpg'));
    });

    test('loadDetail: ante fallo y sin caché, asigna mensaje amigable sin detalles técnicos', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // ViewModel sin cliente configurado simula error de servidor/conexión
      final vm = InstitucionDetailViewModel(999, prefs: prefs);
      await vm.loadDetail();

      expect(vm.isFromCache, isFalse);
      expect(vm.errorMessage, isNotNull);
      expect(vm.errorMessage, contains('No fue posible cargar'));
      expect(vm.errorMessage, isNot(contains('Exception')));
      expect(vm.errorMessage, isNot(contains('500')));
    });
  });
}
