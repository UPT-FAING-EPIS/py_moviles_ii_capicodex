import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';

const _imageRoot = 'assets/images_paypal_tutorial/';

class _TutorialStep {
  const _TutorialStep(
    this.title,
    this.description,
    this.image, {
    this.link,
    this.linkLabel,
  });

  final String title;
  final String description;
  final String? image;
  final String? link;
  final String? linkLabel;
}

const _steps = <_TutorialStep>[
  _TutorialStep(
    'Comprueba tu cuenta',
    'Inicia sesión con la cuenta PayPal Business que recibirá los pagos. En la elegibilidad de la cuenta, comprueba que “Go live” y “PayPal payments” estén disponibles en Live.',
    'interfaz de Elegibilidad de la cuenta.png',
    link: 'https://developer.paypal.com/dashboard/accountStatus',
    linkLabel: 'Abrir elegibilidad de PayPal',
  ),
  _TutorialStep(
    'Entra al panel Developer',
    'Abre el panel para desarrolladores de PayPal y toca “Apps & Credentials” (Aplicaciones y credenciales).',
    'pantalla principal del Dashboard developer _ flecha hacia la opcion Apps Credentials.png',
    link: 'https://developer.paypal.com/dashboard',
    linkLabel: 'Abrir panel Developer',
  ),
  _TutorialStep(
    'Selecciona Live',
    'En “Apps & Credentials”, cambia de Sandbox a Live. Si ya tienes una aplicación Live para tu negocio, puedes abrirla; de lo contrario toca “Create App”.',
    'interfaz de apps credentials _ seleccion de Live _ flecha seleccionando Create App.png',
    link: 'https://developer.paypal.com/dashboard/applications/live',
    linkLabel: 'Abrir aplicaciones Live',
  ),
  _TutorialStep(
    'Crea tu aplicación',
    'Escribe un nombre que identifique tu negocio y pulsa “Create App”. La aplicación debe estar asociada a tu propia cuenta PayPal Business.',
    'Nombre a la app de create app _ seleccionar Create App.png',
  ),
  _TutorialStep(
    'Copia las credenciales Live',
    'Dentro de la aplicación recién creada, copia “Client ID” y “Secret” (Clave secreta 1). Confirma que sigues en Live. El Secret es privado: no lo publiques ni lo envíes por chat.',
    'interfaz de la app creada y flechas para copiar el Client ID y Clave secreta.png',
  ),
  _TutorialStep(
    'Guárdalas en GameOn',
    'Regresa a Cobros PayPal Live. Pega el Client ID en “Client ID Live” y la clave secreta en “Secret Live”; pulsa “Guardar credenciales”. Si cambias la clave en PayPal, actualízala también aquí.',
    null,
    link: 'https://developer.paypal.com/api/get-started/',
    linkLabel: 'Leer la guía oficial de PayPal',
  ),
];

class PayPalTutorialView extends StatefulWidget {
  const PayPalTutorialView({super.key});

  @override
  State<PayPalTutorialView> createState() => _PayPalTutorialViewState();
}

class _PayPalTutorialViewState extends State<PayPalTutorialView> {
  int _index = 0;

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace de PayPal.')),
      );
    }
  }

  void _showImage(String path) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Imagen del tutorial')),
          body: ColoredBox(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Image.asset('$_imageRoot$path', fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    final step = _steps[_index];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial PayPal Live'),
        flexibleSpace: background == null
            ? null
            : Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(background),
                    fit: BoxFit.cover,
                    opacity: .4,
                  ),
                ),
              ),
      ),
      body: Stack(
        children: [
          if (background != null)
            Positioned.fill(
              child: Opacity(
                opacity: .08,
                child: Image.asset(background, fit: BoxFit.cover),
              ),
            ),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Text(
                      'Paso ${_index + 1} de ${_steps.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_index + 1) / _steps.length,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    if (step.image case final image?) ...[
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showImage(image),
                          child: Column(
                            children: [
                              Image.asset(
                                '$_imageRoot$image',
                                fit: BoxFit.contain,
                              ),
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.zoom_in),
                                    SizedBox(width: 6),
                                    Text('Toca para ampliar'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (step.link case final link?)
                      OutlinedButton.icon(
                        onPressed: () => _openLink(link),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(step.linkLabel ?? 'Abrir PayPal'),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _index == 0
                              ? null
                              : () => setState(() => _index--),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Anterior'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _index == _steps.length - 1
                              ? () => Navigator.pop(context)
                              : () => setState(() => _index++),
                          icon: Icon(
                            _index == _steps.length - 1
                                ? Icons.check
                                : Icons.arrow_forward,
                          ),
                          label: Text(
                            _index == _steps.length - 1
                                ? 'Ir a configurar'
                                : 'Siguiente',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
