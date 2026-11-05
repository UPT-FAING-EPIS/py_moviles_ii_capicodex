import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import '../services/gestor_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'centro_ubicacion_picker.dart';

class GestorView extends StatefulWidget {
  final int managerId;
  const GestorView({super.key, required this.managerId});

  @override
  State<GestorView> createState() => _GestorViewState();
}

class _GestorViewState extends State<GestorView> {
  final service = GestorService();
  ScaffoldMessengerState? _messenger;
  int tab = 0;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> centros = [],
      areas = [],
      reservas = [],
      deportes = [];
  DateTime fecha = DateTime.now();
  String search = '';
  int? centroFiltro;
  int? reservaCentroFiltro, reservaDeporteFiltro;
  String? reservaEstadoFiltro;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  String get fechaSql =>
      '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  int asInt(dynamic value) =>
      value is num ? value.toInt() : int.parse('$value');
  String centroNombre(int id) =>
      centros
          .where((c) => c['id'] == id)
          .map((c) => '${c['nombre']}')
          .firstOrNull ??
      'Centro #$id';
  String areaNombre(int id) =>
      areas
          .where((a) => a['id'] == id)
          .map((a) => '${a['nombre_area']}')
          .firstOrNull ??
      'Área #$id';

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final c = await service.centros(widget.managerId);
      final a = await service.areas(c.map((e) => asInt(e['id'])).toList());
      final r = await service.reservas(
        a.map((e) => asInt(e['id'])).toList(),
        fecha: fechaSql,
      );
      final d = await service.deportes();
      if (!mounted) return;
      setState(() {
        centros = c;
        areas = a;
        reservas = r;
        deportes = d;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  Future<void> action(Future<void> Function() operation) async {
    // El messenger se obtuvo mientras esta vista estaba activa. El diálogo
    // puede desmontarse durante la escritura y no se consulta su contexto.
    final messenger = _messenger;
    try {
      await operation();
      if (!mounted) return;
      await refresh();
      if (messenger?.mounted ?? false) {
        messenger!.showSnackBar(
          const SnackBar(content: Text('Cambios guardados')),
        );
      }
    } catch (e) {
      if (messenger?.mounted ?? false) {
        messenger!.showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bg = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    final titles = [
      'Tu espacio deportivo',
      'Mis centros',
      'Mis canchas',
      'Mis reservas',
      'Mi cuenta',
    ];
    final subtitles = [
      'Controla tu negocio en un solo lugar',
      'Administra tus instalaciones',
      'Organiza tus espacios de juego',
      'Revisa la actividad de tus canchas',
      'Personaliza tu experiencia',
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight * 2,
        titleSpacing: 24,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GAMEON · GESTOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: Colors.white.withValues(alpha: .82),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              titles[tab],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitles[tab],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: .86),
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, colors.primaryContainer],
            ),
            image: bg == null
                ? null
                : DecorationImage(
                    image: AssetImage(bg),
                    fit: BoxFit.cover,
                    opacity: .42,
                  ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filledTonal(
              tooltip: 'Actualizar',
              onPressed: refresh,
              icon: const Icon(Icons.refresh, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .18),
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : IndexedStack(
              index: tab,
              children: [
                _dashboard(theme),
                _centros(),
                _areas(),
                _reservas(),
                _cuenta(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            label: 'Centros',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            label: 'Canchas',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }

  Widget _dashboard(ThemeData theme) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      _sectionTitle('Resumen de hoy', 'Así va tu negocio deportivo'),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _stat('Centros', centros.length, Icons.business)),
          Expanded(child: _stat('Canchas', areas.length, Icons.sports_soccer)),
          Expanded(
            child: _stat('Reservas', reservas.length, Icons.calendar_today),
          ),
        ],
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => setState(() => tab = 1),
        icon: const Icon(Icons.add),
        label: const Text('Gestionar centros'),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () => setState(() => tab = 2),
        icon: const Icon(Icons.edit_calendar),
        label: const Text('Gestionar canchas y horarios'),
      ),
      const SizedBox(height: 28),
      _sectionTitle('Reservas de hoy', 'Tus próximos turnos y pagos'),
      const SizedBox(height: 12),
      if (reservas.isEmpty)
        _empty('Sin reservas por hoy', Icons.event_available_outlined),
      ...reservas.take(5).map(_reservaCard),
    ],
  );

  Widget _stat(String title, int count, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: colors.secondary.withValues(alpha: .17),
              child: Icon(icon, color: colors.secondary),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurface.withValues(alpha: .78),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centros() {
    final filtered = centros
        .where(
          (c) => '${c['nombre']}'.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _sectionTitle(
          'Tus centros',
          '${centros.length} instalaciones registradas',
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar centro...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => search = v),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _centroDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo centro'),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          _empty('Todavía no hay centros', Icons.business_outlined),
        ...filtered.map(_centroCard),
      ],
    );
  }

  Widget _areas() {
    final visible = areas
        .where(
          (a) =>
              centroFiltro == null ||
              a['institucion_deportiva_id'] == centroFiltro,
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _sectionTitle('Tus canchas', '${areas.length} espacios deportivos'),
        const SizedBox(height: 18),
        DropdownButtonFormField<int?>(
          initialValue: centroFiltro,
          decoration: const InputDecoration(labelText: 'Filtrar por centro'),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
            ...centros.map(
              (c) => DropdownMenuItem<int?>(
                value: asInt(c['id']),
                child: Text('${c['nombre']}'),
              ),
            ),
          ],
          onChanged: (v) => setState(() => centroFiltro = v),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: centros.isEmpty ? null : () => _areaDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Nueva cancha'),
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          _empty('Todavía no hay canchas', Icons.sports_soccer_outlined),
        ...visible.map(_areaCard),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: colors.onSurface.withValues(alpha: .7),
          ),
        ),
      ],
    );
  }

  Widget _empty(String text, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Icon(icon, size: 44, color: colors.secondary.withValues(alpha: .8)),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withValues(alpha: .75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail(dynamic image, IconData fallback) {
    final colors = Theme.of(context).colorScheme;
    final url = image?.toString() ?? '';
    Widget placeholder() => Container(
      color: colors.primary.withValues(alpha: .32),
      child: Icon(fallback, size: 32, color: colors.secondary),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 76,
        height: 76,
        child: url.isEmpty
            ? placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder(),
              ),
      ),
    );
  }

  Widget _priceTag(dynamic price) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        'S/ $price / hora',
        style: TextStyle(
          color: colors.secondary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _centroCard(Map<String, dynamic> c) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _centroDialog(c),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumbnail(c['imagen'], Icons.business_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c['nombre']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: colors.secondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${c['direccion']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 15,
                          color: colors.secondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${c['telefono']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _priceTag(c['tarifa']),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit_outlined, color: colors.secondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _areaCard(Map<String, dynamic> a) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _thumbnail(a['imagen_area'], Icons.sports_soccer_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a['nombre_area']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        centroNombre(asInt(a['institucion_deportiva_id'])),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: .72),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${a['deportes']?['nombre'] ?? ''} · ${a['estado']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      _priceTag(a['tarifa_por_hora']),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Editar cancha',
                  icon: Icon(Icons.edit_outlined, color: colors.secondary),
                  onPressed: () => _areaDialog(a),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _horariosDialog(a),
                icon: const Icon(Icons.schedule),
                label: const Text('Gestionar horarios'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reservas() {
    final filtered = reservas.where((r) {
      final area = areas
          .where((a) => a['id'] == r['area_deportiva_id'])
          .firstOrNull;
      if (area == null) return false;
      return (reservaCentroFiltro == null ||
              area['institucion_deportiva_id'] == reservaCentroFiltro) &&
          (reservaDeporteFiltro == null ||
              area['deporte_id'] == reservaDeporteFiltro) &&
          (reservaEstadoFiltro == null || r['estado'] == reservaEstadoFiltro);
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _sectionTitle(
          'Agenda de reservas',
          'Consulta los turnos de tus canchas',
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            title: Text('Fecha: $fechaSql'),
            subtitle: const Text('Toca para elegir otro día'),
            leading: Icon(
              Icons.calendar_month,
              color: Theme.of(context).colorScheme.secondary,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: fecha,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => fecha = picked);
                await refresh();
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          initialValue: reservaCentroFiltro,
          decoration: const InputDecoration(labelText: 'Centro'),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
            ...centros.map(
              (c) => DropdownMenuItem<int?>(
                value: asInt(c['id']),
                child: Text('${c['nombre']}'),
              ),
            ),
          ],
          onChanged: (v) => setState(() => reservaCentroFiltro = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          initialValue: reservaDeporteFiltro,
          decoration: const InputDecoration(labelText: 'Deporte'),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
            ...deportes.map(
              (d) => DropdownMenuItem<int?>(
                value: asInt(d['id']),
                child: Text('${d['nombre']}'),
              ),
            ),
          ],
          onChanged: (v) => setState(() => reservaDeporteFiltro = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: reservaEstadoFiltro,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
            ...[
              'pendiente',
              'confirmada',
              'cancelada',
              'completada',
            ].map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
          ],
          onChanged: (v) => setState(() => reservaEstadoFiltro = v),
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          _empty(
            'No hay reservas con estos filtros',
            Icons.event_available_outlined,
          ),
        ...filtered.map(_reservaCard),
      ],
    );
  }

  Widget _reservaCard(Map<String, dynamic> r) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.primary.withValues(alpha: .2),
              child: Icon(Icons.event_available, color: colors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    areaNombre(asInt(r['area_deportiva_id'])),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${r['fecha']} · ${r['hora_inicio']}–${r['hora_fin']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: .75),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${r['estado']} · S/ ${r['monto_pagado'] ?? '—'}',
                    style: TextStyle(
                      color: colors.secondary,
                      fontWeight: FontWeight.w700,
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

  Widget _cuenta() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      _sectionTitle('Perfil gestor', 'Tu cuenta y apariencia de la aplicación'),
      const SizedBox(height: 16),
      Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          title: Text(
            SupabaseEmail.email,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text('Cuenta gestora'),
        ),
      ),
      if (context.watch<PerfilViewModel>().hasAthleteProfile)
        Card(
          child: ListTile(
            leading: const Icon(Icons.directions_run),
            title: const Text('Cambiar a deportista'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.read<PerfilViewModel>().selectMode(
              AppUserMode.deportista,
            ),
          ),
        ),
      const SizedBox(height: 22),
      _sectionTitle('Tema de la aplicación', 'Elige el fondo que más te guste'),
      const SizedBox(height: 12),
      ...AppVisualTheme.values.map(
        (v) => ListTile(
          title: Text(switch (v) {
            AppVisualTheme.light => 'Claro',
            AppVisualTheme.dark => 'Oscuro',
            AppVisualTheme.football => 'Fútbol',
            AppVisualTheme.wimbledon => 'Tenis Wimbledon',
            AppVisualTheme.rolandGarros => 'Tenis Roland Garros',
            AppVisualTheme.usOpen => 'Tenis US Open',
            AppVisualTheme.volleyball => 'Vóley',
            AppVisualTheme.basketball => 'Básquet',
          }),
          selected: context.watch<ThemeController>().selection == v,
          trailing: context.watch<ThemeController>().selection == v
              ? const Icon(Icons.check)
              : null,
          onTap: () => context.read<ThemeController>().select(v),
        ),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => context.read<PerfilViewModel>().signOut(),
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar sesión'),
      ),
    ],
  );

  Future<void> _centroDialog([Map<String, dynamic>? c]) async {
    if (widget.managerId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solo un administrador autorizado puede registrar instalaciones.',
            ),
          ),
        );
      }
      return;
    }
    final fields = [
      'nombre',
      'ruc',
      'direccion',
      'tarifa',
      'telefono',
      'email',
      'descripcion',
      'imagen',
    ];
    final user = service.db.auth.currentUser;
    final initial = <String, dynamic>{
      if (c == null) ...{
        'nombre': user?.userMetadata?['nombre_institucion'],
        'ruc': user?.userMetadata?['ruc'],
        'email': user?.email,
      } else
        ...c,
    };
    final controllers = {
      for (final f in fields)
        f: TextEditingController(text: '${initial[f] ?? ''}'),
    };
    final key = GlobalKey<FormState>();
    var active = c?['estado'] != 0;
    final latitude = num.tryParse('${c?['latitud'] ?? ''}');
    final longitude = num.tryParse('${c?['longitud'] ?? ''}');
    LatLng? location = latitude == null || longitude == null
        ? null
        : LatLng(latitude.toDouble(), longitude.toDouble());
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: Text(c == null ? 'Nuevo centro' : 'Editar centro'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.sizeOf(ctx).height * .68,
            child: Form(
              key: key,
              child: ListView(
                children: [
                  for (final f in fields.where((item) => item != 'imagen')) ...[
                    TextFormField(
                      controller: controllers[f],
                      decoration: InputDecoration(
                        labelText: switch (f) {
                          'nombre' => 'Nombre del centro',
                          'ruc' => 'RUC',
                          'direccion' => 'Dirección',
                          'tarifa' => 'Tarifa por hora (S/)',
                          'telefono' => 'Teléfono de contacto',
                          'email' => 'Correo de contacto',
                          'descripcion' => 'Descripción (opcional)',
                          _ => f,
                        },
                      ),
                      keyboardType: f == 'tarifa'
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : f == 'email'
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                      validator: (v) {
                        if (f == 'descripcion') return null;
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final trimmed = v.trim();
                        if (f == 'tarifa') {
                          final amount = double.tryParse(trimmed);
                          if (amount == null || amount <= 0) {
                            return 'Ingrese una tarifa mayor a 0';
                          }
                        }
                        if (f == 'ruc' &&
                            !RegExp(r'^\d{11}$').hasMatch(trimmed)) {
                          return 'RUC de 11 dígitos';
                        }
                        if (f == 'telefono' && trimmed.length < 6) {
                          return 'Teléfono inválido';
                        }
                        if (f == 'email' &&
                            !RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(trimmed)) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: () async {
                      final point = await Navigator.push<LatLng>(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => CentroUbicacionPicker(
                            initialPosition: location,
                            initialAddress: controllers['direccion']!.text
                                .trim(),
                          ),
                        ),
                      );
                      if (point != null) setLocal(() => location = point);
                    },
                    icon: const Icon(Icons.location_on_outlined),
                    label: Text(
                      location == null
                          ? 'Elegir ubicación en el mapa'
                          : 'Ubicación marcada · Cambiar',
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final url = await service.subirImagen();
                        if (url != null) {
                          setLocal(() => controllers['imagen']!.text = url);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error al subir imagen: $e'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      controllers['imagen']!.text.isEmpty
                          ? 'Subir foto del centro'
                          : 'Foto seleccionada · Cambiar',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Centro activo'),
                    value: active,
                    onChanged: (v) => setLocal(() => active = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!key.currentState!.validate()) return;
                if (!GestorService.validarUbicacion(
                  location?.latitude,
                  location?.longitude,
                )) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Marca la ubicación del centro en el mapa.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      final values = <String, dynamic>{
        for (final f in fields) f: controllers[f]!.text.trim(),
      };
      values['tarifa'] = double.parse(values['tarifa']);
      values['latitud'] = location!.latitude;
      values['longitud'] = location!.longitude;
      values['estado'] = active ? 1 : 0;
      if (values['ruc'] == '') values['ruc'] = null;
      if (values['imagen'] == '') values['imagen'] = null;
      await action(
        () => service.guardarCentro(
          widget.managerId,
          values,
          id: c == null ? null : asInt(c['id']),
        ),
      );
    }
    for (final ctrl in controllers.values) {
      ctrl.dispose();
    }
  }

  Future<void> _areaDialog([Map<String, dynamic>? a]) async {
    final key = GlobalKey<FormState>();
    final name = TextEditingController(text: '${a?['nombre_area'] ?? ''}');
    final price = TextEditingController(text: '${a?['tarifa_por_hora'] ?? ''}');
    final capacity = TextEditingController(
      text: '${a?['capacidad_jugadores'] ?? ''}',
    );
    final description = TextEditingController(
      text: '${a?['descripcion'] ?? ''}',
    );
    final image = TextEditingController(text: '${a?['imagen_area'] ?? ''}');
    int? center = a == null
        ? asInt(centros.first['id'])
        : asInt(a['institucion_deportiva_id']);
    int? sport = a == null
        ? (deportes.isEmpty ? null : asInt(deportes.first['id']))
        : asInt(a['deporte_id']);
    var state = '${a?['estado'] ?? 'activa'}';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(a == null ? 'Nueva cancha' : 'Editar cancha'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: key,
              child: ListView(
                shrinkWrap: true,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: center,
                    decoration: const InputDecoration(labelText: 'Centro'),
                    items: centros
                        .map(
                          (c) => DropdownMenuItem(
                            value: asInt(c['id']),
                            child: Text('${c['nombre']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => center = v),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: sport,
                    decoration: const InputDecoration(labelText: 'Deporte'),
                    items: deportes
                        .map(
                          (d) => DropdownMenuItem(
                            value: asInt(d['id']),
                            child: Text('${d['nombre']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => sport = v),
                  ),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: price,
                    decoration: const InputDecoration(
                      labelText: 'Tarifa por hora',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? 'Número inválido'
                        : null,
                  ),
                  TextFormField(
                    controller: capacity,
                    decoration: const InputDecoration(labelText: 'Capacidad'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isNotEmpty && int.tryParse(v) == null
                        ? 'Número inválido'
                        : null,
                  ),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  TextFormField(
                    controller: image,
                    decoration: const InputDecoration(
                      labelText: 'URL de imagen (opcional)',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final url = await service.subirImagen();
                        if (url != null) image.text = url;
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error al subir imagen: $e'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Subir foto de la cancha'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: state,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items:
                        [
                              'activa',
                              'inactiva',
                              'mantenimiento',
                              if (![
                                'activa',
                                'inactiva',
                                'mantenimiento',
                              ].contains(state))
                                state,
                            ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => setLocal(() => state = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate() && sport != null) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && center != null && sport != null) {
      await action(
        () => service.guardarArea({
          'institucion_deportiva_id': center,
          'deporte_id': sport,
          'nombre_area': name.text.trim(),
          'tarifa_por_hora': double.parse(price.text),
          'capacidad_jugadores': capacity.text.isEmpty
              ? null
              : int.parse(capacity.text),
          'descripcion': description.text.trim(),
          'imagen_area': image.text.isEmpty ? null : image.text.trim(),
          'estado': state,
        }, id: a == null ? null : asInt(a['id'])),
      );
    }
    for (final ctrl in [name, price, capacity, description, image]) {
      ctrl.dispose();
    }
  }

  Future<void> _horariosDialog(Map<String, dynamic> area) async {
    final areaId = asInt(area['id']);
    Future<void> open() async {
      final rows = await service.horarios(areaId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Horarios: ${area['nombre_area']}'),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: [
                ...rows.map(
                  (h) => ListTile(
                    title: Text('${h['dia']}'),
                    subtitle: Text(
                      '${h['hora_apertura']}–${h['hora_cierre']} · ${h['disponible'] == 1 ? 'Disponible' : 'Cerrado'}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (dialog) => AlertDialog(
                            title: const Text('Eliminar horario'),
                            content: Text(
                              '¿Eliminar el horario de ${h['dia']}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialog, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dialog, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true || !ctx.mounted) return;
                        Navigator.pop(ctx);
                        await action(
                          () => service.borrarHorario(asInt(h['id'])),
                        );
                        await open();
                      },
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _horarioForm(areaId, h);
                      await open();
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _horarioForm(areaId);
                    await open();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar día'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }

    await open();
  }

  Future<void> _horarioForm(int areaId, [Map<String, dynamic>? h]) async {
    const days = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];
    var day = '${h?['dia'] ?? days.first}';
    var open = TimeOfDay(
      hour:
          int.tryParse('${h?['hora_apertura'] ?? '08:00'}'.split(':')[0]) ?? 8,
      minute:
          int.tryParse('${h?['hora_apertura'] ?? '08:00'}'.split(':')[1]) ?? 0,
    );
    var close = TimeOfDay(
      hour: int.tryParse('${h?['hora_cierre'] ?? '22:00'}'.split(':')[0]) ?? 22,
      minute:
          int.tryParse('${h?['hora_cierre'] ?? '22:00'}'.split(':')[1]) ?? 0,
    );
    var enabled = h?['disponible'] != 0;
    String time(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Horario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: day,
                items: days
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: h == null ? (v) => setLocal(() => day = v!) : null,
              ),
              ListTile(
                title: const Text('Apertura'),
                subtitle: Text(time(open)),
                onTap: () async {
                  final v = await showTimePicker(
                    context: ctx,
                    initialTime: open,
                  );
                  if (v != null) setLocal(() => open = v);
                },
              ),
              ListTile(
                title: const Text('Cierre'),
                subtitle: Text(time(close)),
                onTap: () async {
                  final v = await showTimePicker(
                    context: ctx,
                    initialTime: close,
                  );
                  if (v != null) setLocal(() => close = v);
                },
              ),
              SwitchListTile(
                title: const Text('Disponible'),
                value: enabled,
                onChanged: (v) => setLocal(() => enabled = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      if (open.hour * 60 + open.minute >= close.hour * 60 + close.minute) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El cierre debe ser posterior a la apertura'),
            ),
          );
        }
        return;
      }
      await action(
        () => service.guardarHorario(
          areaId,
          day,
          time(open),
          time(close),
          enabled,
          id: h == null ? null : asInt(h['id']),
        ),
      );
    }
  }
}

// Solo se muestra el correo de la sesión; la tabla heredada de gestores es privada.
class SupabaseEmail {
  static String get email =>
      GestorService().db.auth.currentUser?.email ?? 'Cuenta gestora';
}
