import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';
import 'paypal_tutorial_view.dart';

class ConfigurarPayPalView extends StatefulWidget {
  const ConfigurarPayPalView({super.key});
  @override
  State<ConfigurarPayPalView> createState() => _ConfigurarPayPalViewState();
}

class _ConfigurarPayPalViewState extends State<ConfigurarPayPalView> {
  final _clientId = TextEditingController();
  final _secret = TextEditingController();
  final _db = Supabase.instance.client;
  bool _busy = false;
  bool _configured = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _clientId.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = Map<String, dynamic>.from(
        await _db.rpc('estado_paypal_gestor') as Map,
      );
      if (mounted) {
        setState(() {
          _configured = data['configurado'] == true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo consultar PayPal: $e');
    }
  }

  Future<void> _saveCredentials() async {
    if (_clientId.text.trim().isEmpty || _secret.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa el Client ID y el Secret Live.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _db.rpc(
        'configurar_paypal_gestor',
        params: {
          'p_client_id': _clientId.text.trim(),
          'p_secret': _secret.text.trim(),
        },
      );
      _secret.clear();
      _clientId.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales PayPal Live guardadas.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobros PayPal Live'),
        flexibleSpace: bg == null
            ? null
            : Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(bg),
                    fit: BoxFit.cover,
                    opacity: .4,
                  ),
                ),
              ),
      ),
      body: Stack(
        children: [
          if (bg != null)
            Positioned.fill(
              child: Opacity(
                opacity: .08,
                child: Image.asset(bg, fit: BoxFit.cover),
              ),
            ),
          ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                _configured
                    ? 'PayPal Live configurado'
                    : 'Conectar mi cuenta PayPal Business',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Las credenciales Live pertenecen a tu cuenta receptora. El Secret se cifra y no se vuelve a mostrar. Al pagar, la tarifa en soles se convierte a USD con una cotización actual y el deportista ve ambos importes antes de continuar.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PayPalTutorialView()),
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Tutorial para obtener estos datos'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _clientId,
                decoration: const InputDecoration(labelText: 'Client ID Live'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _secret,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Secret Live'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _saveCredentials,
                child: Text(
                  _busy
                      ? 'Guardando...'
                      : _configured
                      ? 'Cambiar credenciales'
                      : 'Guardar credenciales',
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
