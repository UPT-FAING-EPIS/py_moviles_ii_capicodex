import 'package:flutter/material.dart';

class DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?) onChanged;
  final double horizontalPadding;

  const DropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.horizontalPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: const InputDecoration(
                labelText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              hint: Text(label),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
