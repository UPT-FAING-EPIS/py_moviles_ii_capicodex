import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';

class RegistroGestorView extends StatefulWidget {
  const RegistroGestorView({super.key});
  @override
  State<RegistroGestorView> createState() => _RegistroGestorViewState();
}

class _RegistroGestorViewState extends State<RegistroGestorView> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), ruc = TextEditingController();
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    for (final c in [name, ruc, email, password]) { c.dispose(); }
    super.dispose();
  }

  Future<void> register() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (auth.currentUser != null) {
        await context.read<PerfilViewModel>().registerManager(
          businessName: name.text, ruc: ruc.text,
        );
        if (mounted) Navigator.pop(context);
        return;
      }
      final response = await auth.signUp(
        email: email.text.trim(), password: password.text,
        data: {
          'tipo_cuenta': 'gestor',
          'nombre_institucion': name.text.trim(),
          'ruc': ruc.text.trim(),
        },
      );
      if (response.user == null) throw Exception('No se creó la cuenta');
      // El trigger crea una solicitud pendiente de aprobación.
      if (response.session != null) await auth.signOut();
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Registro recibido'),
        content: const Text('Confirma tu correo si se solicita. Luego inicia sesión como gestor, sube hasta tres evidencias del negocio y espera la aprobación del administrador.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo registrar: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registro de gestor')),
    body: Form(key: form, child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Gestiona tus centros y canchas deportivas desde la app.'),
      const SizedBox(height: 16),
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nombre del negocio'),
        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
      TextFormField(controller: ruc, decoration: const InputDecoration(labelText: 'RUC (11 dígitos)'),
        keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
        validator: (v) => v?.length == 11 ? null : 'Ingresa 11 dígitos'),
      if (Supabase.instance.client.auth.currentUser == null) ...[
        TextFormField(controller: email, decoration: const InputDecoration(labelText: 'Correo electrónico'),
          keyboardType: TextInputType.emailAddress,
          validator: (v) => v != null && v.contains('@') ? null : 'Correo inválido'),
        TextFormField(controller: password, decoration: const InputDecoration(labelText: 'Contraseña'),
          obscureText: true, validator: (v) => v != null && v.length >= 8 ? null : 'Mínimo 8 caracteres'),
      ] else const Padding(padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Usaremos tu cuenta actual de deportista para habilitar también el perfil gestor.')),
      const SizedBox(height: 24),
      FilledButton(onPressed: busy ? null : register,
        child: busy ? const CircularProgressIndicator() : Text(
          Supabase.instance.client.auth.currentUser == null ? 'Crear cuenta gestora' : 'Habilitar perfil gestor')),
    ])),
  );
}
