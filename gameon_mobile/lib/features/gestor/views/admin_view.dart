import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/core/theme/visual_theme_picker.dart';
import 'package:gameon/core/widgets/role_switcher.dart';
import '../../perfil/viewmodels/perfil_viewmodel.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});
  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> solicitudes = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await db.rpc('solicitudes_gestor');
      if (mounted)
        setState(
          () => solicitudes = (data as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _ver(String path) async {
    try {
      final url = await db.storage
          .from('gestor-solicitudes')
          .createSignedUrl(path, 300);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Evidencia del negocio'),
          content: SizedBox(
            width: 340,
            height: 400,
            child: Image.network(url, fit: BoxFit.contain),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _resolver(int id, bool aprobar) async {
    try {
      await db.rpc(
        'resolver_solicitud_gestor',
        params: {'p_id': id, 'p_aprobar': aprobar},
      );
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo resolver: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilViewModel>();
    if (!vm.isAdmin)
      return const Scaffold(body: Center(child: Text('Acceso denegado')));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración GameOn'),
        actions: [
          VisualThemePicker(iconColor: Theme.of(context).colorScheme.primary),
          const RoleSwitcher(),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Solicitudes de gestores',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Revisa el RUC y las imágenes antes de habilitar la gestión de centros.',
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          if (!loading && solicitudes.isEmpty)
            const ListTile(title: Text('No hay solicitudes pendientes')),
          for (final s in solicitudes)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s['nombre'] ?? 'Negocio sin nombre'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'RUC: ${s['ruc'] ?? '—'} · ${s['estado'] == 0 ? 'Pendiente' : 'Rechazada'}',
                    ),
                    for (final path in (s['evidencias'] as List? ?? []))
                      ListTile(
                        leading: const Icon(Icons.image),
                        title: Text('$path'.split('/').last),
                        onTap: () => _ver('$path'),
                      ),
                    if (s['estado'] == 0)
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _resolver(s['id'] as int, false),
                            child: const Text('Rechazar'),
                          ),
                          FilledButton(
                            onPressed: (s['evidencias'] as List? ?? []).isEmpty
                                ? null
                                : () => _resolver(s['id'] as int, true),
                            child: const Text('Aprobar'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          if (vm.hasAthleteProfile)
            TextButton(
              onPressed: () => vm.selectMode(AppUserMode.deportista),
              child: const Text('Volver a deportista'),
            ),
          if (vm.hasManagerProfile)
            TextButton(
              onPressed: () => vm.selectMode(AppUserMode.gestor),
              child: const Text('Cambiar a gestor'),
            ),
          TextButton(onPressed: vm.signOut, child: const Text('Cerrar sesión')),
        ],
      ),
    );
  }
}
