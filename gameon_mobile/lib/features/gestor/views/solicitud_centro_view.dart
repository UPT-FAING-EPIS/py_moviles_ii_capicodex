import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';
import 'centro_ubicacion_picker.dart';

/// Solicitud de afiliación para el primer centro y para centros posteriores.
class SolicitudCentroView extends StatefulWidget {
  const SolicitudCentroView({super.key});

  @override
  State<SolicitudCentroView> createState() => _SolicitudCentroViewState();
}

class _SolicitudCentroViewState extends State<SolicitudCentroView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ruc = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  LatLng? _location;
  XFile? _cover;
  List<_EvidenceFile> _evidence = [];
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _ruc,
      _address,
      _phone,
      _email,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final value = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => CentroUbicacionPicker(
          initialPosition: _location,
          initialAddress: _address.text,
        ),
      ),
    );
    if (value != null && mounted) setState(() => _location = value);
  }

  Future<void> _pickCover() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (image != null && mounted) setState(() => _cover = image);
  }

  Future<void> _pickEvidenceImages() async {
    final selected = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (mounted && selected.isNotEmpty) {
      final files = await Future.wait(
        selected.map(
          (file) async => _EvidenceFile(
            name: file.name,
            bytes: await file.readAsBytes(),
            contentType: _contentType(file.name),
          ),
        ),
      );
      if (mounted) {
        setState(() => _evidence = [..._evidence, ...files].take(3).toList());
      }
    }
  }

  Future<void> _pickEvidenceFiles() async {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      allowMultiple: true,
      withData: true,
    );
    if (selected == null || !mounted) return;
    final files = <_EvidenceFile>[];
    for (final file in selected.files) {
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes != null) {
        files.add(
          _EvidenceFile(
            name: file.name,
            bytes: bytes,
            contentType: _contentType(file.name),
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _evidence = [..._evidence, ...files].take(3).toList());
    }
  }

  Future<void> _pickEvidence() async {
    if (_evidence.length >= 3) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Seleccionar imágenes'),
              subtitle: const Text('JPG o PNG desde la galería'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickEvidenceImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('Seleccionar archivos'),
              subtitle: const Text('PDF, DOC, DOCX, JPG o PNG'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickEvidenceFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _upload(XFile file, String prefix) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final clean = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '$uid/${DateTime.now().microsecondsSinceEpoch}_${prefix}_$clean';
    await Supabase.instance.client.storage
        .from('gestor-solicitudes')
        .uploadBinary(
          path,
          await file.readAsBytes(),
          fileOptions: FileOptions(contentType: _contentType(file.name)),
        );
    return path;
  }

  Future<String> _uploadEvidence(_EvidenceFile file) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final clean = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '$uid/${DateTime.now().microsecondsSinceEpoch}_evidencia_$clean';
    await Supabase.instance.client.storage
        .from('gestor-solicitudes')
        .uploadBinary(
          path,
          file.bytes,
          fileOptions: FileOptions(contentType: file.contentType),
        );
    return path;
  }

  String _contentType(String fileName) {
    switch (fileName.split('.').last.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() ||
        _location == null ||
        _cover == null ||
        _evidence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa la ubicación, imagen principal y al menos una evidencia.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final db = Supabase.instance.client;
      // Primero habilita el espacio temporal de archivos para la solicitud.
      await db.rpc(
        'solicitar_gestor_actual',
        params: {'p_nombre': _name.text.trim(), 'p_ruc': _ruc.text.trim()},
      );
      final coverPath = await _upload(_cover!, 'portada');
      final requestId = await db.rpc(
        'crear_solicitud_centro_actual',
        params: {
          'p_nombre': _name.text.trim(),
          'p_ruc': _ruc.text.trim(),
          'p_direccion': _address.text.trim(),
          'p_latitud': _location!.latitude,
          'p_longitud': _location!.longitude,
          'p_telefono': _phone.text.trim(),
          'p_email': _email.text.trim(),
          'p_descripcion': _description.text.trim(),
          'p_imagen_ruta': coverPath,
        },
      );
      for (final file in _evidence) {
        final path = await _uploadEvidence(file);
        await db.rpc(
          'agregar_evidencia_solicitud_centro',
          params: {'p_solicitud_id': requestId, 'p_ruta': path},
        );
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Solicitud enviada'),
          content: const Text(
            'El administrador revisará la información y las evidencias de tu complejo deportivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo enviar la solicitud: $e')),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    return Scaffold(
      body: Stack(
        children: [
          if (background != null)
            Positioned.fill(
              child: Opacity(
                opacity: .08,
                child: Image.asset(background, fit: BoxFit.cover),
              ),
            ),
          Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(
                    alpha: background == null ? 1 : .80,
                  ),
                  colors.primaryContainer.withValues(
                    alpha: background == null ? 1 : .85,
                  ),
                ],
              ),
              image: background == null
                  ? null
                  : DecorationImage(
                      image: AssetImage(background),
                      fit: BoxFit.cover,
                      opacity: .42,
                    ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 20, 18),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AFILIACIÓN DE NEGOCIO',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Registra tu complejo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Datos del complejo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Registra un complejo por solicitud. Después podrás solicitar la afiliación de otros complejos.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del negocio o complejo',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                        ? 'Ingresa el nombre del complejo'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ruc,
                    decoration: const InputDecoration(
                      labelText: 'RUC (11 dígitos)',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.trim().length == 11
                        ? null
                        : 'Ingresa los 11 dígitos del RUC',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator: (value) =>
                        value == null || value.trim().length < 5
                        ? 'Ingresa una dirección válida'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(
                      _location == null
                          ? 'Seleccionar ubicación en mapa'
                          : 'Ubicación seleccionada',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de contacto',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Correo de contacto',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: 'Descripción del complejo',
                    ),
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: Text(
                      _cover == null
                          ? 'Imagen principal del complejo'
                          : _cover!.name,
                    ),
                    subtitle: const Text('Obligatoria'),
                    trailing: const Icon(Icons.upload_outlined),
                    onTap: _pickCover,
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text('Evidencias: ${_evidence.length}/3'),
                    subtitle: const Text(
                      'Hasta 3: imágenes, PDF o documentos Word',
                    ),
                    trailing: const Icon(Icons.add_photo_alternate_outlined),
                    onTap: _evidence.length >= 3 ? null : _pickEvidence,
                  ),
                  for (final file in _evidence)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.attach_file),
                      title: Text(file.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _evidence.remove(file)),
                      ),
                    ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(
                      _saving
                          ? 'Enviando...'
                          : 'Enviar solicitud para revisión',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceFile {
  const _EvidenceFile({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;
}
