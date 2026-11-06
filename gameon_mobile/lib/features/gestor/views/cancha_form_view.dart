import 'package:flutter/material.dart';
import '../services/gestor_service.dart';

/// Ficha completa de una cancha, accesible al tocar su tarjeta.
class CanchaFormView extends StatefulWidget {
  final Map<String, dynamic>? area;
  final List<Map<String, dynamic>> centros;
  final List<Map<String, dynamic>> deportes;
  final GestorService service;

  const CanchaFormView({
    super.key,
    this.area,
    required this.centros,
    required this.deportes,
    required this.service,
  });

  @override
  State<CanchaFormView> createState() => _CanchaFormViewState();
}

class _CanchaFormViewState extends State<CanchaFormView> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController name, price, capacity, description, image;
  int? center, sport;
  late String state;
  bool saving = false;
  bool uploading = false;

  int _id(dynamic value) => value is num ? value.toInt() : int.parse('$value');

  @override
  void initState() {
    super.initState();
    final a = widget.area;
    name = TextEditingController(text: '${a?['nombre_area'] ?? ''}');
    price = TextEditingController(text: '${a?['tarifa_por_hora'] ?? ''}');
    capacity = TextEditingController(
      text: '${a?['capacidad_jugadores'] ?? ''}',
    );
    description = TextEditingController(text: '${a?['descripcion'] ?? ''}');
    image = TextEditingController(text: '${a?['imagen_area'] ?? ''}');
    center = a == null
        ? (widget.centros.isEmpty ? null : _id(widget.centros.first['id']))
        : _id(a['institucion_deportiva_id']);
    sport = a == null
        ? (widget.deportes.isEmpty ? null : _id(widget.deportes.first['id']))
        : _id(a['deporte_id']);
    state = '${a?['estado'] ?? 'activa'}';
  }

  @override
  void dispose() {
    for (final controller in [name, price, capacity, description, image]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => uploading = true);
    try {
      final url = await widget.service.subirImagen();
      if (url != null && mounted) setState(() => image.text = url);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la imagen: $e')),
        );
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || center == null || sport == null)
      return;
    setState(() => saving = true);
    try {
      await widget.service.guardarArea({
        'institucion_deportiva_id': center,
        'deporte_id': sport,
        'nombre_area': name.text.trim(),
        'tarifa_por_hora': double.parse(price.text.trim()),
        'capacidad_jugadores': capacity.text.trim().isEmpty
            ? null
            : int.parse(capacity.text.trim()),
        'descripcion': description.text.trim(),
        'imagen_area': image.text.trim().isEmpty ? null : image.text.trim(),
        'estado': state,
      }, id: widget.area == null ? null : _id(widget.area!['id']));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la cancha: $e')),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final states = {'activa', 'inactiva', 'mantenimiento', state}.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.area == null ? 'Nueva cancha' : 'Detalles de cancha',
        ),
      ),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Información de la cancha',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Configura el espacio que verán los deportistas.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              initialValue: center,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Centro deportivo'),
              items: widget.centros
                  .map(
                    (c) => DropdownMenuItem(
                      value: _id(c['id']),
                      child: Text(
                        '${c['nombre']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => center = value),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<int>(
              initialValue: sport,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Deporte'),
              items: widget.deportes
                  .map(
                    (d) => DropdownMenuItem(
                      value: _id(d['id']),
                      child: Text('${d['nombre']}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => sport = value),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Nombre de la cancha',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: price,
              decoration: const InputDecoration(
                labelText: 'Tarifa por hora (S/)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) => double.tryParse(v?.trim() ?? '') == null
                  ? 'Ingresa un importe válido'
                  : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: capacity,
              decoration: const InputDecoration(
                labelText: 'Capacidad de jugadores',
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v != null &&
                      v.trim().isNotEmpty &&
                      int.tryParse(v.trim()) == null
                  ? 'Ingresa un número válido'
                  : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: description,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Descripción de la cancha',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Imagen de la cancha',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (image.text.trim().isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  image.text.trim(),
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 80,
                    child: Center(child: Text('No se pudo mostrar la imagen')),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: uploading ? null : _upload,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                uploading
                    ? 'Subiendo imagen...'
                    : 'Elegir imagen de la galería',
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: image,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'URL de imagen (opcional)',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 26),
            DropdownButtonFormField<String>(
              initialValue: state,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: states
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) => setState(() => state = value ?? state),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(saving ? 'Guardando...' : 'Guardar cancha'),
            ),
          ],
        ),
      ),
    );
  }
}
