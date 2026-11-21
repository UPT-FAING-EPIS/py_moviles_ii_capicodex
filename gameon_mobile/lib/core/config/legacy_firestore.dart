import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Conexión exclusiva al proyecto que conserva las conversaciones y presencia.
/// El proyecto predeterminado de Firebase se reserva para FCM.
FirebaseFirestore? _legacyFirestore;

Future<void> initializeLegacyFirestore() async {
  if (_legacyFirestore != null) return;

  const options = FirebaseOptions(
    apiKey: 'AIzaSyAvyRkVmA_0xYPY1IGs78Ffbeic14yk7zk',
    appId: '1:640447509717:android:d30da91d1689aa62599e5c',
    messagingSenderId: '640447509717',
    projectId: 'gameon-mobile',
    storageBucket: 'gameon-mobile.firebasestorage.app',
  );

  FirebaseApp app;
  final existingApps = Firebase.apps.where(
    (firebaseApp) => firebaseApp.name == 'gameonLegacyFirestore',
  );
  if (existingApps.isNotEmpty) {
    app = existingApps.first;
  } else {
    app = await Firebase.initializeApp(
      name: 'gameonLegacyFirestore',
      options: options,
    );
  }

  _legacyFirestore = FirebaseFirestore.instanceFor(app: app);
}

FirebaseFirestore get legacyFirestore {
  final firestore = _legacyFirestore;
  if (firestore == null) {
    throw StateError('Firestore de conversaciones no fue inicializado.');
  }
  return firestore;
}
