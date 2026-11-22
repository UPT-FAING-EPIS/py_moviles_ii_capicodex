import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/core/theme/visual_theme_picker.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';
import '../../perfil/viewmodels/perfil_viewmodel.dart';
import 'solicitud_centro_view.dart';

class GestorPendienteView extends StatefulWidget {
  const GestorPendienteView({super.key});
  @override
  State<GestorPendienteView> createState() => _GestorPendienteViewState();
}

class _GestorPendienteViewState extends State<GestorPendienteView> {
  final db = Supabase.instance.client;
  bool busy = false;
  String? error;
  String? latestCenterStatus;
  List<Map<String, dynamic>> files = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        db.from('gestor_evidencias').select('id,ruta,gestor_id'),
        db
            .from('solicitudes_centros_deportivos')
            .select('estado')
            .order('creado_en', ascending: false)
            .limit(1),
      ]);
      final centerRows = List<Map<String, dynamic>>.from(results[1] as List);
      if (mounted) {
        setState(() {
          files = List<Map<String, dynamic>>.from(results[0] as List);
          latestCenterStatus = centerRows.isEmpty
              ? null
              : '${centerRows.first['estado']}'.toLowerCase();
        });
      }
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
    final rejected = latestCenterStatus == 'rechazada' || vm.managerStatus == -1;
    final colors = Theme.of(context).colorScheme;
    final background = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        flexibleSpace: background == null ? null : Container(decoration: BoxDecoration(image: DecorationImage(image: AssetImage(background), fit: BoxFit.cover, opacity: .42))),
        title: const Text('Solicitud de gestor'),
        actions: const [VisualThemePicker(iconColor: Colors.white)],
      ),
      body: Stack(children: [
        if (background != null) Positioned.fill(child: Opacity(opacity: .08, child: Image.asset(background, fit: BoxFit.cover))),
        ListView(padding: const EdgeInsets.all(20), children: [
        Text(rejected
          ? 'Tu solicitud fue rechazada. Puedes corregir los datos y enviar una nueva solicitud.'
          : 'Tu solicitud espera la revisión del administrador. Adjunta hasta tres imágenes que acrediten tu negocio (por ejemplo, RUC o documentos del centro).'),
        const SizedBox(height: 16),
        Text('Evidencias enviadas: ${files.length}/3'),
        for (final item in files) ListTile(
          leading: const Icon(Icons.image_outlined),
          title: Text('${item['ruta']}'.split('/').last),
        ),
        if (!rejected && vm.managerStatus == 0) FilledButton.icon(
          onPressed: busy || files.length >= 3 ? null : _upload,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(busy ? 'Subiendo...' : 'Añadir imágenes'),
        ),
        if (rejected) FilledButton.icon(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SolicitudCentroView())),
          icon: const Icon(Icons.edit_note_outlined),
          label: const Text('Completar nueva solicitud'),
        ),
        if (!rejected && latestCenterStatus != 'pendiente') OutlinedButton.icon(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SolicitudCentroView())),
          icon: const Icon(Icons.edit_note_outlined),
          label: const Text('Corregir o enviar nueva solicitud'),
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
      ])]),
    );
  }
}
