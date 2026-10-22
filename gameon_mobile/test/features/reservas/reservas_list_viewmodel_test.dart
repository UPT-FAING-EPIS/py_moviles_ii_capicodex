import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/reservas/models/reserva.dart';
import 'package:gameon/features/reservas/viewmodels/reservas_list_viewmodel.dart';

void main() {
  group('ReservasListViewModel - Pruebas Unitarias', () {
    late ReservasListViewModel viewModel;

    setUp(() {
      viewModel = ReservasListViewModel();
    });

    tearDown(() {
      ReservasListViewModel.clearInstance();
    });

    test('Estado inicial es vacío y sin errores', () {
      expect(viewModel.reservas, isEmpty);
      expect(viewModel.cargando, isFalse);
      expect(viewModel.error, isNull);
    });

    test('setReservasForTesting actualiza lista de reservas y notifica listeners', () {
      bool notified = false;
      viewModel.addListener(() => notified = true);

      final reservaPrueba = Reserva(
        id: 101,
        idUsuario: 42,
        areaDeportivaId: 5,
        fecha: DateTime(2026, 11, 20),
        horaInicio: '18:00:00',
        horaFin: '19:00:00',
        estado: 'Confirmada',
        creadoEn: DateTime(2026, 11, 1),
        montoPagado: 60.0,
        metodoPago: 'paypal',
      );

      viewModel.setReservasForTesting([reservaPrueba]);

      expect(viewModel.reservas.length, 1);
      expect(viewModel.reservas.first.id, 101);
      expect(viewModel.reservas.first.idUsuario, 42);
      expect(notified, isTrue);
    });

    test('setLoadingForTesting actualiza bandera de cargando y notifica', () {
      bool notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.setLoadingForTesting(true);
      expect(viewModel.cargando, isTrue);
      expect(notified, isTrue);

      notified = false;
      viewModel.setLoadingForTesting(false);
      expect(viewModel.cargando, isFalse);
      expect(notified, isTrue);
    });

    test('setErrorForTesting actualiza error y notifica', () {
      bool notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.setErrorForTesting('Fallo de red');
      expect(viewModel.error, 'Fallo de red');
      expect(notified, isTrue);

      notified = false;
      viewModel.setErrorForTesting(null);
      expect(viewModel.error, isNull);
      expect(notified, isTrue);
    });

    test('cargarReservasUsuario sin cliente remoto asigna error de conexión', () async {
      await viewModel.cargarReservasUsuario(idUsuario: 42);

      expect(viewModel.cargando, isFalse);
      expect(viewModel.error, 'No se pudo conectar con el servicio');
    });

    test('Caché de áreas: almacena y recupera área sin necesidad de cliente remoto', () async {
      final area = AreaLite(
        id: 10,
        nombre: 'Cancha Sintética 1',
        institucionId: 3,
        tarifaPorHora: 45.0,
        imagenArea: null,
      );

      expect(viewModel.hasAreaCache(10), isFalse);
      viewModel.addAreaCache(area);
      expect(viewModel.hasAreaCache(10), isTrue);

      final cached = await viewModel.getArea(10);
      expect(cached, isNotNull);
      expect(cached!.nombre, 'Cancha Sintética 1');
      expect(cached.tarifaPorHora, 45.0);
    });

    test('Caché de instituciones: almacena y recupera institución sin cliente remoto', () async {
      final inst = InstitucionLite(
        id: 3,
        nombre: 'Club Internacional Tacna',
        direccion: 'Av. Bolognesi 500',
      );

      expect(viewModel.hasInstitucionCache(3), isFalse);
      viewModel.addInstitucionCache(inst);
      expect(viewModel.hasInstitucionCache(3), isTrue);

      final cached = await viewModel.getInstitucion(3);
      expect(cached, isNotNull);
      expect(cached!.nombre, 'Club Internacional Tacna');
      expect(cached.direccion, 'Av. Bolognesi 500');
    });

    test('Gestión de instancia estática y refreshIfActive', () async {
      ReservasListViewModel.setInstance(viewModel);

      // refreshIfActive con instancia activa
      await ReservasListViewModel.refreshIfActive(42);
      expect(viewModel.error, 'No se pudo conectar con el servicio');

      ReservasListViewModel.clearInstance();
      // refreshIfActive sin instancia activa no arroja excepción
      await ReservasListViewModel.refreshIfActive(42);
    });
  });
}
