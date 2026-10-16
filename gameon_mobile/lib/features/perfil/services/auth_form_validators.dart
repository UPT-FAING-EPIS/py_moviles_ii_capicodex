/// Validaciones compartidas por los formularios de acceso y registro.
class AuthFormValidators {
  const AuthFormValidators._();

  static String? nombre(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre';
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  static String? correo(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu correo';
    if (!value.trim().contains('@')) return 'Correo inválido';
    return null;
  }

  static String? contrasena(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? confirmarContrasena(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }
}
