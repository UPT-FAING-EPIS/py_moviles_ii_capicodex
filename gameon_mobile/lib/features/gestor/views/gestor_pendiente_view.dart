import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/core/theme/visual_theme_picker.dart';
import '../../perfil/viewmodels/perfil_viewmodel.dart';

class GestorPendienteView extends StatefulWidget {
  const GestorPendienteView({super.key});
  @override
  State<GestorPendienteView> createState() => _GestorPendienteViewState();
}

class _GestorPendienteViewState extends State<GestorPendienteView> {
  final db = Supabase.instance.client;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> files = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await db.from('gestor_evidencias').select('id,ruta,gestor_id');
      if (mounted) setState(() => files = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> _upload() async {
    final uid = db.auth.currentUser?.id;
    if (uid == null || files.length >= 3) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 75, maxWidth: 1600);
    if (picked.isEmpty) return;
    setState(() { busy = true; error = null; });
    try {
      final gestor = await db.rpc('solicitudes_gestor_actual');
      final gestorId = (gestor as num).toInt();
      for (final image in picked.take(3 - files.length)) {
        final path = '$uid/${DateTime.now().microsecondsSinceEpoch}_${image.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}.jpg';
        await db.storage.from('gestor-solicitudes').uploadBinary(
          path, await image.readAsBytes(),
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        try {
          await db.from('gestor_evidencias').insert({'gestor_id': gestorId, 'ruta': path});
        } catch (_) {
          try { await db.storage.from('gestor-solicitudes').remove([path]); } catch (_) {}
          rethrow;
        }
      }
      await _load();
    } catch (e) {
      if (mounted) setState(() => error = 'No se pudo subir la evidencia: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de gestor'), actions: [
        VisualThemePicker(iconColor: Theme.of(context).colorScheme.primary),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(vm.managerStatus == -1
          ? 'Tu solicitud fue rechazada. Contacta a soporte para más información.'
          : 'Tu solicitud espera la revisión del administrador. Adjunta hasta tres imágenes que acrediten tu negocio (por ejemplo, RUC o documentos del centro).'),
        const SizedBox(height: 16),
        Text('Evidencias enviadas: ${files.length}/3'),
        for (final item in files) ListTile(
          leading: const Icon(Icons.image_outlined),
          title: Text('${item['ruta']}'.split('/').last),
        ),
        if (vm.managerStatus == 0) FilledButton.icon(
          onPressed: busy || files.length >= 3 ? null : _upload,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(busy ? 'Subiendo...' : 'Añadir imágenes'),
        ),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
        OutlinedButton.icon(
          onPressed: () => context.read<PerfilViewModel>().reloadProfile(),
          icon: const Icon(Icons.refresh), label: const Text('Actualizar estado'),
        ),
        if (vm.hasAthleteProfile) TextButton(
          onPressed: () => vm.selectMode(AppUserMode.deportista),
          child: const Text('Volver a deportista'),
        ),
        TextButton(onPressed: vm.signOut, child: const Text('Cerrar sesión')),
      ]),
    );
  }
}
