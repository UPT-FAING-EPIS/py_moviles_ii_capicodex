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
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 17,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    items: items,
    onChanged: onChanged,
  );
}
