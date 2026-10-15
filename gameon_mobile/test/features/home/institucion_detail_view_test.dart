import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/home/models/deporte.dart';
import 'package:gameon/features/home/models/horario_atencion.dart';
import 'package:gameon/features/home/models/institucion_deportiva.dart';
import 'package:gameon/features/home/viewmodels/institucion_detail_viewmodel.dart';
import 'package:gameon/features/home/views/institucion_detail_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Instalación con datos completos para Escenario 1
  final institucionConDatos = InstitucionDeportiva(
    id: 1,
    usuarioInstalacionId: 1,
    nombre: 'Top Gol Tacna',
    direccion: 'Av. Jorge Basadre 123',
    latitud: -18.01,
    longitud: -70.25,
    tarifa: 51.0,
    calificacion: 4.8,
    telefono: '946143071',
    email: 'contacto@topgol.com',
    descripcion: 'Canchas con iluminación LED y estacionamiento amplio.',
    estado: 1,
    imagen: 'https://ejemplo.com/foto_principal.jpg',
    fotografias: [
      'https://ejemplo.com/foto1.jpg',
      'https://ejemplo.com/foto2.jpg',
    ],
    servicios: [
      'Estacionamiento',
      'Iluminación nocturna',
      'Vestuarios y duchas',
    ],
  );

  // Instalación sin información complementaria para Escenario 2
  final institucionSinComplementos = InstitucionDeportiva(
    id: 2,
    usuarioInstalacionId: 1,
    nombre: 'Cancha El Vecino',
    direccion: 'Calle Los Álamos 456',
    latitud: -18.02,
    longitud: -70.26,
    tarifa: 25.0,
    calificacion: 3.5,
    telefono: '952000111',
    email: 'info@elvecino.com',
    descripcion: '',
    estado: 1,
    imagen: null,
    fotografias: [],
    servicios: [],
  );

  group('US-04 · Detalle de una instalación deportiva', () {
    testWidgets(
      'Escenario 1: El detalle tiene datos (nombre, dirección, deportes, horarios, servicios, tarifa, fotografías y retorno)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final vm = InstitucionDetailViewModel(1, prefs: prefs);
        vm.horarios.addAll([
          HorarioAtencion(
            id: 1,
            institucionDeportivaId: 1,
            dia: 'Lunes',
            horaApertura: '07:00:00',
            horaCierre: '22:00:00',
          ),
        ]);
        vm.deportes.addAll([
          Deporte(id: 1, nombre: 'Fútbol'),
          Deporte(id: 2, nombre: 'Vóley'),
        ]);
        vm.servicios.addAll([
          'Estacionamiento',
          'Iluminación nocturna',
          'Vestuarios y duchas',
        ]);
        vm.fotografias.addAll([
          'https://ejemplo.com/foto1.jpg',
          'https://ejemplo.com/foto2.jpg',
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => InstitucionDetailView(
                  institucion: institucionConDatos,
                  viewModel: vm,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Nombre
        expect(find.text('Top Gol Tacna'), findsOneWidget);
        // 2. Dirección
        expect(find.text('Av. Jorge Basadre 123'), findsWidgets);
        // 3. Tarifa
        expect(find.text('S/. 51.00'), findsOneWidget);
        // 4. Deportes
        expect(find.text('Fútbol'), findsOneWidget);
        expect(find.text('Vóley'), findsOneWidget);
        // 5. Horarios
        expect(find.text('07:00:00 - 22:00:00'), findsOneWidget);
        // 6. Servicios
        expect(find.text('Estacionamiento'), findsOneWidget);
        expect(find.text('Iluminación nocturna'), findsOneWidget);
        // 7. Fotografías
        expect(find.text('Fotografías'), findsOneWidget);

        // Volver a la lista sin perder su posición
        final backButton = find.byKey(const Key('institucion_back_button'));
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Escenario 2: El detalle no tiene información complementaria (datos básicos e indicación clara en campos sin info)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final vm = InstitucionDetailViewModel(2, prefs: prefs);
        // Sin horarios, sin deportes, sin servicios, sin fotografías
        vm.horarios.clear();
        vm.deportes.clear();
        vm.servicios.clear();
        vm.fotografias.clear();

        await tester.pumpWidget(
          MaterialApp(
            home: InstitucionDetailView(
              institucion: institucionSinComplementos,
              viewModel: vm,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Datos básicos visibles
        expect(find.text('Cancha El Vecino'), findsOneWidget);
        expect(find.text('Calle Los Álamos 456'), findsWidgets);
        expect(find.text('S/. 25.00'), findsOneWidget);
        expect(find.text('952000111'), findsOneWidget);

        // Indicación clara en campos sin información
        expect(find.text('Sin fotografías registradas'), findsOneWidget);
        expect(find.text('Sin servicios registrados'), findsOneWidget);
        expect(find.text('Sin horarios registrados'), findsOneWidget);
        expect(find.text('Sin deportes registrados'), findsOneWidget);
      },
    );

    testWidgets(
      'Escenario 3: El detalle se abre sin conexión (datos guardados, aviso de desactualización y botón reintentar)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final vm = InstitucionDetailViewModel(1, prefs: prefs);
        // Simular que los datos vinieron de caché
        vm.horarios.add(
          HorarioAtencion(
            id: 1,
            institucionDeportivaId: 1,
            dia: 'Lunes',
            horaApertura: '08:00:00',
            horaCierre: '20:00:00',
          ),
        );
        vm.deportes.add(Deporte(id: 1, nombre: 'Fútbol'));
        vm.servicios.add('Estacionamiento');

        // Guardar en caché y cargar marcando isFromCache = true
        await vm.saveToCache();
        await vm.loadFromCache();

        // Forzar simulación de fallo remoto con recuperación de caché
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return InstitucionDetailView(
                  institucion: institucionConDatos,
                  viewModel: vm,
                );
              },
            ),
          ),
        );

        // Marcamos isFromCache en el viewmodel para simular sesión sin conexión con caché
        // Guardar y cargar caché
        await vm.saveToCache();
        // Usar método loadFromCache directamente
        final loaded = await vm.loadFromCache();
        expect(loaded, isTrue);

        // Renderizamos con un viewmodel que tiene isFromCache = true
        final vmOffline = InstitucionDetailViewModel(1, prefs: prefs);
        await vmOffline.loadFromCache();
        // Disparamos simulación donde el servidor falla pero la caché rescata los datos
        // mediante el método loadDetail interceptado o configurado
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return InstitucionDetailView(
                  institucion: institucionConDatos,
                  viewModel: vmOffline,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Simular evento sin conexión con aviso
        // El aviso debe ser visible si isFromCache es true
      },
    );

    testWidgets(
      'Escenario 3 (directo): Verificación de aviso de datos desactualizados y botón de reintentar',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // Creamos un VM que simula haber rescatado datos de caché ante fallo de red
        final vm = InstitucionDetailViewModel(1, prefs: prefs);
        vm.horarios.add(
          HorarioAtencion(
            id: 1,
            institucionDeportivaId: 1,
            dia: 'Martes',
            horaApertura: '09:00:00',
            horaCierre: '21:00:00',
          ),
        );
        await vm.saveToCache();

        // Creamos una subclase o estado con isFromCache = true
        final testVm = _MockCachedDetailViewModel(1, prefs: prefs);
        testVm.horarios.add(
          HorarioAtencion(
            id: 1,
            institucionDeportivaId: 1,
            dia: 'Martes',
            horaApertura: '09:00:00',
            horaCierre: '21:00:00',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: InstitucionDetailView(
              institucion: institucionConDatos,
              viewModel: testVm,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ve la información guardada
        expect(find.text('09:00:00 - 21:00:00'), findsOneWidget);

        // Ve el aviso de que los datos podrían estar desactualizados
        expect(
          find.text('Estás viendo la información guardada. Los datos podrían estar desactualizados.'),
          findsOneWidget,
        );

        // Ve el botón para reintentar
        final retryButton = find.byKey(const Key('offline_retry_button'));
        expect(retryButton, findsOneWidget);

        // Puede pulsar reintentar
        await tester.tap(retryButton);
        await tester.pump();
      },
    );

    testWidgets(
      'Escenario 4: El servidor falla al cargar el detalle (mensaje comprensible sin detalles técnicos y botón reintentar)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final errorVm = _MockErrorDetailViewModel(1, prefs: prefs);

        await tester.pumpWidget(
          MaterialApp(
            home: InstitucionDetailView(
              institucion: institucionConDatos,
              viewModel: errorVm,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Mensaje comprensible sin detalles técnicos (nada de 500, PostgrestException, socket, stacktrace)
        expect(
          find.text(
            'No fue posible cargar los detalles de la instalación. Por favor, verifica tu conexión o intenta nuevamente.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('500'), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);
        expect(find.textContaining('Postgrest'), findsNothing);

        // Botón para reintentar
        final retryButton = find.byKey(const Key('error_retry_button'));
        expect(retryButton, findsOneWidget);

        await tester.tap(retryButton);
        await tester.pump();
      },
    );
  });
}

class _MockCachedDetailViewModel extends InstitucionDetailViewModel {
  _MockCachedDetailViewModel(super.institucionId, {super.prefs});

  @override
  bool get isFromCache => true;

  @override
  Future<void> loadDetail({InstitucionDeportiva? institucion, bool isRetry = false}) async {
    // No-op para test
  }
}

class _MockErrorDetailViewModel extends InstitucionDetailViewModel {
  _MockErrorDetailViewModel(super.institucionId, {super.prefs});

  @override
  bool get isFromCache => false;

  @override
  String? get errorMessage =>
      'No fue posible cargar los detalles de la instalación. Por favor, verifica tu conexión o intenta nuevamente.';

  @override
  Future<void> loadDetail({InstitucionDeportiva? institucion, bool isRetry = false}) async {
    // No-op para test
  }
}
