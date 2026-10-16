import 'package:flutter/material.dart';

class InfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.lightbulb_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bannerColor = color ?? Colors.blue[600]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bannerColor.withOpacity(0.1), bannerColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: bannerColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: bannerColor,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
