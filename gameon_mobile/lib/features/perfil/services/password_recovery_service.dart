import 'dart:convert';
import 'package:http/http.dart' as http;

class RecoveryException implements Exception {
  final String message;
  const RecoveryException(this.message);
}

/// Usa los endpoints de Supabase Auth sin instalar la sesión de recuperación
/// en la app. El token temporal solo vive durante confirmarCambio.
class PasswordRecoveryService {
  final String supabaseUrl;
  final String anonKey;
  final http.Client _http;
  PasswordRecoveryService({
    required this.supabaseUrl,
    required this.anonKey,
    http.Client? client,
  }) : _http = client ?? http.Client();

  static const mensajeEnvio =
      'Si el correo está registrado, recibirás un código para recuperar tu acceso.';

  Map<String, String> get _headers => {
    'apikey': anonKey,
    'Content-Type': 'application/json',
  };
  Uri _url(String path) => Uri.parse('$supabaseUrl/auth/v1/$path');

  Future<void> solicitarCodigo(String email) async {
    try {
      final response = await _http
          .post(
            _url('recover'),
            headers: _headers,
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 429) {
        throw const RecoveryException(
          'Espera unos minutos antes de solicitar otro código.',
        );
      }
      // No mostrar diferencias entre cuentas existentes y no existentes.
      if (response.statusCode >= 500 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        throw const RecoveryException(
          'No se pudo enviar la solicitud. Inténtalo nuevamente.',
        );
      }
      if (response.statusCode >= 200 && response.statusCode < 300 ||
          response.statusCode == 400 ||
          response.statusCode == 404 ||
          response.statusCode == 422) {
        return;
      }
      throw const RecoveryException(
        'No se pudo enviar la solicitud. Inténtalo nuevamente.',
      );
    } on RecoveryException {
      rethrow;
    } catch (_) {
      throw const RecoveryException(
        'No se pudo conectar. Revisa tu conexión e inténtalo nuevamente.',
      );
    }
  }

  Future<void> confirmarCambio({
    required String email,
    required String codigo,
    required String password,
  }) async {
    String? accessToken;
    try {
      final verification = await _http
          .post(
            _url('verify'),
            headers: _headers,
            body: jsonEncode({
              'email': email.trim(),
              'token': codigo.trim(),
              'type': 'recovery',
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (verification.statusCode < 200 || verification.statusCode >= 300) {
        throw const RecoveryException(
          'Código inválido o vencido. Solicita uno nuevo.',
        );
      }
      final data = jsonDecode(verification.body) as Map<String, dynamic>;
      accessToken = data['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw const RecoveryException(
          'No se pudo verificar el código. Solicita uno nuevo.',
        );
      }
      final response = await _http
          .put(
            _url('user'),
            headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
            body: jsonEncode({'password': password}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const RecoveryException(
          'No se pudo cambiar la contraseña. Revisa sus requisitos y solicita un código nuevo.',
        );
      }
    } on RecoveryException {
      rethrow;
    } catch (_) {
      throw const RecoveryException(
        'No se pudo confirmar el cambio. Intenta iniciar sesión; si no funciona, solicita un código nuevo.',
      );
    } finally {
      if (accessToken != null) {
        try {
          await _http
              .post(
                _url('logout?scope=local'),
                headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
              )
              .timeout(const Duration(seconds: 10));
        } catch (_) {
          /* Sin persistencia local del token; no ocultar el resultado del cambio. */
        }
      }
    }
  }

  void dispose() => _http.close();
}
