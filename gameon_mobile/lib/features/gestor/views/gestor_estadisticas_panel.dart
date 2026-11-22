import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GestorEstadisticasPanel extends StatefulWidget {
  const GestorEstadisticasPanel({
    super.key,
    required this.centros,
    required this.refreshToken,
  });
  final List<Map<String, dynamic>> centros;
  final int refreshToken;

  @override
  State<GestorEstadisticasPanel> createState() =>
      _GestorEstadisticasPanelState();
}

class _GestorEstadisticasPanelState extends State<GestorEstadisticasPanel> {
  DateTime inicio = DateUtils.dateOnly(
    DateTime.now().subtract(const Duration(days: 6)),
  );
  DateTime fin = DateUtils.dateOnly(DateTime.now());
  int? centroId;
  Map<String, dynamic>? datos;
  String? error;
  bool cargando = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant GestorEstadisticasPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  String _sqlDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  String _money(dynamic value) => _number(value).toStringAsFixed(2);
  List<Map<String, dynamic>> _rows(String key) => (datos?[key] as List? ?? [])
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_request;
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final response = await Supabase.instance.client.rpc(
        'gestor_estadisticas',
        params: {
          'p_inicio': _sqlDate(inicio),
          'p_fin': _sqlDate(fin),
          'p_centro_id': centroId,
        },
      );
      if (mounted && request == _request) {
        setState(() => datos = Map<String, dynamic>.from(response as Map));
      }
    } catch (e) {
      if (mounted && request == _request) {
        setState(() => error = 'No se pudieron cargar las estadísticas: $e');
      }
    } finally {
      if (mounted && request == _request) setState(() => cargando = false);
    }
  }

  void _range(int days) {
    setState(() {
      fin = DateUtils.dateOnly(DateTime.now());
      inicio = fin.subtract(Duration(days: days - 1));
    });
    _load();
  }

  Future<void> _custom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: inicio, end: fin),
    );
    if (picked == null || !mounted) return;
    setState(() {
      inicio = DateUtils.dateOnly(picked.start);
      fin = DateUtils.dateOnly(picked.end);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final methods = _rows('por_metodo');
    final days = _rows('por_dia');
    final centers = _rows('por_institucion');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ingresos y actividad',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        const Text(
          'Reservas confirmadas, completadas o pagadas. Los importes antiguos sin monto registrado se estiman con la tarifa actual.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Última semana'),
                      selected:
                          fin.difference(inicio).inDays == 6 &&
                          fin == DateUtils.dateOnly(DateTime.now()),
                      onSelected: (_) => _range(7),
                    ),
                    ChoiceChip(
                      label: const Text('Último mes'),
                      selected:
                          fin.difference(inicio).inDays == 29 &&
                          fin == DateUtils.dateOnly(DateTime.now()),
                      onSelected: (_) => _range(30),
                    ),
                    OutlinedButton.icon(
                      onPressed: _custom,
                      icon: const Icon(Icons.date_range),
                      label: const Text('Personalizado'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  key: ValueKey(centroId),
                  initialValue: centroId,
                  decoration: const InputDecoration(
                    labelText: 'Complejo deportivo',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos mis complejos'),
                    ),
                    ...widget.centros.map(
                      (c) => DropdownMenuItem<int?>(
                        value: (c['id'] as num).toInt(),
                        child: Text(
                          '${c['nombre']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => centroId = value);
                    _load();
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  '${_sqlDate(inicio)} al ${_sqlDate(fin)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (cargando) const LinearProgressIndicator(),
        if (error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Text(error!),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              ),
            ),
          ),
        if (datos != null && error == null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: color.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Ingresos registrados para el gestor'),
                  ),
                  Text(
                    'S/ ${_money(datos!['ingresos'])}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${datos!['reservas'] ?? 0} reservas cobradas en este periodo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          _methods(methods),
          _daily(days),
          if (centroId == null) _centers(centers),
        ],
      ],
    );
  }

  Widget _methods(List<Map<String, dynamic>> rows) {
    final max = rows.fold<double>(
      0,
      (v, row) => math.max(v, _number(row['monto'])),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos por método de pago',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Text('Sin pagos registrados en este periodo.'),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${row['metodo']} · ${row['reservas']} reservas',
                          ),
                        ),
                        Text('S/ ${_money(row['monto'])}'),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: max == 0 ? 0 : _number(row['monto']) / max,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _daily(List<Map<String, dynamic>> rows) {
    final max = rows.fold<double>(
      0,
      (v, row) => math.max(v, _number(row['monto'])),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos por día',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Text('Sin actividad en este periodo.')
            else
              SizedBox(
                height: 170,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: rows
                        .map(
                          (row) => SizedBox(
                            width: 50,
                            child: Tooltip(
                              message:
                                  '${row['fecha']} · S/ ${_money(row['monto'])} · ${row['reservas']} reservas',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    _money(row['monto']),
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 28,
                                    height: max == 0
                                        ? 4
                                        : math.max(
                                            4,
                                            105 * _number(row['monto']) / max,
                                          ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${row['fecha']}'.substring(5),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _centers(List<Map<String, dynamic>> rows) {
    final total = rows.fold<double>(
      0,
      (sum, row) => sum + _number(row['reservas']),
    );
    final max = rows.fold<double>(
      0,
      (v, row) => math.max(v, _number(row['monto'])),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos por complejo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Text('Sin reservas cobradas en los complejos.')
            else ...[
              Text(
                'Participación por reservas',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 125,
                    height: 125,
                    child: CustomPaint(
                      painter: _GestorDonutPainter(rows: rows, total: total),
                      child: Center(
                        child: Text(
                          '${total.toInt()}\nreservas',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rows
                          .take(5)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 9,
                                    height: 9,
                                    color:
                                        _GestorDonutPainter.colors[entry.key %
                                            _GestorDonutPainter.colors.length],
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      '${entry.value['institucion']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text('${entry.value['reservas']}'),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Monto por complejo',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${row['institucion']} · ${row['reservas']} reservas',
                      ),
                      Text('S/ ${_money(row['monto'])}'),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: max == 0 ? 0 : _number(row['monto']) / max,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GestorDonutPainter extends CustomPainter {
  const _GestorDonutPainter({required this.rows, required this.total});
  final List<Map<String, dynamic>> rows;
  final double total;
  static const colors = [
    Color(0xFF1479D1),
    Color(0xFF1A9D67),
    Color(0xFFF1A62E),
    Color(0xFF8C5BDE),
    Color(0xFFE05D5D),
    Color(0xFF3F9CB8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final rect = Offset.zero & size;
    var start = -math.pi / 2;
    for (var index = 0; index < rows.length; index++) {
      final value = (rows[index]['reservas'] as num?)?.toDouble() ?? 0;
      final sweep = 2 * math.pi * value / total;
      canvas.drawArc(
        rect.deflate(10),
        start,
        sweep,
        false,
        Paint()
          ..color = colors[index % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _GestorDonutPainter oldDelegate) =>
      oldDelegate.rows != rows || oldDelegate.total != total;
}
