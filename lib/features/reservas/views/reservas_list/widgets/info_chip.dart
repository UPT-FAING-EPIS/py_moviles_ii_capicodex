import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor? color;
  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipColor[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: chipColor[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
