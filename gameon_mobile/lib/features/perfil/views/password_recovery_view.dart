import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/backend_config.dart';
import '../services/auth_form_validators.dart';
import '../services/password_recovery_service.dart';

class PasswordRecoveryView extends StatefulWidget {
  final String initialEmail;
  final PasswordRecoveryService? service;
  const PasswordRecoveryView({super.key, this.initialEmail = '', this.service});

  @override
  State<PasswordRecoveryView> createState() => _PasswordRecoveryViewState();
}

class _PasswordRecoveryViewState extends State<PasswordRecoveryView> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _codigo = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  late final _service =
      widget.service ??
      PasswordRecoveryService(
        supabaseUrl: BackendConfig.supabaseUrl,
        anonKey: BackendConfig.supabaseAnonKey,
      );
  bool _sent = false;
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    _password.dispose();
    _confirmation.dispose();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_sent) {
        await _service.solicitarCodigo(_email.text);
        if (mounted) setState(() => _sent = true);
      } else {
        await _service.confirmarCambio(
          email: _email.text,
          codigo: _codigo.text,
          password: _password.text,
        );
        _password.clear();
        _confirmation.clear();
        _codigo.clear();
        if (mounted) setState(() => _done = true);
      }
    } on RecoveryException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Recuperar acceso')),
      body: _done
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Contraseña actualizada. Inicia sesión con tu nueva contraseña.',
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver al inicio de sesión'),
                  ),
                ],
              ),
            )
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    _sent
                        ? PasswordRecoveryService.mensajeEnvio
                        : 'Ingresa tu correo para solicitar un código de recuperación.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    enabled: !_busy && !_sent,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                    validator: AuthFormValidators.correo,
                  ),
                  if (_sent) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codigo,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Código del correo',
                      ),
                      validator: (v) =>
                          RegExp(r'^\d{6,10}$').hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Ingresa el código del correo',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Nueva contraseña',
                      ),
                      validator: AuthFormValidators.contrasena,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmation,
                      enabled: !_busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                      ),
                      validator: (v) => AuthFormValidators.confirmarContrasena(
                        v,
                        _password.text,
                      ),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy
                          ? 'Procesando...'
                          : _sent
                          ? 'Cambiar contraseña'
                          : 'Solicitar código',
                    ),
                  ),
                  if (_sent)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              _codigo.clear();
                              _password.clear();
                              _confirmation.clear();
                              setState(() {
                                _sent = false;
                                _error = null;
                              });
                            },
                      child: const Text(
                        'Solicitar otro código o cambiar el correo',
                      ),
                    ),
                ],
              ),
            ),
    ),
  );
}
