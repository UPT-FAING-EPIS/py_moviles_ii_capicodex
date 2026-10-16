import 'dart:convert';

import '../models/usuario_deportista.dart';

/// Estado explícito de una lectura de perfil para que la interfaz pueda
/// diferenciar una carga correcta de un JSON rechazado.
class PerfilCargaEstado {
  final UsuarioDeportista? perfil;
  final String? error;

  const PerfilCargaEstado._({this.perfil, this.error});

  factory PerfilCargaEstado.conDatos(UsuarioDeportista perfil) =>
      PerfilCargaEstado._(perfil: perfil);

  factory PerfilCargaEstado.conError(String mensaje) =>
      PerfilCargaEstado._(error: mensaje);

  bool get tieneDatos => perfil != null;
  bool get tieneError => error != null;
}

/// Lector puro: no usa red ni emulador. Recibe JSON crudo y transforma solo
/// las claves conocidas por [UsuarioDeportista].
class PerfilJsonLoader {
  const PerfilJsonLoader();

  PerfilCargaEstado leer(String jsonCrudo) {
    try {
      final decoded = jsonDecode(jsonCrudo);
      if (decoded is! Map<String, dynamic>) {
        return PerfilCargaEstado.conError('El perfil debe ser un objeto JSON');
      }
      return PerfilCargaEstado.conDatos(UsuarioDeportista.fromJson(decoded));
    } on FormatException {
      return PerfilCargaEstado.conError('JSON de perfil inválido');
    } catch (_) {
      return PerfilCargaEstado.conError('No se pudo leer el perfil');
    }
  }

  /// Ejecuta una carga una sola vez. Si el origen falla, retorna error sin
  /// reintentos; así el llamador puede mostrar el estado al usuario.
  Future<PerfilCargaEstado> cargarUnaVez(
    Future<String> Function() obtenerJson,
  ) async {
    try {
      return leer(await obtenerJson());
    } catch (_) {
      return PerfilCargaEstado.conError('Carga de perfil rechazada');
    }
  }
}
