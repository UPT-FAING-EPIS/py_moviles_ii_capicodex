import 'core/config/backend_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/home/views/home_view.dart';
import 'features/perfil/viewmodels/perfil_viewmodel.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

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
    url: BackendConfig.supabaseUrl,
    anonKey: BackendConfig.supabaseAnonKey,
  );

  // --------------------------------------------------------------------------
  // INICIALIZACIÓN DE FIREBASE
  // --------------------------------------------------------------------------
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --------------------------------------------------------------------------
  // INICIALIZACIÓN DE SERVICIOS DE NOTIFICACIONES
  // --------------------------------------------------------------------------
  final navigationService = NotificationNavigationService(navigatorKey);
  notificationService = NotificationService(navigationService);
  await notificationService.initialize();
  final themeController = ThemeController();
  await themeController.load();

  // --------------------------------------------------------------------------
  // INICIAR LA APP
  // --------------------------------------------------------------------------
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
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
    final themeController = context.watch<ThemeController>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: AppTheme.forVisualTheme(themeController.selection),
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      locale: const Locale('es', 'ES'),
      home: HomeView(),
    );
  }
}
