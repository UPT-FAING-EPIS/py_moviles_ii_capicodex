import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReservaNumeroCopiable extends StatelessWidget {
  const ReservaNumeroCopiable({super.key, required this.numero});

  final int numero;

  Future<void> _copiar(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: numero.toString()));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Número de reserva copiado'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo copiar el número de reserva')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(
          'N.º de reserva: $numero',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        OutlinedButton.icon(
          onPressed: () => _copiar(context),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copiar número'),
        ),
      ],
    );
  }
}
