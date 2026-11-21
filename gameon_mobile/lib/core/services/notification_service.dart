import 'dart:convert';

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
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._navigationService);

  // ==========================================================================
  // INICIALIZACIÓN
  // ==========================================================================

  /// Inicializa el servicio de notificaciones
  ///
  /// Debe llamarse en main() antes de runApp()
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await updateNotificationPreferences();
    await requestPermission();
    await _configureForegroundNotifications();
    _registerBackgroundHandler();
    _setupListeners();
  }

  /// Configura los avisos locales que se usan cuando llega un push con la app
  /// abierta. FCM no muestra automáticamente el banner en foreground.
  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload);
          if (data is Map<String, dynamic>) {
            _navigationService.handleNotificationTap(data);
          } else if (data is Map) {
            _navigationService.handleNotificationTap(
              Map<String, dynamic>.from(data),
            );
          }
        } catch (e) {
          debugPrint('[NotificationService] Payload inválido: $e');
        }
      },
    );
  }

  // ==========================================================================
  // CONFIGURACIÓN
  // ==========================================================================

  /// Solicita permisos de notificaciones al usuario
  Future<AuthorizationStatus> requestPermission() async {
    // En Android 13+ el permiso es de tiempo de ejecución. Se solicita
    // explícitamente también desde el plugin local para que el diálogo del
    // sistema aparezca de forma consistente antes de registrar el token FCM.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final settings = await FirebaseMessaging.instance.requestPermission();
    debugPrint(
      '[NotificationService] Estado del permiso: ${settings.authorizationStatus}',
    );
    return settings.authorizationStatus;
  }

  /// Consulta el estado actual del permiso concedido por el sistema operativo.
  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Indica si el usuario desea recibir avisos en este dispositivo.
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  /// Guarda la preferencia de entrega de avisos para este dispositivo.
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  /// Actualiza el canal de notificaciones según las preferencias del usuario
  Future<void> updateNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('notifications_sound') ?? true;
      final vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;

      // 1. Eliminar el canal existente
      await _localNotifications
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

      await _localNotifications
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
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        '📨 Mensaje recibido en primer plano: ${message.notification?.title}',
      );
      await _showForegroundNotification(message);
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!await areNotificationsEnabled()) return;
    final notification = message.notification;
    final title = notification?.title ?? 'Nueva notificación';
    final body = notification?.body ?? '';
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'gameon_main',
        'Notificaciones de GameOn',
        channelDescription: 'Notificaciones de mensajes y reservas',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
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
      if (!await areNotificationsEnabled()) return null;
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
