import 'package:flutter/material.dart';

import '../services/calificacion_service.dart';

Future<bool?> mostrarCalificarInstalacionSheet(
  BuildContext context, {
  required int reservaId,
  required String institucionNombre,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CalificarInstalacionSheet(
      reservaId: reservaId,
      institucionNombre: institucionNombre,
    ),
  );
}

class _CalificarInstalacionSheet extends StatefulWidget {
  final int reservaId;
  final String institucionNombre;

  const _CalificarInstalacionSheet({
    required this.reservaId,
    required this.institucionNombre,
  });

  @override
  State<_CalificarInstalacionSheet> createState() =>
      _CalificarInstalacionSheetState();
}

class _CalificarInstalacionSheetState
    extends State<_CalificarInstalacionSheet> {
  final _service = CalificacionService();
  final _comentarioController = TextEditingController();
  int _puntuacion = 0;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  bool _edicion = false;

  @override
  void initState() {
    super.initState();
    _cargarExistente();
  }

  Future<void> _cargarExistente() async {
    try {
      final calificacion = await _service.obtenerMiCalificacion(
        widget.reservaId,
      );
      if (!mounted) return;
      if (calificacion != null) {
        _puntuacion = calificacion.puntuacion;
        _comentarioController.text = calificacion.comentario ?? '';
        _edicion = true;
      }
    } catch (_) {
      _error = 'No se pudo cargar tu calificación. Inténtalo nuevamente.';
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (_puntuacion == 0) {
      setState(() => _error = 'Selecciona una puntuación de 1 a 5 estrellas.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _service.guardar(
        reservaId: widget.reservaId,
        puntuacion: _puntuacion,
        comentario: _comentarioController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar la calificación.');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottom),
        child: _cargando
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _edicion
                        ? 'Editar calificación'
                        : 'Califica tu experiencia',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.institucionNombre),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final estrella = index + 1;
                      return IconButton(
                        tooltip: '$estrella estrellas',
                        onPressed: _guardando
                            ? null
                            : () => setState(() => _puntuacion = estrella),
                        icon: Icon(
                          estrella <= _puntuacion
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber.shade700,
                          size: 34,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _comentarioController,
                    enabled: !_guardando,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Comentario (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.star_rate_rounded),
                      label: Text(
                        _edicion ? 'Guardar cambios' : 'Enviar calificación',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
