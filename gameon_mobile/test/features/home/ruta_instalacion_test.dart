import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/home/models/institucion_deportiva.dart';
import 'package:gameon/features/home/viewmodels/institucion_detail_viewmodel.dart';
import 'package:gameon/features/home/views/institucion_detail_view.dart';

void main() {
  final instalacion = InstitucionDeportiva(
    id: 42,
    usuarioInstalacionId: 17,
    nombre: 'Instalación de prueba',
    direccion: 'Av. de prueba 123',
    latitud: -18.01,
    longitud: -70.25,
    tarifa: 50,
    calificacion: 4,
    telefono: '999000111',
    email: 'contacto@example.com',
    estado: 1,
  );

  late _RutaViewModel viewModel;
  setUp(() => viewModel = _RutaViewModel());
  tearDown(() => viewModel.dispose());

  Future<void> pulsarComoLlegar(
    WidgetTester tester,
    InstitucionDeportiva destino,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InstitucionDetailView(institucion: destino, viewModel: viewModel),
      ),
    );
    await tester.tap(find.text('Cómo llegar'));
    await tester.pumpAndSettle();
  }

  testWidgets('solo abre la ruta con las coordenadas al confirmar', (
    tester,
  ) async {
    await pulsarComoLlegar(tester, instalacion);

    expect(find.text('¿Abrir ruta en Google Maps?'), findsOneWidget);
    expect(viewModel.destinos, isEmpty);

    await tester.tap(find.text('Abrir ruta'));
    await tester.pumpAndSettle();

    final enlace = viewModel.destinos.single;
    expect(enlace.origin, 'https://www.google.com');
    expect(enlace.path, '/maps/dir/');
    expect(enlace.queryParameters, {
      'api': '1',
      'destination': '-18.01,-70.25',
    });
  });

  testWidgets('cancelar conserva la ficha sin abrir Maps', (tester) async {
    await pulsarComoLlegar(tester, instalacion);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Abrir ruta en Google Maps?'), findsNothing);
    expect(find.text('Cómo llegar'), findsOneWidget);
    expect(viewModel.destinos, isEmpty);
  });

  testWidgets('una ubicación inválida bloquea la apertura', (tester) async {
    await pulsarComoLlegar(tester, instalacion.copyWith(latitud: 91));

    expect(
      find.text('Esta instalación no tiene una ubicación válida.'),
      findsOneWidget,
    );
    expect(find.text('¿Abrir ruta en Google Maps?'), findsNothing);
    expect(viewModel.destinos, isEmpty);
  });

  test('rechaza coordenadas fuera de rango, no finitas y sin configurar', () {
    for (final (lat, lng) in <(double, double)>[
      (double.nan, -70),
      (-18, double.infinity),
      (-91, -70),
      (-18, -181),
      (-18, 181),
      (0, 0),
    ]) {
      expect(
        viewModel.rutaExterna(
          instalacion.copyWith(latitud: lat, longitud: lng),
        ),
        isNull,
      );
    }
    expect(viewModel.rutaExterna(instalacion.copyWith(latitud: 0)), isNotNull);
  });

  for (final errorDelSistema in [false, true]) {
    testWidgets('informa fallo al abrir Maps (excepción: $errorDelSistema)', (
      tester,
    ) async {
      viewModel.puedeAbrir = false;
      viewModel.errorDelSistema = errorDelSistema;

      await pulsarComoLlegar(tester, instalacion);
      await tester.tap(find.text('Abrir ruta'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo abrir Google Maps.'), findsOneWidget);
      expect(find.text('Cómo llegar'), findsOneWidget);
    });
  }
}

class _RutaViewModel extends InstitucionDetailViewModel {
  _RutaViewModel() : super(42);

  final destinos = <Uri>[];
  bool puedeAbrir = true;
  bool errorDelSistema = false;

  @override
  Future<void> loadDetail({
    InstitucionDeportiva? institucion,
    bool isRetry = false,
  }) async {}

  @override
  Future<bool> abrirRuta(Uri destino) async {
    destinos.add(destino);
    if (errorDelSistema) throw PlatformException(code: 'LAUNCH_FAILED');
    return puedeAbrir;
  }
}
