import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../perfil/viewmodels/perfil_viewmodel.dart';

class HistorialPagosView extends StatelessWidget {
  final int? reservaId;
  const HistorialPagosView({super.key, this.reservaId});

  Future<List<Map<String, dynamic>>> _load(BuildContext context) async {
    final id = int.parse(context.read<PerfilViewModel>().profile!.id);
    var query = Supabase.instance.client.from('reservas')
        .select('id,fecha,estado,metodo_pago,monto_pagado,creado_en,yape_monto_esperado')
        .eq('id_usuario', id);
    if (reservaId != null) query = query.eq('id', reservaId!);
    final rows = await query.order('creado_en', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Historial de pagos')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _load(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) return Center(child: Text('No se pudo cargar: ${snapshot.error}'));
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) return const Center(child: Text('Aún no tienes movimientos de reservas.'));
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Este historial muestra los pagos asociados a tus reservas. La revisión Yape no equivale a una confirmación automática del proveedor.'),
          const SizedBox(height: 12),
          for (final r in snapshot.data!) Card(child: ListTile(
            title: Text('Reserva #${r['id']} · ${r['fecha']}'),
            subtitle: Text('${r['metodo_pago'] ?? 'Sin método'} · ${r['estado']}\n'
              'Importe: S/ ${r['monto_pagado'] ?? r['yape_monto_esperado'] ?? '—'}'),
            isThreeLine: true,
          )),
        ]);
      },
    ),
  );
}
