import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../domain/entities/institucion_deportiva.dart';
import '../domain/usecases/obtener_instituciones_activas.dart';
import '../presentation/states/ui_state.dart';

/// ViewModel de la funcionalidad vertical "Visualizar instalaciones deportivas".
///
/// Solo depende del contrato de dominio [InstitucionesRepository], por lo que puede
/// probarse sin emulador, sin widgets y sin una conexión real a Supabase.
class HomeViewModel extends ChangeNotifier {
  final ObtenerInstitucionesActivas obtenerInstitucionesActivas;

  UiState<List<InstitucionDeportiva>> _estado = const Loading();
  UiState<List<InstitucionDeportiva>> get estado => _estado;

  HomeViewModel({required this.obtenerInstitucionesActivas});

  Future<void> cargar() async {
    _estado = const Loading();
    notifyListeners();

    try {
      final instituciones = await obtenerInstitucionesActivas();
      _estado = instituciones.isEmpty
          ? const Empty()
          : Success<List<InstitucionDeportiva>>(instituciones);
    } catch (e, st) {
      developer.log(
        'Error al cargar instalaciones deportivas',
        name: 'HomeViewModel',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      _estado = ErrorState<List<InstitucionDeportiva>>(
        'No pudimos cargar las instalaciones. Verifica tu conexión e inténtalo nuevamente.',
        cargar,
      );
    }
    notifyListeners();
  }
}
