import 'package:flutter/material.dart';
import '../services/gestor_service.dart';

/// Una configuración Yape por gestor, aplicada a todos sus centros y canchas.
class ConfigurarYapeView extends StatefulWidget {
  final int gestorId;
  final GestorService service;

  const ConfigurarYapeView({
    super.key,
    required this.gestorId,
    required this.service,
  });

  @override
  State<ConfigurarYapeView> createState() => _ConfigurarYapeViewState();
}

class _ConfigurarYapeViewState extends State<ConfigurarYapeView> {
  final _form = GlobalKey<FormState>();
  final _titular = TextEditingController();
  final _celular = TextEditingController();
  String? _qr;
  bool _loading = true;
  bool _uploading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cobro = await widget.service.cobroYape(widget.gestorId);
      if (!mounted) return;
      setState(() {
        _qr = cobro?['yape_qr_url']?.toString();
        _titular.text = '${cobro?['yape_titular'] ?? ''}';
        _celular.text = '${cobro?['yape_celular'] ?? ''}';
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _upload() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await widget.service.subirImagen();
      if (url != null && mounted) setState(() => _qr = url);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo subir el QR: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_qr == null) {
      setState(() => _error = 'Selecciona la imagen de tu código QR Yape.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.guardarCobroYape(
        widget.gestorId,
        _qr!,
        _titular.text.trim(),
        _celular.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titular.dispose();
    _celular.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi código Yape')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Text(
                    'Cobros de mis canchas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este QR se mostrará a los deportistas al reservar cualquiera de tus canchas.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titular,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del titular de Yape',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Ingresa el titular'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _celular,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Número de celular Yape',
                    ),
                    validator: (v) => v == null || v.trim().length < 9
                        ? 'Ingresa un celular válido'
                        : null,
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Imagen de mi QR Yape',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_qr != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.network(
                          _qr!,
                          height: 220,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 100,
                            child: Center(
                              child: Text('No se pudo mostrar el QR'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _upload,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      _uploading
                          ? 'Subiendo imagen...'
                          : _qr == null
                          ? 'Subir imagen de mi QR Yape'
                          : 'Cambiar imagen de mi QR',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'El gestor comprueba cada pago recibido en Yape antes de confirmar la reserva.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: colors.error)),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _saving || _uploading ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _saving ? 'Guardando...' : 'Guardar código Yape',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
