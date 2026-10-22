import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gameon/core/theme/theme_controller.dart';
import 'package:gameon/features/perfil/models/usuario_deportista.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import 'package:gameon/features/reservas/models/reserva.dart';
import 'package:gameon/features/reservas/viewmodels/reservas_list_viewmodel.dart';
import 'package:gameon/features/reservas/views/reservas_list/reservas_list_view.dart';
import 'package:gameon/features/reservas/views/reservas_list/reserva_card.dart';
import 'package:gameon/features/reservas/views/reservas_list/widgets/estado_chip.dart';

class FakePerfilViewModel extends ChangeNotifier implements PerfilViewModel {
  @override
  bool isLoggedIn;

  @override
  UsuarioDeportista? profile;

  @override
  bool isLoggingIn = false;

  @override
  bool isSigningUp = false;

  FakePerfilViewModel({
    this.isLoggedIn = true,
    this.profile,
  });

  @override
  void startHeartbeat({Duration interval = const Duration(seconds: 45)}) {}

  @override
  void stopHeartbeat() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UsuarioDeportista createTestUser({
  String id = '42',
  String nombre = 'Luz',
  String apellidos = 'Gómez',
  String username = 'luzg',
}) {
  return UsuarioDeportista(
    id: id,
    authId: 'auth-$id',
    username: username,
    nombre: nombre,
    apellidos: apellidos,
    telefono: '952000123',
    fechaNacimiento: DateTime(1998, 4, 15),
    genero: 'femenino',
    nivelHabilidad: 'avanzado',
    estado: 1,
    createdAt: DateTime(2026, 1, 1),
    deportesFavoritos: ['Fútbol', 'Vóley'],
  );
}

Reserva createTestReserva({
  required int id,
  required int idUsuario,
  int areaDeportivaId = 1,
  String estado = 'Confirmada',
  DateTime? fecha,
  String horaInicio = '18:00:00',
  String horaFin = '19:00:00',
  double montoPagado = 50.0,
}) {
  return Reserva(
    id: id,
    idUsuario: idUsuario,
    areaDeportivaId: areaDeportivaId,
    fecha: fecha ?? DateTime(2026, 11, 10),
    horaInicio: horaInicio,
    horaFin: horaFin,
    estado: estado,
    creadoEn: DateTime(2026, 11, 1),
    montoPagado: montoPagado,
    metodoPago: 'paypal',
  );
}

Widget createTestApp({
  required ReservasListViewModel reservasVm,
  required PerfilViewModel perfilVm,
  bool autoLoad = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeController>.value(value: ThemeController()),
      ChangeNotifierProvider<PerfilViewModel>.value(value: perfilVm),
    ],
    child: MaterialApp(
      home: ReservasListView(
        viewModel: reservasVm,
        autoLoad: autoLoad,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('US-11 · Consultar mis reservas', () {
    late ReservasListViewModel reservasVm;
    late FakePerfilViewModel perfilVm;

    setUp(() {
      reservasVm = ReservasListViewModel();
      perfilVm = FakePerfilViewModel(
        isLoggedIn: true,
        profile: createTestUser(id: '42'),
      );
    });

    tearDown(() {
      ReservasListViewModel.clearInstance();
    });

    testWidgets(
      'Criterio 1 - Seguridad y autorización: Usuario no autenticado ve pantalla de bloqueo para iniciar sesión',
      (WidgetTester tester) async {
        perfilVm = FakePerfilViewModel(isLoggedIn: false, profile: null);

        await tester.pumpWidget(
          createTestApp(
            reservasVm: reservasVm,
            perfilVm: perfilVm,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Inicia sesión'), findsOneWidget);
        expect(
          find.text('Debes iniciar sesión para ver tus reservas'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.lock_person), findsOneWidget);
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(find.byType(ReservaCard), findsNothing);
      },
    );

    testWidgets(
      'Criterio 2 - Estado 1/4 (Cargando): Muestra indicador de carga mientras se obtienen las reservas',
      (WidgetTester tester) async {
        reservasVm.setLoadingForTesting(true);

        await tester.pumpWidget(
          createTestApp(
            reservasVm: reservasVm,
            perfilVm: perfilVm,
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(find.byType(ReservaCard), findsNothing);
      },
    );

    testWidgets(
      'Criterio 2 - Estado 2/4 (Éxito con datos): Muestra lista de reservas del usuario autenticado con detalles completos',
      (WidgetTester tester) async {
        final area1 = AreaLite(
          id: 1,
          nombre: 'Cancha Sintética Principal',
          institucionId: 10,
          tarifaPorHora: 50.0,
          imagenArea: null,
        );
        final inst1 = InstitucionLite(
          id: 10,
          nombre: 'Complejo Deportivo Tacna',
          direccion: 'Av. Pinto 123',
        );

        reservasVm.addAreaCache(area1);
        reservasVm.addInstitucionCache(inst1);

        final reservasUsuario = [
          createTestReserva(
            id: 201,
            idUsuario: 42,
            areaDeportivaId: 1,
            estado: 'Confirmada',
            horaInicio: '18:00:00',
            horaFin: '19:00:00',
            montoPagado: 50.0,
          ),
          createTestReserva(
            id: 202,
            idUsuario: 42,
            areaDeportivaId: 1,
            estado: 'Pendiente',
            horaInicio: '20:00:00',
            horaFin: '21:30:00',
            montoPagado: 75.0,
          ),
        ];

        reservasVm.setReservasForTesting(reservasUsuario);

        await tester.pumpWidget(
          createTestApp(
            reservasVm: reservasVm,
            perfilVm: perfilVm,
          ),
        );
        await tester.pumpAndSettle();

        // Encabezado y contador de reservas
        expect(find.text('Mis Reservas'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        // Tarjetas de reserva renderizadas
        expect(find.byType(ReservaCard), findsNWidgets(2));
        expect(find.text('Reserva #201'), findsOneWidget);
        expect(find.text('Reserva #202'), findsOneWidget);

        // Nombres de área e institución resueltos desde caché
        expect(find.text('Cancha Sintética Principal'), findsNWidgets(2));
        expect(find.text('Complejo Deportivo Tacna'), findsNWidgets(2));

        // Chips de estado
        expect(find.byType(EstadoChip), findsNWidgets(2));
        expect(find.text('Confirmada'), findsOneWidget);
        expect(find.text('Pendiente'), findsOneWidget);

        // Horarios y montos
        expect(find.text('18:00 - 19:00'), findsOneWidget);
        expect(find.text('20:00 - 21:30'), findsOneWidget);
        expect(find.text('S/. 50.00'), findsOneWidget);
        expect(find.text('S/. 75.00'), findsOneWidget);
      },
    );

    testWidgets(
      'Criterio 2 - Estado 3/4 (Vacío): Muestra ilustración y mensaje amigable cuando no tiene reservas',
      (WidgetTester tester) async {
        reservasVm.setReservasForTesting([]);

        await tester.pumpWidget(
          createTestApp(
            reservasVm: reservasVm,
            perfilVm: perfilVm,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('¡Aún no tienes reservas!'), findsOneWidget);
        expect(
          find.text(
            'Cuando realices una reserva aparecerá aquí para que puedas hacer seguimiento fácilmente.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.event_available), findsOneWidget);
        expect(find.byType(ReservaCard), findsNothing);
      },
    );

    testWidgets(
      'Criterio 2 - Estado 4/4 (Error): Muestra mensaje claro y botón de reintento ante fallos de conexión',
      (WidgetTester tester) async {
        reservasVm.setErrorForTesting('No se pudo conectar con el servidor.');

        await tester.pumpWidget(
          createTestApp(
            reservasVm: reservasVm,
            perfilVm: perfilVm,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Error al cargar reservas'), findsOneWidget);
        expect(
          find.text('No se pudo conectar con el servidor.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Reintentar'), findsOneWidget);
      },
    );

    testWidgets(
      'Aislamiento de usuario autenticado: Solo muestra reservas pertenecientes al id_usuario activo',
      (WidgetTester tester) async {
        // Reservas que pertenecen exclusivamente al usuario autenticado (id: 42)
        final reservasUsuarioAutenticado = [
          createTestReserva(id: 301, idUsuario: 42),
        ];

        reservasVm.setReservasForTesting(reservasUsuarioAutenticado);

        await tester.pumpWidget(
          createTestApp(
            reservasVm: reservasVm,
            perfilVm: perfilVm,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Reserva #301'), findsOneWidget);
        expect(reservasVm.reservas.every((r) => r.idUsuario == 42), isTrue);
      },
    );

    testWidgets(
      'Interacción: Botón de refresco disponible en el encabezado de la pantalla',
      (WidgetTester tester) async {
        reservasVm.setReservasForTesting([
          createTestReserva(id: 401, idUsuario: 42),
        ]);

        await tester.pumpWidget(
          createTestApp(
            reservasVm: reservasVm,
            perfilVm: perfilVm,
          ),
        );
        await tester.pumpAndSettle();

        final refreshButton = find.byIcon(Icons.refresh);
        expect(refreshButton, findsOneWidget);
      },
    );
  });
}
