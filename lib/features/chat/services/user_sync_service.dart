import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_user.dart';

/// Servicio para sincronizar datos de usuarios entre Supabase y Firebase
class UserSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _usersCollection = 'users';

  /// Sincronizar usuario de Supabase a Firebase
  /// Se debe llamar al iniciar sesión y al actualizar el perfil
  Future<void> syncUserToFirebase({
    required String userId,
    required String nombre,
    String? fotoPerfil,
  }) async {
    final chatUser = ChatUser(
      id: userId,
      nombre: nombre,
      fotoPerfil: fotoPerfil,
    );

    await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .set(chatUser.toJson(), SetOptions(merge: true));
  }

  /// Sincronizar usuario actual desde Supabase
  Future<void> syncCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Obtener datos del perfil desde Supabase
    try {
      final response = await _supabase
          .from('usuarios_deportistas')
          .select('nombre, apellidos, imagen_perfil')
          .eq('auth_id', user.id)
          .single();

      final nombre = response['nombre'] as String? ?? '';
      final apellidos = response['apellidos'] as String? ?? '';
      final nombreCompleto = '$nombre $apellidos'.trim();
      final imagenPerfil = response['imagen_perfil'] as String?;

      await syncUserToFirebase(
        userId: user.id,
        nombre: nombreCompleto.isEmpty ? 'Usuario' : nombreCompleto,
        fotoPerfil: imagenPerfil,
      );
    } catch (e) {
      // Si no se encuentra el perfil, usar datos del auth
      final nombreMeta = user.userMetadata?['nombre'] as String? ?? '';
      final apellidosMeta = user.userMetadata?['apellidos'] as String? ?? '';
      final nombreCompletoMeta = '$nombreMeta $apellidosMeta'.trim();

      await syncUserToFirebase(
        userId: user.id,
        nombre: nombreCompletoMeta.isEmpty ? 'Usuario' : nombreCompletoMeta,
        fotoPerfil: null,
      );
    }
  }

  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {
    await _firestore.collection(_usersCollection).doc(userId).set({
      'is_online': isOnline,
      'last_seen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setCurrentUserPresence(bool isOnline) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await setPresence(userId: user.id, isOnline: isOnline);
  }

  //updatelastseen

  Future<void> updateLastSeen(String userId) async {
    await _firestore.collection(_usersCollection).doc(userId).set({
      'last_seen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCurrentUserLastSeen() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await updateLastSeen(user.id);
  }
}
