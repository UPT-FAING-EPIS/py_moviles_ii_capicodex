import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.green.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey.shade600,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator:
          widget.validator ??
          (v) {
            if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
            if (v.length < 6) return 'Mínimo 6 caracteres';
            return null;
          },
    );
  }
}
