import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';
import 'package:gameon/core/theme/visual_theme_picker.dart';
import 'package:gameon/core/widgets/role_switcher.dart';
import '../../perfil/viewmodels/perfil_viewmodel.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class AdminUserDetailView extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminUserDetailView({super.key, required this.user});

  @override
  State<AdminUserDetailView> createState() => _AdminUserDetailViewState();
}

class _AdminUserDetailViewState extends State<AdminUserDetailView> {
  Map<String, dynamic>? detail;
  Map<int, Map<String, dynamic>> centerStats = {};
  DateTime statsStart = DateUtils.dateOnly(
    DateTime.now().subtract(const Duration(days: 29)),
  );
  DateTime statsEnd = DateUtils.dateOnly(DateTime.now());
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await Supabase.instance.client.rpc(
        'admin_detalle_usuario',
        params: {'p_usuario_id': widget.user['id']},
      );
      final loaded = value == null
          ? null
          : Map<String, dynamic>.from(value as Map);
      final stats = <int, Map<String, dynamic>>{};
      if (loaded != null) {
        final managers = _rows(loaded['gestor']);
        final jobs = <Future<void>>[];
        for (final manager in managers) {
          for (final center in _rows(manager['centros'])) {
            jobs.add(() async {
              final response = await Supabase.instance.client.rpc(
                'admin_estadisticas_centro',
                params: {
                  'p_gestor_id': manager['id'],
                  'p_centro_id': center['id'],
                  'p_inicio': _dateSql(statsStart),
                  'p_fin': _dateSql(statsEnd),
                },
              );
              stats[center['id'] as int] = Map<String, dynamic>.from(
                response as Map,
              );
            }());
          }
        }
        await Future.wait(jobs);
      }
      if (mounted)
        setState(() {
          detail = loaded;
          centerStats = stats;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  List<Map<String, dynamic>> _rows(dynamic value) => (value as List? ?? [])
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();

  String _dateSql(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _money(dynamic value) =>
      ((value is num ? value.toDouble() : double.tryParse('$value')) ?? 0)
          .toStringAsFixed(2);

  Future<void> _setCenterRange(Duration? duration) async {
    setState(() {
      statsEnd = DateUtils.dateOnly(DateTime.now());
      statsStart = duration == null
          ? DateTime(2020)
          : statsEnd.subtract(duration);
      detail = detail;
    });
    await _load();
  }

  Future<void> _customCenterRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: statsStart, end: statsEnd),
    );
    if (picked == null || !mounted) return;
    setState(() {
      statsStart = DateUtils.dateOnly(picked.start);
      statsEnd = DateUtils.dateOnly(picked.end);
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    final name = '${widget.user['nombre'] ?? 'Usuario'}'.trim();
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(
                    alpha: background == null ? 1 : .80,
                  ),
                  colors.primaryContainer.withValues(
                    alpha: background == null ? 1 : .85,
                  ),
                ],
              ),
              image: background == null
                  ? null
                  : DecorationImage(
                      image: AssetImage(background),
                      fit: BoxFit.cover,
                      opacity: .42,
                    ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 20, 18),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FICHA DE USUARIO',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            name.isEmpty ? 'Usuario' : name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
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
            child: detail == null
                ? Center(
                    child: error == null
                        ? const CircularProgressIndicator()
                        : Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(error!, textAlign: TextAlign.center),
                          ),
                  )
                : _content(),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    final managers = _rows(detail!['gestor']);
    final reservations = _rows(detail!['reservas']);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('${widget.user['username'] ?? '—'}'),
            subtitle: Text(
              '${widget.user['telefono'] ?? 'Sin teléfono'} · ${widget.user['estado'] == 1 ? 'Cuenta activa' : 'Cuenta desactivada'}',
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (managers.isNotEmpty) ...[
          Text(
            'Instalaciones deportivas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text('Indicadores por institución:'),
                  ChoiceChip(
                    label: const Text('Semana'),
                    selected: statsEnd.difference(statsStart).inDays == 6,
                    onSelected: (_) => _setCenterRange(const Duration(days: 6)),
                  ),
                  ChoiceChip(
                    label: const Text('Mes'),
                    selected: statsEnd.difference(statsStart).inDays == 29,
                    onSelected: (_) =>
                        _setCenterRange(const Duration(days: 29)),
                  ),
                  ChoiceChip(
                    label: const Text('Todo'),
                    selected: statsStart.year == 2020,
                    onSelected: (_) => _setCenterRange(null),
                  ),
                  OutlinedButton.icon(
                    onPressed: _customCenterRange,
                    icon: const Icon(Icons.tune),
                    label: const Text('Personalizado'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...managers.expand((manager) => _managerCards(manager)),
        ] else ...[
          Text(
            'Historial de reservas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (reservations.isEmpty)
            const Card(
              child: ListTile(
                title: Text(
                  'Este deportista aún no tiene reservas registradas',
                ),
              ),
            ),
          ...reservations.map(
            (item) => Card(
              child: ListTile(
                leading: const Icon(Icons.sports_soccer),
                title: Text('${item['cancha']} · ${item['complejo']}'),
                subtitle: Text(
                  '${item['fecha']} ${item['inicio']}–${item['fin']}\n${item['direccion']} · ${item['metodo'] ?? 'Sin método'}',
                ),
                trailing: Text('${item['estado']}'),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _managerCards(Map<String, dynamic> manager) {
    final centers = _rows(manager['centros']);
    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.business_outlined),
          title: Text('${manager['nombre_negocio'] ?? 'Gestor'}'),
          subtitle: Text(
            'RUC: ${manager['ruc'] ?? '—'} · ${manager['estado'] == 1 ? 'Activo' : 'Pendiente'}',
          ),
        ),
      ),
      if (centers.isEmpty)
        const Card(
          child: ListTile(title: Text('No tiene complejos aprobados todavía')),
        ),
      ...centers.map((center) {
        final courts = _rows(center['canchas']);
        final stat = centerStats[center['id'] as int] ?? {};
        final methods = _rows(stat['por_metodo']);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${center['nombre']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${center['direccion']}'),
                Text('Ubicación: ${center['latitud']}, ${center['longitud']}'),
                if ('${center['telefono'] ?? ''}'.isNotEmpty)
                  Text('Teléfono: ${center['telefono']}'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ingresos registrados',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${stat['reservas'] ?? 0} reservas cobradas · ${_dateSql(statsStart)} a ${_dateSql(statsEnd)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'S/ ${_money(stat['ingresos'])}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                if (methods.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      children: methods
                          .map(
                            (method) => Chip(
                              label: Text(
                                '${method['metodo']}: S/ ${_money(method['monto'])}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Canchas',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if (courts.isEmpty) const Text('No hay canchas registradas.'),
                ...courts.map(
                  (court) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.sports_soccer),
                    title: Text('${court['nombre']}'),
                    subtitle: Text(
                      '${court['deporte'] ?? 'Deporte'} · S/ ${court['tarifa'] ?? 0}/h · ${court['estado']}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }
}

class _AdminViewState extends State<AdminView> {
  final db = Supabase.instance.client;
  final supportEmail = TextEditingController();
  final welcomeMessage = TextEditingController();
  int tab = 0;
  DateTime rangeStart = DateUtils.dateOnly(
    DateTime.now().subtract(const Duration(days: 6)),
  );
  DateTime rangeEnd = DateUtils.dateOnly(DateTime.now());
  String userSearch = '';
  String userType = 'Todos';
  bool loading = true;
  String? error;
  Map<String, dynamic> summary = {};
  Map<String, dynamic> statistics = {};
  List<Map<String, dynamic>> centerRequests = [];
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> audit = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    supportEmail.dispose();
    welcomeMessage.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _rows(dynamic value) => (value as List? ?? [])
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        db.rpc('admin_resumen'),
        db.rpc('admin_solicitudes_centros'),
        db.rpc('admin_usuarios'),
        db.rpc('admin_reclamos'),
        db.rpc('admin_auditoria'),
        db.from('configuracion_general').select('clave,valor'),
        db.rpc(
          'admin_estadisticas',
          params: {
            'p_inicio': _dateSql(rangeStart),
            'p_fin': _dateSql(rangeEnd),
          },
        ),
      ]);
      final config = _rows(results[5]);
      if (!mounted) return;
      setState(() {
        summary = results[0] is Map
            ? Map<String, dynamic>.from(results[0] as Map)
            : {};
        centerRequests = _rows(results[1]);
        users = _rows(results[2]);
        complaints = _rows(results[3]);
        audit = _rows(results[4]);
        statistics = results[6] is Map
            ? Map<String, dynamic>.from(results[6] as Map)
            : {};
        supportEmail.text =
            config
                .where((x) => x['clave'] == 'soporte_email')
                .firstOrNull?['valor']
                ?.toString() ??
            '';
        welcomeMessage.text =
            config
                .where((x) => x['clave'] == 'mensaje_bienvenida')
                .firstOrNull?['valor']
                ?.toString() ??
            '';
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _dateSql(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _action(Future<void> Function() task, String done) async {
    // Se conserva el messenger antes de la operación asíncrona: el árbol puede
    // reconstruirse al guardar y ya no es seguro buscarlo con este context.
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await task();
      if (!mounted) return;
      await _load();
      if (messenger?.mounted ?? false) {
        messenger!
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(done), behavior: SnackBarBehavior.floating),
          );
      }
    } catch (e) {
      if (messenger?.mounted ?? false) {
        messenger!
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('No se pudo guardar el cambio: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  Future<void> _resolveCenter(
    Map<String, dynamic> request,
    bool approve,
  ) async {
    final note = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Aprobar complejo' : 'Rechazar complejo'),
        content: TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Observación para el solicitante',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(approve ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await _action(
      () => db.rpc(
        'resolver_solicitud_centro',
        params: {
          'p_id': request['id'],
          'p_aprobar': approve,
          'p_observacion': note.text,
        },
      ),
      approve ? 'Complejo aprobado' : 'Complejo rechazado',
    );
  }

  Future<void> _viewFile(String path) async {
    try {
      final url = await db.storage
          .from('gestor-solicitudes')
          .createSignedUrl(path, 300);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Evidencia adjunta'),
          content: SizedBox(
            width: 360,
            height: 420,
            child: Image.network(url, fit: BoxFit.contain),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el archivo: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<PerfilViewModel>();
    if (!profile.isAdmin)
      return const Scaffold(body: Center(child: Text('Acceso denegado')));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: background == null ? 1 : .8),
                  colors.primaryContainer.withValues(
                    alpha: background == null ? 1 : .85,
                  ),
                ],
              ),
              image: background == null
                  ? null
                  : DecorationImage(
                      image: AssetImage(background),
                      fit: BoxFit.cover,
                      opacity: .42,
                    ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administración',
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Centro de control GameOn',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VisualThemePicker(iconColor: Colors.white),
                    const RoleSwitcher(),
                    IconButton(
                      onPressed: loading ? null : _load,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: IndexedStack(
              index: tab,
              children: [
                _dashboard(),
                _affiliations(),
                _users(),
                _complaints(),
                _audit(),
                _settings(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Afiliaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Reclamos',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Auditoría',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final cards = [
      ('Deportistas activos', 'deportistas', Icons.directions_run),
      ('Gestores de canchas', 'gestores', Icons.business_outlined),
      ('Complejos afiliados', 'complejos', Icons.domain_outlined),
      ('Canchas activas', 'canchas', Icons.sports_soccer),
    ];
    final methodRows = _rows(statistics['por_metodo']);
    final dailyRows = _rows(statistics['por_dia']);
    final institutionRows = _rows(statistics['por_institucion']);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Resumen de operación',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Indicadores consolidados de reservas cobradas e ingresos de gestores.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (c) => SizedBox(
                    width: 165,
                    child: _metric(c.$1, '${statistics[c.$2] ?? 0}', c.$3),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          _rangeSelector(),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ingresos registrados para gestores',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Reservas cobradas entre ${_dateSql(rangeStart)} y ${_dateSql(rangeEnd)}',
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'S/ ${_money(statistics['ingresos_gestores'])}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _methodChart(methodRows),
          const SizedBox(height: 12),
          _institutionDonut(institutionRows),
          const SizedBox(height: 12),
          _dailyChart(dailyRows),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Pendientes administrativos'),
              subtitle: Text(
                '${statistics['solicitudes_pendientes'] ?? 0} solicitudes de afiliación y ${statistics['reclamos_abiertos'] ?? 0} reclamos requieren atención.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;
    return number.toStringAsFixed(2);
  }

  Widget _rangeSelector() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.date_range_outlined),
          ChoiceChip(
            label: const Text('Última semana'),
            selected: rangeEnd.difference(rangeStart).inDays == 6,
            onSelected: (_) {
              setState(() {
                rangeEnd = DateUtils.dateOnly(DateTime.now());
                rangeStart = rangeEnd.subtract(const Duration(days: 6));
              });
              _load();
            },
          ),
          ChoiceChip(
            label: const Text('Último mes'),
            selected: rangeEnd.difference(rangeStart).inDays == 29,
            onSelected: (_) {
              setState(() {
                rangeEnd = DateUtils.dateOnly(DateTime.now());
                rangeStart = rangeEnd.subtract(const Duration(days: 29));
              });
              _load();
            },
          ),
          ChoiceChip(
            label: const Text('Todo el historial'),
            selected: rangeStart.year == 2020,
            onSelected: (_) {
              setState(() {
                rangeStart = DateTime(2020);
                rangeEnd = DateUtils.dateOnly(DateTime.now());
              });
              _load();
            },
          ),
          OutlinedButton.icon(
            onPressed: _chooseRange,
            icon: const Icon(Icons.tune),
            label: const Text('Personalizado'),
          ),
        ],
      ),
    ),
  );

  Future<void> _chooseRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: rangeStart, end: rangeEnd),
    );
    if (picked == null || !mounted) return;
    setState(() {
      rangeStart = DateUtils.dateOnly(picked.start);
      rangeEnd = DateUtils.dateOnly(picked.end);
    });
    await _load();
  }

  Widget _methodChart(List<Map<String, dynamic>> rows) {
    final max = rows.fold<double>(
      0,
      (value, item) =>
          (item['monto'] is num
                  ? (item['monto'] as num).toDouble()
                  : double.tryParse('${item['monto']}') ?? 0) >
              value
          ? (item['monto'] is num
                ? (item['monto'] as num).toDouble()
                : double.tryParse('${item['monto']}') ?? 0)
          : value,
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
            const SizedBox(height: 14),
            if (rows.isEmpty)
              const Text('No hay reservas cobradas en este rango.')
            else
              ...rows.map((item) {
                final amount = item['monto'] is num
                    ? (item['monto'] as num).toDouble()
                    : double.tryParse('${item['monto']}') ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item['metodo']} · ${item['reservas']} reservas',
                            ),
                          ),
                          Text('S/ ${_money(amount)}'),
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: max == 0 ? 0 : amount / max,
                        minHeight: 9,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _dailyChart(List<Map<String, dynamic>> rows) {
    final max = rows.fold<int>(
      0,
      (value, item) =>
          (item['reservas'] is num
                  ? (item['reservas'] as num).toInt()
                  : int.tryParse('${item['reservas']}') ?? 0) >
              value
          ? (item['reservas'] is num
                ? (item['reservas'] as num).toInt()
                : int.tryParse('${item['reservas']}') ?? 0)
          : value,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Picos de reservas cobradas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text('Días con reservas dentro del rango elegido.'),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              const Text('Aún no hay actividad para graficar.')
            else
              SizedBox(
                height: 155,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: rows.take(14).map((item) {
                    final count = item['reservas'] is num
                        ? (item['reservas'] as num).toInt()
                        : int.tryParse('${item['reservas']}') ?? 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Tooltip(
                          message: '${item['fecha']}: $count reservas',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '$count',
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                height: max == 0 ? 4 : 100 * count / max,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['fecha']}'.substring(5),
                                style: const TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _institutionDonut(List<Map<String, dynamic>> rows) {
    final total = rows.fold<double>(
      0,
      (sum, row) =>
          sum +
          (row['reservas'] is num
              ? (row['reservas'] as num).toDouble()
              : double.tryParse('${row['reservas']}') ?? 0),
    );
    const colors = [
      Color(0xFF1479D1),
      Color(0xFF1A9D67),
      Color(0xFFF1A62E),
      Color(0xFF8C5BDE),
      Color(0xFFE05D5D),
      Color(0xFF3F9CB8),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instituciones con más reservas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            const Text(
              'Participación por cantidad de reservas cobradas en el rango elegido.',
            ),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              const Text('No hay reservas cobradas para mostrar instituciones.')
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 142,
                    height: 142,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        rows: rows,
                        total: total,
                        colors: colors,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${total.toInt()}'),
                            const Text(
                              'reservas',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: rows
                          .take(colors.length)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                            final row = entry.value;
                            final visits = row['reservas'] is num
                                ? (row['reservas'] as num).toInt()
                                : int.tryParse('${row['reservas']}') ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: colors[entry.key],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${row['institucion']}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text('$visits'),
                                ],
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, maxLines: 2),
        ],
      ),
    ),
  );

  Widget _affiliations() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'Afiliaciones de negocios',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Valida los datos del complejo y sus evidencias antes de habilitarlo.',
        ),
        const SizedBox(height: 16),
        if (centerRequests.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('No hay solicitudes de complejos'),
            ),
          ),
        ...centerRequests.map(_centerRequestCard),
      ],
    ),
  );

  Widget _centerRequestCard(Map<String, dynamic> item) {
    final pending = item['estado'] == 'pendiente';
    final evidence = item['evidencias'] as List? ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item['nombre']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text('RUC: ${item['ruc']}'),
            Text('${item['direccion']}'),
            if ('${item['telefono'] ?? ''}'.isNotEmpty)
              Text('Teléfono: ${item['telefono']}'),
            if ('${item['email'] ?? ''}'.isNotEmpty)
              Text('Correo: ${item['email']}'),
            if ('${item['descripcion'] ?? ''}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${item['descripcion']}'),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('${item['estado']}')),
                Chip(
                  avatar: const Icon(Icons.location_on_outlined, size: 16),
                  label: Text('${item['latitud']}, ${item['longitud']}'),
                ),
              ],
            ),
            if (item['imagen_ruta'] != null)
              TextButton.icon(
                onPressed: () => _viewFile('${item['imagen_ruta']}'),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Ver imagen principal'),
              ),
            for (final path in evidence)
              TextButton.icon(
                onPressed: () => _viewFile('$path'),
                icon: const Icon(Icons.attach_file),
                label: Text('$path'.split('/').last),
              ),
            if (pending)
              Row(
                children: [
                  TextButton(
                    onPressed: () => _resolveCenter(item, false),
                    child: const Text('Rechazar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: evidence.isEmpty
                        ? null
                        : () => _resolveCenter(item, true),
                    child: const Text('Aprobar'),
                  ),
                ],
              )
            else if ('${item['observacion'] ?? ''}'.isNotEmpty)
              Text('Observación: ${item['observacion']}'),
          ],
        ),
      ),
    );
  }

  Widget _users() {
    final filtered = users.where((u) {
      final isManager = u['es_gestor'] == true;
      final matchesType =
          userType == 'Todos' ||
          (userType == 'Gestor de Canchas' ? isManager : !isManager);
      final haystack =
          '${u['nombre'] ?? ''} ${u['username'] ?? ''} ${u['telefono'] ?? ''}'
              .toLowerCase();
      return matchesType && haystack.contains(userSearch.toLowerCase());
    }).toList();
    final athletes = users.where((u) => u['es_gestor'] != true).length;
    final managers = users.where((u) => u['es_gestor'] == true).length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Usuarios y roles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Toca una cuenta para ver su historial o sus instalaciones.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Deportistas',
                  '$athletes',
                  Icons.directions_run,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metric(
                  'Gestores de canchas',
                  '$managers',
                  Icons.business,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => userSearch = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar por nombre, usuario o teléfono',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: userType,
            decoration: const InputDecoration(labelText: 'Tipo de usuario'),
            items: const ['Todos', 'Deportista', 'Gestor de Canchas']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => userType = value ?? 'Todos'),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Botones: persona tachada/activa = desactivar o activar la cuenta. Escudo = asignar o retirar el acceso de administrador del sistema.',
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (filtered.isEmpty)
            const Card(
              child: ListTile(title: Text('No se encontraron usuarios')),
            ),
          ...filtered.map((u) {
            final name = '${u['nombre'] ?? 'Usuario'}'.trim();
            final active = u['estado'] == 1;
            final admin = u['es_admin'] == true;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(name.isEmpty ? 'U' : name[0].toUpperCase()),
                ),
                title: Text(name.isEmpty ? 'Usuario' : name),
                subtitle: Text(
                  '@${u['username'] ?? '—'} · ${u['es_gestor'] == true ? 'Gestor' : 'Deportista'}${admin ? ' · Admin' : ''}',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminUserDetailView(user: u),
                  ),
                ),
                trailing: Wrap(
                  spacing: 2,
                  children: [
                    IconButton(
                      tooltip: active ? 'Desactivar' : 'Activar',
                      onPressed: () => _action(
                        () => db.rpc(
                          'admin_cambiar_estado_usuario',
                          params: {'p_id': u['id'], 'p_activo': !active},
                        ),
                        active ? 'Cuenta desactivada' : 'Cuenta activada',
                      ),
                      icon: Icon(
                        active
                            ? Icons.person_off_outlined
                            : Icons.person_add_alt_1_outlined,
                      ),
                    ),
                    IconButton(
                      tooltip: admin
                          ? 'Retirar administrador'
                          : 'Asignar administrador',
                      onPressed: () => _action(
                        () => db.rpc(
                          'admin_asignar_administrador',
                          params: {
                            'p_auth_id': u['auth_id'],
                            'p_activo': !admin,
                          },
                        ),
                        admin
                            ? 'Rol administrador retirado'
                            : 'Rol administrador asignado',
                      ),
                      icon: Icon(
                        admin
                            ? Icons.admin_panel_settings
                            : Icons.admin_panel_settings_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _complaints() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'Reclamos y atención',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (complaints.isEmpty)
          const Card(
            child: ListTile(title: Text('No hay reclamos registrados')),
          ),
        ...complaints.map(
          (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent),
              title: Text('${item['tipo']} #${item['id']} · ${item['nombre']}'),
              subtitle: Text('${item['detalle']}\nEstado: ${item['estado']}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _replyComplaint(item),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _replyComplaint(Map<String, dynamic> item) async {
    final reply = TextEditingController(text: '${item['respuesta'] ?? ''}');
    var status = '${item['estado']}';
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${item['tipo']} #${item['id']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${item['detalle']}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items:
                      const ['recibido', 'en_revision', 'respondido', 'cerrado']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (value) => setDialogState(() => status = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reply,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Respuesta'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (save == true)
      await _action(
        () => db.rpc(
          'admin_resolver_reclamo',
          params: {
            'p_id': item['id'],
            'p_estado': status,
            'p_respuesta': reply.text,
          },
        ),
        'Reclamo actualizado',
      );
  }

  Widget _audit() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'Auditoría administrativa',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (audit.isEmpty)
          const Card(
            child: ListTile(title: Text('Aún no hay acciones registradas')),
          ),
        ...audit.map(
          (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text('${item['accion']}'),
              subtitle: Text(
                '${item['entidad']} #${item['entidad_id']}\n${item['creado_en']}',
              ),
              isThreeLine: true,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _settings() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Text(
        'Configuración general',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      const Text(
        'Solo parámetros visibles de la aplicación. No incluye credenciales ni pagos.',
      ),
      const SizedBox(height: 20),
      TextField(
        controller: supportEmail,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Correo de soporte',
          helperText:
              'Se usa en el botón “Contactar por email” de Ayuda y soporte.',
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: welcomeMessage,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'Mensaje de bienvenida'),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () => _action(() async {
          await db.rpc(
            'admin_guardar_configuracion',
            params: {'p_clave': 'soporte_email', 'p_valor': supportEmail.text},
          );
          await db.rpc(
            'admin_guardar_configuracion',
            params: {
              'p_clave': 'mensaje_bienvenida',
              'p_valor': welcomeMessage.text,
            },
          );
        }, 'Configuración guardada'),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Guardar cambios'),
      ),
    ],
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.rows,
    required this.total,
    required this.colors,
  });

  final List<Map<String, dynamic>> rows;
  final double total;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 21.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    var start = -math.pi / 2;
    for (var index = 0; index < rows.length; index++) {
      final raw = rows[index]['reservas'];
      final value = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
      final sweep = total <= 0 ? 0.0 : (value / total) * math.pi * 2;
      paint.color = colors[index % colors.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.rows != rows || oldDelegate.total != total;
}
