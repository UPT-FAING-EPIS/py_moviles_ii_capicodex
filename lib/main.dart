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

// ============================================================================
// GLOBAL KEYS
// ============================================================================

/// Navigator key global para permitir navegación sin BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ============================================================================
// GLOBAL SERVICES
// ============================================================================

/// Instancia global del servicio de notificaciones
/// Se inicializa en main() y se puede usar en toda la app
late final NotificationService notificationService;

// ============================================================================
// MAIN - PUNTO DE ENTRADA DE LA APP
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --------------------------------------------------------------------------
  // INICIALIZACIÓN DE SUPABASE
  // --------------------------------------------------------------------------
  await Supabase.initialize(
    url: 'https://pqhpvowpirqyodgdguuw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxaHB2b3dwaXJxeW9kZ2RndXV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxOTQ3MDksImV4cCI6MjA3Mjc3MDcwOX0.d6EyyKnHHP_3BKNqRIIx3CvMShL96Ww21pNgMDmnRHk',
  );

  // --------------------------------------------------------------------------
  // INICIALIZACIÓN DE FIREBASE
  // --------------------------------------------------------------------------
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase no pudo inicializarse: $error');
  }

  // --------------------------------------------------------------------------
  // INICIALIZACIÓN DE SERVICIOS DE NOTIFICACIONES
  // --------------------------------------------------------------------------
  final navigationService = NotificationNavigationService(navigatorKey);
  notificationService = NotificationService(navigationService);
  try {
    await notificationService.initialize();
  } catch (error) {
    debugPrint('Notificaciones no disponibles: $error');
  }

  // --------------------------------------------------------------------------
  // INICIAR LA APP
  // --------------------------------------------------------------------------
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
}

// ============================================================================
// WIDGET PRINCIPAL DE LA APP
// ============================================================================

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
