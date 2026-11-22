import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';

class ConstanciaReservaView extends StatefulWidget {
  const ConstanciaReservaView({super.key, required this.reservaId});
  final int reservaId;

  @override
  State<ConstanciaReservaView> createState() => _ConstanciaReservaViewState();
}

class _ConstanciaReservaViewState extends State<ConstanciaReservaView> {
  late final Future<Map<String, dynamic>> _constancia = _load();

  Future<Map<String, dynamic>> _load() async {
    final result = await Supabase.instance.client.rpc(
      'constancia_reserva',
      params: {'p_reserva_id': widget.reservaId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  String _date(dynamic value, {bool time = true}) {
    if (value == null) return 'No registrada';
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return '$value';
    return DateFormat(
      time ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy',
    ).format(time ? parsed.toLocal() : parsed);
  }

  String _hour(dynamic value) {
    final text = '$value';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  @override
  Widget build(BuildContext context) {
    final background = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Constancia de reserva'),
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
          FutureBuilder<Map<String, dynamic>>(
            future: _constancia,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No se pudo consultar la constancia: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              final amount = (data['monto'] as num?)?.toDouble();
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GameOn · Constancia de reserva',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Registro informativo. No es boleta ni factura.',
                          ),
                          const Divider(height: 28),
                          _row('Código', 'Reserva #${data['id']}'),
                          _row(
                            'Cliente',
                            '${data['cliente'] ?? 'No registrado'}',
                          ),
                          _row(
                            'Centro deportivo',
                            '${data['centro'] ?? 'No registrado'}',
                          ),
                          _row(
                            'Cancha',
                            '${data['cancha'] ?? 'No registrada'}',
                          ),
                          _row('Fecha', _date(data['fecha'], time: false)),
                          _row(
                            'Horario',
                            '${_hour(data['hora_inicio'])} – ${_hour(data['hora_fin'])}',
                          ),
                          _row(
                            'Monto registrado',
                            amount == null
                                ? 'No registrado'
                                : 'S/ ${amount.toStringAsFixed(2)}',
                          ),
                          _row(
                            'Método de pago',
                            '${data['metodo'] ?? 'No registrado'}',
                          ),
                          _row(
                            'Estado',
                            '${data['estado'] ?? 'No registrado'}',
                          ),
                          _row(
                            'Fecha de registro',
                            _date(data['registrado_en']),
                          ),
                          _row(
                            'Fecha de aprobación',
                            _date(data['aprobado_en']),
                          ),
                          _row(
                            'Gestor responsable',
                            '${data['gestor_responsable'] ?? 'No registrado'}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: Text(value)),
      ],
    ),
  );
}
