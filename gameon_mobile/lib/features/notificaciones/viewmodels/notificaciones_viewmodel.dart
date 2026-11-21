import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notificacion.dart';

class NotificacionesViewModel extends ChangeNotifier {
  final SupabaseClient _supabase;
  RealtimeChannel? _channel;
  late final String _destinatarioAuthId;

  List<Notificacion> items = [];
  bool loading = false;
  String? error;

  int get unreadCount =>
      items.where((notification) => !notification.leido).length;

  NotificacionesViewModel({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client {
    _destinatarioAuthId = _supabase.auth.currentUser?.id ?? '';
  }

  Future<void> start() async {
    if (_destinatarioAuthId.isEmpty) {
      error = 'Inicia sesión para ver tus notificaciones';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    await _load();
    _channel = _supabase.channel('notificaciones-$_destinatarioAuthId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notificaciones',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'destinatario_auth_id',
          value: _destinatarioAuthId,
        ),
        callback: (_) => _load(),
      )
      ..subscribe();
  }

  Future<void> _load() async {
    try {
      final data = await _supabase
          .from('notificaciones')
          .select()
          .eq('destinatario_auth_id', _destinatarioAuthId)
          .order('fecha', ascending: false);
      items = data.map(Notificacion.fromJson).toList();
      error = null;
    } on PostgrestException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> marcarLeido(String id) async {
    try {
      await _supabase
          .from('notificaciones')
          .update({'leido': true})
          .eq('id', int.parse(id));
    } on PostgrestException {
      // La siguiente recarga permite reintentar sin ocultar la notificación.
    }
  }

  @override
  void dispose() {
    if (_channel != null) _supabase.removeChannel(_channel!);
    super.dispose();
  }
}
