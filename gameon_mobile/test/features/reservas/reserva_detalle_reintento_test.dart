import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/perfil/models/usuario_deportista.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import 'package:gameon/features/reservas/models/reserva.dart';
import 'package:gameon/features/reservas/viewmodels/reservas_list_viewmodel.dart';
import 'package:gameon/features/reservas/views/reservas_list/reserva_detail_view.dart';
import 'package:provider/provider.dart';

typedef ReservaDetails = ({
  Reserva reserva,
  AreaLite area,
  InstitucionLite institucion,
});

class FakePerfilViewModel extends ChangeNotifier implements PerfilViewModel {
  @override
  bool isLoggedIn = true;

  @override
  UsuarioDeportista? profile = UsuarioDeportista(
    id: '42',
    authId: 'auth-42',
    username: 'luz',
    nombre: 'Luz',
    apellidos: 'Gutiérrez',
    telefono: '',
    fechaNacimiento: null,
    genero: 'femenino',
    nivelHabilidad: 'Principiante',
    estado: 1,
    createdAt: DateTime(2026, 1, 1),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReservaDetailsViewModel extends ReservasListViewModel {
  final requests = <int>[];
  final attempts = <Completer<ReservaDetails?>>[];

  @override
  Future<ReservaDetails?> getReservaWithDetails(
    int id, {
    required int idUsuario,
  }) {
    requests.add(idUsuario);
    final attempt = Completer<ReservaDetails?>();
    attempts.add(attempt);
    return attempt.future;
  }
}

ReservaDetails testDetails() => (
  reserva: Reserva(
    id: 100,
    idUsuario: 42,
    areaDeportivaId: 1,
    fecha: DateTime(2026, 11, 20),
    horaInicio: '18:00:00',
    horaFin: '19:00:00',
    estado: 'Confirmada',
    creadoEn: DateTime(2026, 11, 1),
  ),
  area: AreaLite(id: 1, nombre: 'Cancha', institucionId: 2, tarifaPorHora: 20),
  institucion: InstitucionLite(id: 2, nombre: 'Complejo', direccion: 'Tacna'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> showDetail(
    WidgetTester tester,
    FakeReservaDetailsViewModel vm,
    FakePerfilViewModel perfil,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<PerfilViewModel>.value(
        value: perfil,
        child: MaterialApp(
          home: ReservaDetailView.fromId(reservaId: 100, viewModel: vm),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('reintenta tras un fallo y muestra el detalle si responde', (
    tester,
  ) async {
    final vm = FakeReservaDetailsViewModel();
    final perfil = FakePerfilViewModel();
    await showDetail(tester, vm, perfil);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(vm.requests, [42]);

    vm.attempts.first.completeError(StateError('token-secreto-123'));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('No se pudo cargar el detalle'), findsOneWidget);
    expect(find.textContaining('token-secreto-123'), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
    expect(vm.requests, [42, 42]);

    vm.attempts.last.complete(testDetails());
    await tester.pumpAndSettle();
    expect(find.text('Detalle #100'), findsOneWidget);
    expect(find.text('N.º de reserva: 100'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('mantiene Reintentar si la nueva consulta vuelve a fallar', (
    tester,
  ) async {
    final vm = FakeReservaDetailsViewModel();
    await showDetail(tester, vm, FakePerfilViewModel());

    vm.attempts.first.completeError(Exception('fallo de red'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    vm.attempts.last.completeError(Exception('otro fallo'));
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('otro fallo'), findsNothing);
    expect(vm.requests, [42, 42]);
  });

  testWidgets('no muestra el detalle si cambia la cuenta durante la carga', (
    tester,
  ) async {
    final vm = FakeReservaDetailsViewModel();
    final perfil = FakePerfilViewModel();
    await showDetail(tester, vm, perfil);

    perfil.profile = null;
    perfil.isLoggedIn = false;
    perfil.notifyListeners();
    vm.attempts.first.complete(testDetails());
    await tester.pumpAndSettle();

    expect(find.text('Detalle #100'), findsNothing);
    expect(find.text('N.º de reserva: 100'), findsNothing);
    expect(find.text('Inicia sesión para consultar esta reserva'), findsOneWidget);
  });
}
