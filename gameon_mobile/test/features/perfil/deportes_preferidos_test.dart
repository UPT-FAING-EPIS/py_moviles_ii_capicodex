import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/core/theme/theme_controller.dart';
import 'package:gameon/features/perfil/models/usuario_deportista.dart';
import 'package:gameon/features/perfil/viewmodels/edit_perfil_viewmodel.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import 'package:gameon/features/perfil/views/perfil_view/authenticated/edit_perfil/edit_perfil_view.dart';
import 'package:gameon/features/perfil/views/perfil_view/authenticated/perfil_authenticated_view.dart';

class FakeEditPerfilViewModel extends EditPerfilViewModel {
  int saveDeportesCalls = 0;
  int upsertPerfilCalls = 0;
  int? lastSavedUsuarioId;
  List<String>? lastSavedDeportes;

  FakeEditPerfilViewModel({List<String> disponibles = const []}) {
    setDeportesDisponiblesForTesting(disponibles);
  }

  @override
  Future<SavePerfilResult> upsertUsuarioDeportista({
    int? id,
    required String username,
    required String nombre,
    required String apellidos,
    required String telefono,
    DateTime? fechaNacimiento,
    required String genero,
    required String nivelHabilidad,
    String? fcmToken,
    String? imagenPerfil,
  }) async {
    upsertPerfilCalls++;
    return SavePerfilResult.success(id ?? 42);
  }

  @override
  Future<List<String>> saveDeportesFavoritos(
    int usuarioId,
    List<String> deportesSeleccionados,
  ) async {
    saveDeportesCalls++;
    lastSavedUsuarioId = usuarioId;
    final normalizados = <String>[];
    for (final raw in deportesSeleccionados) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty && !normalizados.contains(trimmed)) {
        normalizados.add(trimmed);
      }
    }
    lastSavedDeportes = normalizados;
    return normalizados;
  }
}

class FakePerfilViewModel extends ChangeNotifier implements PerfilViewModel {
  @override
  bool isLoggedIn;

  @override
  UsuarioDeportista? profile;

  @override
  bool isLoggingIn = false;

  @override
  bool isSigningUp = false;

  @override
  bool get hasManagerProfile => false;

  @override
  bool get hasAthleteProfile => profile != null;

  @override
  int? get managerId => null;

  @override
  AppUserMode get mode => AppUserMode.deportista;

  int reloadCalls = 0;

  FakePerfilViewModel({
    this.isLoggedIn = true,
    this.profile,
  });

