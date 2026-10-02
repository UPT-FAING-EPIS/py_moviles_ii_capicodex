import 'package:flutter/material.dart';

class SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const SectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black87),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 2,
          ),
        ),
        const Divider(height: 0, indent: 20, endIndent: 20, thickness: 0.6),
      ],
    );
  }
}
