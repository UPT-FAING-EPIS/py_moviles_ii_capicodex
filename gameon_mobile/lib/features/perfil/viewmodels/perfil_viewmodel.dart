import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_deportista.dart';
import 'package:gameon/features/chat/services/user_sync_service.dart';
import 'package:gameon/core/services/notification_service.dart';

class PerfilViewModel extends ChangeNotifier {
  // Form keys could be kept in the view, but we manage simple flags here.
  bool _isSigningUp = false;
  bool get isSigningUp => _isSigningUp;

  bool _isLoggingIn = false;
  bool get isLoggingIn => _isLoggingIn;

  UsuarioDeportista? _profile;
  UsuarioDeportista? get profile => _profile;
  bool get isLoggedIn => supabase.auth.currentSession != null;

  final UserSyncService _userSyncService = UserSyncService();
  final NotificationService? _notificationService;
  Timer? _heartbeatTimer;
  StreamSubscription<String>? _tokenRefreshSubscription;

  PerfilViewModel([this._notificationService]) {
    // Escucha cambios de autenticación para cargar / limpiar perfil
    supabase.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      switch (event.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          if (session?.user != null) {
            _loadProfile();
            _registerFcmToken();
            _userSyncService.setPresence(
              userId: session!.user.id,
              isOnline: true,
            );
            startHeartbeat();
          }
          break;
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.userDeleted:
          stopHeartbeat();
          _profile = null;
          notifyListeners();
          break;
        default:
          if (session?.user == null) {
            stopHeartbeat();
            _profile = null;
            notifyListeners();
          }
      }
    });
    // Si ya hay sesión al crear el VM (hot reload), cargar perfil.
    if (supabase.auth.currentSession?.user != null) {
      _loadProfile();
      _registerFcmToken();
    }
    // Escuchar rotación del token y actualizar en Supabase
    _tokenRefreshSubscription = _notificationService?.onTokenRefresh.listen((
      token,
    ) {
      _registerFcmToken(token);
    });
  }

  final supabase = Supabase.instance.client;

  Future<SignupResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_isSigningUp) return SignupResult.busy();
    _isSigningUp = true;
    notifyListeners();

    try {
      final authResponse = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {'full_name': fullName.trim()},
      );

      final user = authResponse.user;
      developer.log(
        'VM signUp user: ${user?.id} session: ${authResponse.session != null}',
      );
      if (user == null) {
        return SignupResult.error(
          'No se pudo crear el usuario (flujo pendiente).',
        );
      }
      final session = supabase.auth.currentSession;
      developer.log('session null? ${session == null}');
      developer.log('access token length: ${session?.accessToken.length}');
      developer.log('user id: ${session?.user.id}');

      final parts = fullName
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      final nombre = parts.isNotEmpty ? parts.first : 'Usuario';
      final apellidos = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      // Obtener FCM token
      final fcmToken = await _notificationService?.getToken();
      developer.log(
        'VM FCM token obtenido en signup: ${fcmToken?.substring(0, (fcmToken?.length ?? 0) > 6 ? 6 : (fcmToken?.length ?? 0))}...',
      );

      final insertPayload = {
        'nombre': nombre,
        'apellidos': apellidos,
        'genero': 'otro',
        'nivel_habilidad': 'Principiante',
        'auth_id': user.id,
        'fcm_token': fcmToken,
      };
      developer.log('VM insert usuarios_deportistas => $insertPayload');
      try {
        await supabase.from('usuarios_deportistas').insert(insertPayload);
      } on PostgrestException catch (e) {
        developer.log('VM PostgrestException insert: ${e.message}', error: e);
        if (e.message.toLowerCase().contains('permission') ||
            e.code == '42501') {
          return SignupResult.error(
            'Permisos insuficientes para crear perfil (verifica sesión).',
          );
        }
        return SignupResult.error('Error BD: ${e.message}');
      }

      // Pequeño delay para asegurar que la base de datos procese la inserción
      await Future.delayed(const Duration(milliseconds: 500));

      // Tras crear el registro en usuarios_deportistas cargamos perfil.
      await _loadProfile();

      // Verificar que el perfil se haya cargado correctamente
      if (_profile == null) {
        developer.log('VM signup: perfil no se cargó después de crear usuario');
        return SignupResult.error(
          'Error al cargar perfil después de crear cuenta',
        );
      }

      return SignupResult.success();
    } on AuthException catch (e) {
      developer.log('VM AuthException: ${e.message}', error: e);
      return SignupResult.error(e.message);
    } catch (e, st) {
      developer.log('VM Error genérico signup: $e', error: e, stackTrace: st);
      return SignupResult.error('Error inesperado');
    } finally {
      _isSigningUp = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile({int maxRetries = 3}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        developer.log(
          'VM _loadProfile: intento ${attempt + 1}/$maxRetries para auth_id=${user.id}',
        );
        final data = await supabase
            .from('usuarios_deportistas')
            .select()
            .eq('auth_id', user.id)
            .maybeSingle();
        if (data != null) {
          // Cargar deportes favoritos del usuario
          final usuarioId = int.tryParse(data['id'].toString());
          if (usuarioId != null) {
            try {
              final deportesData = await supabase
                  .from('usuarios_deportes')
                  .select('deportes(nombre)')
                  .eq('usuario_id', usuarioId);

              final deportes = deportesData
                  .map((e) => e['deportes']?['nombre']?.toString() ?? '')
                  .where((n) => n.isNotEmpty)
                  .toList();

              data['deportes_favoritos'] = deportes;
            } catch (e) {
              developer.log('VM _loadProfile: error al cargar deportes: $e');
              data['deportes_favoritos'] = <String>[];
            }
          }

          _profile = UsuarioDeportista.fromJson(data);
          developer.log(
            'VM _loadProfile: perfil cargado exitosamente ${_profile!.nombreCompleto}',
          );
          // Sincronizar usuario a Firebase tras cargar perfil
          await _userSyncService.syncCurrentUser();
          notifyListeners();
          return; // Éxito, salir del bucle
        } else {
          developer.log(
            'VM _loadProfile: sin registro en usuarios_deportistas en intento ${attempt + 1}',
          );
          if (attempt < maxRetries - 1) {
            await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
            attempt++;
            continue;
          }
        }
      } on PostgrestException catch (e) {
        developer.log(
          'VM _loadProfile PostgrestException intento ${attempt + 1}: ${e.message}',
          error: e,
        );
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          attempt++;
          continue;
        }
      } catch (e, st) {
        developer.log(
          'VM _loadProfile error genérico intento ${attempt + 1}: $e',
          error: e,
          stackTrace: st,
        );
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          attempt++;
          continue;
        }
      }
      break;
    }
  }

  /// Método público para recargar el perfil desde la base de datos
  Future<void> reloadProfile() async {
    await _loadProfile();
  }

  Future<void> signOut() async {
    stopHeartbeat();
    _tokenRefreshSubscription?.cancel();
    await supabase.auth.signOut();
    _profile = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  Future<void> setCurrentUserPresence(bool isOnline) async {
    await _userSyncService.setCurrentUserPresence(isOnline);
  }

  void startHeartbeat({Duration interval = const Duration(seconds: 45)}) {
    _heartbeatTimer?.cancel();
    final user = supabase.auth.currentUser;
    if (user == null) return;
    _userSyncService.updateCurrentUserLastSeen();
    _heartbeatTimer = Timer.periodic(interval, (_) {
      _userSyncService.updateCurrentUserLastSeen();
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    if (_isLoggingIn) return LoginResult.busy();
    _isLoggingIn = true;
    notifyListeners();
    try {
      final resp = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (resp.session == null) {
        return LoginResult.error('Credenciales inválidas');
      }
      await _loadProfile();
      // Actualizar FCM token tras iniciar sesión
      await _registerFcmToken();
      await _userSyncService.setCurrentUserPresence(true);
      return LoginResult.success();
    } on AuthException catch (e) {
      developer.log('VM login AuthException: ${e.message}', error: e);
      return LoginResult.error(_mapAuthError(e.message));
    } catch (e, st) {
      developer.log('VM login error genérico: $e', error: e, stackTrace: st);
      return LoginResult.error('Error inesperado');
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  // Registrar/actualizar token FCM en Supabase para el usuario autenticado
  Future<void> _registerFcmToken([String? token]) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      if (_notificationService == null) {
        developer.log('VM FCM: NotificationService no disponible');
        return;
      }

      final t = token ?? await _notificationService?.getToken();
      if (t == null || t.isEmpty) return;

      await supabase
          .from('usuarios_deportistas')
          .update({'fcm_token': t})
          .eq('auth_id', user.id);
    } on PostgrestException catch (e) {
      developer.log('VM FCM PostgrestException: ${e.message}', error: e);
    } catch (e, st) {
      developer.log('VM FCM error genérico: $e', error: e, stackTrace: st);
    }
  }

  String _mapAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials'))
      return 'Correo o contraseña incorrectos';
    if (m.contains('email not confirmed')) return 'Debes confirmar tu correo';
    return message;
  }
}

class SignupResult {
  final bool ok;
  final String? message;
  final bool isBusy;
  SignupResult._(this.ok, this.message, this.isBusy);
  factory SignupResult.success() => SignupResult._(true, null, false);
  factory SignupResult.error(String msg) => SignupResult._(false, msg, false);
  factory SignupResult.busy() =>
      SignupResult._(false, 'Operación en curso', true);
}

class LoginResult {
  final bool ok;
  final String? message;
  final bool isBusy;
  LoginResult._(this.ok, this.message, this.isBusy);
  factory LoginResult.success() => LoginResult._(true, null, false);
  factory LoginResult.error(String msg) => LoginResult._(false, msg, false);
  factory LoginResult.busy() =>
      LoginResult._(false, 'Operación en curso', true);
}
