import 'package:flutter/material.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import 'package:gameon/features/perfil/views/perfil_view/unauthenticated/forms/widgets/password_field.dart';
import 'package:gameon/features/perfil/views/perfil_view/unauthenticated/forms/widgets/social_buttons.dart';
import 'package:provider/provider.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              'Bienvenido',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ingresa con tu correo y contraseña para continuar.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.green.shade700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.green.shade700,
                    width: 2,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                if (!v.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            PasswordField(controller: passCtrl, label: 'Contraseña'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                ),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Consumer<PerfilViewModel>(
              builder: (context, vm, _) {
                final busy = vm.isLoggingIn;
                return ElevatedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          final res = await vm.login(
                            email: emailCtrl.text,
                            password: passCtrl.text,
                          );
                          if (!context.mounted) return;
                          if (res.ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sesión iniciada')),
                            );
                            Navigator.of(context).pop();
                          } else if (!res.isBusy) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res.message ?? 'Error al iniciar sesión',
                                ),
                              ),
                            );
                          }
                        },
                  icon: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    busy ? 'Ingresando...' : 'Ingresar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                );
              },
            ),
            const SocialButtons(),
          ],
        ),
      ),
    );
  }
}
