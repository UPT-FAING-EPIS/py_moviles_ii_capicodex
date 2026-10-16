import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/perfil/viewmodels/perfil_viewmodel.dart';
import 'features/perfil/views/session_gate.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_navigation_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

late final NotificationService notificationService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[BOOT] Inicializando Supabase...');
  await Supabase.initialize(
    url: 'https://pqhpvowpirqyodgdguuw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxaHB2b3dwaXJxeW9kZ2RndXV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxOTQ3MDksImV4cCI6MjA3Mjc3MDcwOX0.d6EyyKnHHP_3BKNqRIIx3CvMShL96Ww21pNgMDmnRHk',
  );
  debugPrint('[BOOT] Supabase listo');

  debugPrint('[BOOT] Inicializando Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    debugPrint('[BOOT] Firebase listo');
  } catch (error, stackTrace) {
    debugPrint('[BOOT] Firebase no pudo inicializarse: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  final navigationService = NotificationNavigationService(navigatorKey);
  notificationService = NotificationService(navigationService);

  debugPrint('[BOOT] Mostrando interfaz...');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PerfilViewModel(notificationService),
        ),
      ],
      child: const MainApp(),
    ),
  );

  // Las notificaciones no deben bloquear la primera pantalla.
  unawaited(
    notificationService
        .initialize()
        .timeout(const Duration(seconds: 10))
        .then((_) => debugPrint('[BOOT] Notificaciones listas'))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('[BOOT] Notificaciones no disponibles: $error');
          return null;
        }),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      locale: const Locale('es', 'ES'),
      home: const SessionGate(),
    );
  }
}
