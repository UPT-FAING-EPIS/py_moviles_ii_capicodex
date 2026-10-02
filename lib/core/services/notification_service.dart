import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_navigation_service.dart';

/// Handler para mensajes de Firebase cuando la app está en background o cerrada
/// Debe ser una función top-level (fuera de clases) con @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Mensaje en background: ${message.notification?.title}');
}

/// Servicio encargado de gestionar las notificaciones push de Firebase
///
/// Este servicio maneja:
/// - Inicialización de Firebase Messaging
/// - Configuración de permisos
/// - Listeners de mensajes (foreground, background, opened)
/// - Integración con el servicio de navegación
class NotificationService {
  final NotificationNavigationService _navigationService;

  NotificationService(this._navigationService);

  // ==========================================================================
  // INICIALIZACIÓN
  // ==========================================================================

  /// Inicializa el servicio de notificaciones
  ///
  /// Debe llamarse en main() antes de runApp()
  Future<void> initialize() async {
    await _requestPermissions();
    await updateNotificationPreferences();
    await _configureForegroundNotifications();
    _registerBackgroundHandler();
    _setupListeners();
  }

  // ==========================================================================
  // CONFIGURACIÓN
  // ==========================================================================

  /// Solicita permisos de notificaciones al usuario
  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission();
    debugPrint('[NotificationService] Permisos solicitados');
  }

  /// Actualiza el canal de notificaciones según las preferencias del usuario
  Future<void> updateNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('notifications_sound') ?? true;
      final vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // 1. Eliminar el canal existente
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.deleteNotificationChannel('gameon_main');

      // Pequeña pausa para asegurar que el OS procese la eliminación
      await Future.delayed(const Duration(milliseconds: 200));

      // 2. Crear el nuevo canal con la configuración actualizada
      // Si el sonido está desactivado, bajamos la importancia a DEFAULT para evitar intrusión
      // Si está activado, mantenemos HIGH para que suene y vibre
      final importance = soundEnabled
          ? Importance.high
          : Importance.defaultImportance;

      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'gameon_main', // Nuevo ID para forzar actualización
        'Notificaciones de GameOn',
        description: 'Notificaciones de mensajes y reservas',
        importance: importance,
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
        showBadge: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      debugPrint(
        '[NotificationService] Canal actualizado: Sonido=$soundEnabled, Vibración=$vibrationEnabled, Importancia=$importance',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error al actualizar canal: $e');
    }
  }

  /// Configura las notificaciones en primer plano
  ///
  /// Desactiva la presentación automática de notificaciones cuando
  /// la app está activa. Las notificaciones solo se mostrarán cuando
  /// la app esté en background o cerrada.
  Future<void> _configureForegroundNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
    debugPrint(
      '[NotificationService] Notificaciones en foreground desactivadas',
    );
  }

  /// Registra el handler para mensajes en background
  void _registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('[NotificationService] Background handler registrado');
  }

  // ==========================================================================
  // LISTENERS
  // ==========================================================================

  /// Configura todos los listeners de Firebase Messaging
  void _setupListeners() {
    _setupForegroundListener();
    _setupBackgroundOpenedListener();
    _checkInitialMessage();
  }

  /// Listener para mensajes cuando la app está en PRIMER PLANO
  ///
  /// No se muestra notificación visual, solo se registra en logs.
  /// Aquí podrías actualizar la UI internamente si es necesario.
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '📨 Mensaje recibido en primer plano: ${message.notification?.title}',
      );
      // Aquí podrías:
      // - Actualizar un badge de mensajes no leídos
      // - Refrescar la lista de conversaciones
      // - Mostrar un banner discreto dentro de la app
      // - Actualizar un Stream o Provider
    });
  }

  /// Listener para cuando el usuario toca una notificación (app en BACKGROUND)
  void _setupBackgroundOpenedListener() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Notificación abierta desde background');
      _navigationService.handleNotificationTap(message.data);
    });
  }

  /// Verifica si la app se abrió desde una notificación (app estaba CERRADA)
  Future<void> _checkInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📬 App abierta desde notificación');
      _navigationService.handleNotificationTap(initialMessage.data);
    }
  }

  // ==========================================================================
  // MÉTODOS PÚBLICOS
  // ==========================================================================

  /// Obtiene el token FCM del dispositivo actual
  ///
  /// Este token se debe guardar en Supabase para poder enviar
  /// notificaciones push a este dispositivo.
  Future<String?> getToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[NotificationService] Token FCM obtenido');
      return token;
    } catch (e) {
      debugPrint('[NotificationService] Error al obtener token: $e');
      return null;
    }
  }

  /// Stream que emite cada vez que el token FCM se actualiza
  ///
  /// Útil para mantener sincronizado el token en Supabase.
  Stream<String> get onTokenRefresh {
    return FirebaseMessaging.instance.onTokenRefresh;
  }
}