  @override
  void updateDeportesFavoritosLocal(List<String> deportes) {
    if (profile == null) return;
    final normalizados = <String>[];
    for (final raw in deportes) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty && !normalizados.contains(trimmed)) {
        normalizados.add(trimmed);
      }
    }
    profile = profile!.copyWith(
      deportesFavoritos: List<String>.unmodifiable(normalizados),
    );
    notifyListeners();
  }

  @override
  Future<void> reloadProfile() async {
    reloadCalls++;
    notifyListeners();
  }

  @override
  void startHeartbeat({Duration interval = const Duration(seconds: 45)}) {}

  @override
  void stopHeartbeat() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UsuarioDeportista createTestProfile({
  List<String> deportesFavoritos = const ['Fútbol', 'Volleyball'],
}) {
  return UsuarioDeportista(
    id: '42',
    authId: 'auth-42',
    username: 'mayrafc',
    nombre: 'Mayra',
    apellidos: 'Chire',
    telefono: '952111222',
    fechaNacimiento: DateTime(2001, 5, 20),
    genero: 'femenino',
    nivelHabilidad: 'Intermedio',
    estado: 1,
    imagenPerfil: null,
    createdAt: DateTime(2026, 3, 10),
    deportesFavoritos: deportesFavoritos,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('US-18 · Registrar deportes preferidos sin afectar otros datos', () {
    test(
      'saveDeportesFavoritos selecciona y guarda deportes en usuarios_deportes sin tocar usuarios_deportistas',
      () async {
        final requests = <http.Request>[];
        final client = SupabaseClient(
          'https://example.supabase.co',
          'public-anon-key',
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/rest/v1/deportes' &&
                request.method == 'GET') {
              return http.Response(
                jsonEncode([
                  {'id': 1, 'nombre': 'Fútbol'},
                  {'id': 3, 'nombre': 'Tenis'},
                ]),
                200,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            if (request.url.path == '/rest/v1/usuarios_deportes' &&
                request.method == 'DELETE') {
              expect(request.url.queryParameters['usuario_id'], 'eq.42');
              return http.Response(
                '[]',
                200,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            if (request.url.path == '/rest/v1/usuarios_deportes' &&
                request.method == 'POST') {
              expect(jsonDecode(request.body), [
                {'usuario_id': 42, 'deporte_id': 1},
                {'usuario_id': 42, 'deporte_id': 3},
              ]);
              return http.Response(
                '[]',
                201,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            fail('Ruta inesperada: ${request.method} ${request.url.path}');
          }),
        );

        final vm = EditPerfilViewModel(supabaseClient: client);
        final guardados = await vm.saveDeportesFavoritos(
          42,
          [' Fútbol ', 'Tenis', 'Fútbol'],
        );

        expect(guardados, ['Fútbol', 'Tenis']);
        expect(
          requests.map((r) => '${r.method} ${r.url.path}').toList(),
          [
            'GET /rest/v1/deportes',
            'DELETE /rest/v1/usuarios_deportes',
            'POST /rest/v1/usuarios_deportes',
          ],
        );
        expect(
          requests.any((r) => r.url.path.contains('usuarios_deportistas')),
          isFalse,
        );
        await client.dispose();
      },
    );

    test(
      'saveDeportesFavoritos permite eliminar todos los deportes sin insertar ni afectar otros datos',
      () async {
        final requests = <http.Request>[];
        final client = SupabaseClient(
          'https://example.supabase.co',
          'public-anon-key',
          httpClient: MockClient((request) async {
            requests.add(request);
            expect(request.url.path, '/rest/v1/usuarios_deportes');
            expect(request.method, 'DELETE');
            expect(request.url.queryParameters['usuario_id'], 'eq.42');
            return http.Response(
              '[]',
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }),
        );

        final vm = EditPerfilViewModel(supabaseClient: client);
        final guardados = await vm.saveDeportesFavoritos(42, []);

        expect(guardados, isEmpty);
        expect(requests, hasLength(1));
        expect(requests.single.method, 'DELETE');
        await client.dispose();
      },
    );

    test(
      'si falla la consulta del catálogo de deportes no elimina los deportes previos del usuario',
      () async {
        final requests = <http.Request>[];
        final client = SupabaseClient(
          'https://example.supabase.co',
          'public-anon-key',
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response(
              '{"message":"server error"}',
              500,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }),
        );

        final vm = EditPerfilViewModel(supabaseClient: client);
        await expectLater(
          vm.saveDeportesFavoritos(42, ['Fútbol']),
          throwsException,
        );

        expect(
          requests.any(
            (r) =>
                r.url.path == '/rest/v1/usuarios_deportes' &&
                r.method == 'DELETE',
          ),
          isFalse,
        );
        await client.dispose();
      },
    );

    test(
      'copyWith y updateDeportesFavoritosLocal actualizan deportes conservando intactos los demás datos personales',
      () {
        final original = createTestProfile(
          deportesFavoritos: ['Fútbol', 'Volleyball'],
        );
        final perfilVm = FakePerfilViewModel(profile: original);

        perfilVm.updateDeportesFavoritosLocal(['Tenis', 'Natación']);

        final actualizado = perfilVm.profile!;
        expect(actualizado.deportesFavoritos, ['Tenis', 'Natación']);
        expect(actualizado.id, original.id);
        expect(actualizado.authId, original.authId);
        expect(actualizado.username, original.username);
        expect(actualizado.nombre, original.nombre);
        expect(actualizado.apellidos, original.apellidos);
        expect(actualizado.telefono, original.telefono);
        expect(actualizado.fechaNacimiento, original.fechaNacimiento);
        expect(actualizado.genero, original.genero);
        expect(actualizado.nivelHabilidad, original.nivelHabilidad);
        expect(actualizado.estado, original.estado);
        expect(actualizado.createdAt, original.createdAt);
      },
    );

    testWidgets(
      'EditPerfilView permite seleccionar, eliminar y guardar deportes sin modificar otros datos del perfil',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final initialProfile = createTestProfile(
          deportesFavoritos: ['Fútbol', 'Volleyball'],
        );
        final perfilVm = FakePerfilViewModel(profile: initialProfile);
        final editVm = FakeEditPerfilViewModel(
          disponibles: const [
            'Fútbol',
            'Basketball',
            'Tenis',
            'Volleyball',
          ],
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeController>.value(
                value: ThemeController(),
              ),
              ChangeNotifierProvider<PerfilViewModel>.value(value: perfilVm),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('es', 'ES')],
              home: EditPerfilView(
                profile: initialProfile,
                viewModel: editVm,
                autoLoadDeportes: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verificar deportes iniciales mostrados
        expect(find.text('2 deportes seleccionados'), findsOneWidget);
        expect(find.text('Fútbol'), findsOneWidget);
        expect(find.text('Volleyball'), findsOneWidget);

        // 1. Eliminar 'Volleyball' desde el chip en la tarjeta
        final closeIcons = find.byIcon(Icons.close);
        expect(closeIcons, findsNWidgets(2));
        await tester.ensureVisible(closeIcons.last);
        await tester.tap(closeIcons.last);
        await tester.pumpAndSettle();

        expect(find.text('1 deportes seleccionados'), findsOneWidget);
        expect(find.text('Volleyball'), findsNothing);

        // 2. Abrir el selector de deportes y seleccionar 'Tenis'
        await tester.ensureVisible(find.text('Mis deportes'));
        await tester.tap(find.text('Mis deportes'));
        await tester.pumpAndSettle();

        expect(find.text('Selecciona tus deportes'), findsOneWidget);
        await tester.tap(find.text('Tenis'));
        await tester.pumpAndSettle();

        expect(find.text('Confirmar (2 seleccionados)'), findsOneWidget);
        await tester.tap(find.text('Confirmar (2 seleccionados)'));
        await tester.pumpAndSettle();

        expect(find.text('2 deportes seleccionados'), findsOneWidget);
        expect(find.text('Fútbol'), findsOneWidget);
        expect(find.text('Tenis'), findsOneWidget);

        // 3. Guardar cambios y verificar que no se alteraron los demás datos personales
        await tester.ensureVisible(find.text('Guardar Cambios'));
        await tester.tap(find.text('Guardar Cambios'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(editVm.upsertPerfilCalls, 0);
        expect(editVm.saveDeportesCalls, 1);
        expect(editVm.lastSavedUsuarioId, 42);
        expect(editVm.lastSavedDeportes, ['Fútbol', 'Tenis']);
        expect(perfilVm.profile!.deportesFavoritos, ['Fútbol', 'Tenis']);
        expect(perfilVm.profile!.nombre, 'Mayra');
        expect(perfilVm.profile!.apellidos, 'Chire');
        expect(perfilVm.profile!.username, 'mayrafc');
        expect(perfilVm.profile!.telefono, '952111222');
        expect(perfilVm.profile!.genero, 'femenino');
        expect(perfilVm.profile!.nivelHabilidad, 'Intermedio');
      },
    );

    testWidgets(
      'PerfilAuthenticatedView permite gestionar deportes directamente desde el perfil conservando datos personales',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final initialProfile = createTestProfile(deportesFavoritos: ['Fútbol']);
        final perfilVm = FakePerfilViewModel(profile: initialProfile);
        final editVm = FakeEditPerfilViewModel(
          disponibles: const ['Fútbol', 'Basketball', 'Tenis'],
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeController>.value(
                value: ThemeController(),
              ),
              ChangeNotifierProvider<PerfilViewModel>.value(value: perfilVm),
            ],
            child: MaterialApp(
              home: Consumer<PerfilViewModel>(
                builder: (context, vm, _) => PerfilAuthenticatedView(
                  profile: vm.profile!,
                  onLogout: () async {},
                  editPerfilViewModel: editVm,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mis Deportes'), findsOneWidget);
        expect(find.text('Gestionar'), findsOneWidget);
        expect(find.text('Mayra Chire'), findsWidgets);
        expect(find.text('@mayrafc'), findsOneWidget);

        await tester.ensureVisible(find.text('Gestionar'));
        await tester.tap(find.text('Gestionar'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Basketball'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmar (2 seleccionados)'));
        await tester.pumpAndSettle();

        expect(editVm.upsertPerfilCalls, 0);
        expect(editVm.saveDeportesCalls, 1);
        expect(
          perfilVm.profile!.deportesFavoritos,
          ['Fútbol', 'Basketball'],
        );
        expect(find.text('Basketball'), findsOneWidget);
        expect(find.text('Mayra Chire'), findsWidgets);
        expect(find.text('@mayrafc'), findsOneWidget);
        expect(find.text('952111222'), findsOneWidget);
      },
    );
  });
}
