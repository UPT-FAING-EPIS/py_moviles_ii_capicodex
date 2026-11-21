import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportView extends StatefulWidget {
  const HelpSupportView({super.key});

  @override
  State<HelpSupportView> createState() => _HelpSupportViewState();
}

class _HelpSupportViewState extends State<HelpSupportView> {
  String _supportEmail = '';
  bool _loadingEmail = true;

  static const _faqs = [
    {
      'question': '¿Cómo creo un partido?',
      'answer':
          'Ve a Partidos, pulsa + y completa deporte, fecha, hora y ubicación.',
    },
    {
      'question': '¿Cómo edito mi perfil?',
      'answer': 'En Perfil, selecciona Editar perfil para modificar tus datos.',
    },
    {
      'question': '¿Es gratis usar GameOn?',
      'answer':
          'Buscar y unirse a partidos públicos es gratis. Las reservas se cobran según la tarifa del complejo.',
    },
    {
      'question': '¿Cómo reportar a un usuario?',
      'answer':
          'Usa el Libro de reclamaciones de tu perfil para dejar un registro formal.',
    },
    {
      'question': '¿Puedo cancelar mi asistencia a un partido?',
      'answer':
          'Sí, desde el detalle del partido, siempre que este aún no haya iniciado.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSupportEmail();
  }

  Future<void> _loadSupportEmail() async {
    try {
      final result = await Supabase.instance.client.rpc(
        'obtener_correo_soporte',
      );
      if (!mounted) return;
      setState(() {
        _supportEmail = '$result'.trim();
        _loadingEmail = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  Future<void> _sendEmail() async {
    if (_supportEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El administrador aún no configuró un correo de soporte.',
          ),
        ),
      );
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('Soporte GameOn - Consulta')}',
    );
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el cliente de correo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final headerBackground = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primaryContainer],
                ),
                image: headerBackground == null
                    ? null
                    : DecorationImage(
                        image: AssetImage(headerBackground),
                        fit: BoxFit.cover,
                        opacity: .42,
                      ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ayuda y soporte',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Preguntas frecuentes y contacto',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Preguntas frecuentes',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ..._faqs.map(_faqItem),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.mail_outline,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¿Aún tienes dudas?',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _supportEmail.isEmpty && !_loadingEmail
                                ? 'El correo de soporte será publicado por el administrador.'
                                : 'Escríbenos y te responderemos lo antes posible.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _loadingEmail ? null : _sendEmail,
                              icon: const Icon(Icons.send),
                              label: Text(
                                _loadingEmail
                                    ? 'Cargando contacto...'
                                    : 'Contactar por email',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(Map<String, String> faq) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      title: Text(
        faq['question']!,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [Text(faq['answer']!, style: const TextStyle(height: 1.5))],
    ),
  );
}
