import 'package:flutter/material.dart';

class EstadoChip extends StatelessWidget {
  final String estado;
  const EstadoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        color = Colors.orange.shade600;
        icon = Icons.hourglass_empty;
        break;
      case 'confirmada':
      case 'pagada':
        color = Colors.green.shade600;
        icon = Icons.check_circle;
        break;
      case 'cancelada':
        color = Colors.red.shade600;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey.shade600;
        icon = Icons.help_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            estado,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
