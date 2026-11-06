import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvisosReservaView extends StatefulWidget {
  const AvisosReservaView({super.key});
  @override
  State<AvisosReservaView> createState() => _AvisosReservaViewState();
}

class _AvisosReservaViewState extends State<AvisosReservaView> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> avisos = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = db.auth.currentUser?.id;
      if (uid == null) return;
      final rows = await db.from('avisos_reserva').select()
          .eq('destinatario', uid).order('creado_en', ascending: false).limit(100);
      if (mounted) setState(() { avisos = List<Map<String, dynamic>>.from(rows); error = null; });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> _read(Map<String, dynamic> aviso) async {
    await db.from('avisos_reserva').update({'leido': true})
        .eq('id', aviso['id']);
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Avisos de reservas'), actions: [
      IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
    ]),
    body: error != null ? Center(child: Text(error!)) :
      RefreshIndicator(onRefresh: _load, child: ListView(
        children: [
          if (avisos.isEmpty) const ListTile(title: Text('Aún no hay avisos de reservas')),
          for (final aviso in avisos) ListTile(
            leading: Icon(aviso['leido'] == true ? Icons.notifications_none : Icons.notifications_active),
            title: Text('${aviso['mensaje']}'),
            subtitle: Text('Reserva #${aviso['reserva_id']} · ${aviso['creado_en']}'),
            onTap: () => _read(aviso),
          ),
        ],
      )),
  );
}
