import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';

class ReservaDirectaView extends StatefulWidget {
  final List<Map<String, dynamic>> areas;
  final List<Map<String, dynamic>> centros;
  final int? initialAreaId;
  const ReservaDirectaView({
    super.key,
    required this.areas,
    required this.centros,
    this.initialAreaId,
  });

  @override
  State<ReservaDirectaView> createState() => _ReservaDirectaViewState();
}

class _ReservaDirectaViewState extends State<ReservaDirectaView> {
  final _db = Supabase.instance.client;
  final _cliente = TextEditingController();
  final _telefono = TextEditingController();
  final _monto = TextEditingController();
  int? _areaId;
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  String _method = 'efectivo';
  final Set<int> _selectedSlotMinutes = <int>{};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _reservas = [];
  List<Map<String, dynamic>> _horarios = [];

  @override
  void initState() {
    super.initState();
    _areaId = widget.initialAreaId ??
        (widget.areas.isEmpty ? null : _asInt(widget.areas.first['id']));
    _load();
  }

  @override
  void dispose() {
    _cliente.dispose();
    _telefono.dispose();
    _monto.dispose();
    super.dispose();
  }

  int _asInt(dynamic value) => value is num ? value.toInt() : int.parse('$value');
  String get _dateSql => '${_day.year}-${_day.month.toString().padLeft(2, '0')}-${_day.day.toString().padLeft(2, '0')}';
  Map<String, dynamic>? get _area => _areaId == null ? null : widget.areas.where((a) => _asInt(a['id']) == _areaId).firstOrNull;
  String _time(TimeOfDay value) => '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';
  int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;
  TimeOfDay _add(TimeOfDay value, int minutes) { final total = _minutes(value) + minutes; return TimeOfDay(hour: total ~/ 60, minute: total % 60); }
  TimeOfDay _parse(String value) { final p=value.split(':'); return TimeOfDay(hour:int.parse(p[0]), minute:int.parse(p[1])); }
  String _dayName(DateTime day) => const ['domingo','lunes','martes','miércoles','jueves','viernes','sábado'][day.weekday % 7];

  Future<void> _load() async {
    if (_areaId == null) { setState(() => _loading = false); return; }
    setState(() { _loading = true; _error = null; _selectedSlotMinutes.clear(); });
    try {
      final values = await Future.wait([
        _db.from('reservas').select('hora_inicio,hora_fin,estado').eq('area_deportiva_id', _areaId!).eq('fecha', _dateSql).neq('estado', 'cancelada'),
        _db.from('areas_horarios').select('hora_apertura,hora_cierre,disponible,dia').eq('area_deportiva_id', _areaId!).eq('disponible', 1),
      ]);
      if (!mounted) return;
      final daySchedules = List<Map<String,dynamic>>.from(values[1] as List)
          .where((item) => '${item['dia']}'.toLowerCase() == _dayName(_day))
          .toList();
      setState(() { _reservas = List<Map<String,dynamic>>.from(values[0] as List); _horarios = daySchedules; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  List<TimeOfDay> get _availableSlots {
    if (_horarios.isEmpty) return [];
    final opening = _parse('${_horarios.first['hora_apertura']}');
    final closing = _parse('${_horarios.first['hora_cierre']}');
    final result = <TimeOfDay>[];
    for (var cursor = _minutes(opening); cursor + 30 <= _minutes(closing); cursor += 30) {
      final start = TimeOfDay(hour: cursor ~/ 60, minute: cursor % 60);
      final end = _add(start, 30);
      final occupied = _reservas.any((r) => _minutes(_parse('${r['hora_inicio']}')) < _minutes(end) && _minutes(_parse('${r['hora_fin']}')) > _minutes(start));
      if (!occupied) result.add(start);
    }
    return result;
  }

  bool get _hasSelection => _selectedSlotMinutes.isNotEmpty;
  int get _durationMinutes => _selectedSlotMinutes.length * 30;
  TimeOfDay get _start => TimeOfDay(
        hour: _selectedSlotMinutes.reduce((a, b) => a < b ? a : b) ~/ 60,
        minute: _selectedSlotMinutes.reduce((a, b) => a < b ? a : b) % 60,
      );
  TimeOfDay get _end => _add(_start, _durationMinutes);
  bool get _selectionIsContiguous {
    if (_selectedSlotMinutes.isEmpty) return false;
    final values = _selectedSlotMinutes.toList()..sort();
    return List.generate(values.length - 1, (i) => values[i + 1] - values[i])
        .every((difference) => difference == 30);
  }

  void _toggleSlot(TimeOfDay slot) {
    final minute = _minutes(slot);
    final next = Set<int>.from(_selectedSlotMinutes);
    if (!next.add(minute)) {
      next.remove(minute);
    }
    final values = next.toList()..sort();
    final contiguous = values.length < 2 ||
        List.generate(values.length - 1, (i) => values[i + 1] - values[i])
            .every((difference) => difference == 30);
    if (!contiguous) {
      setState(() => _error = 'Selecciona bloques continuos de 30 minutos.');
      return;
    }
    setState(() {
      _selectedSlotMinutes
        ..clear()
        ..addAll(next);
      _error = null;
    });
    _updateAmount();
  }

  void _updateAmount() {
    final rate = (_area?['tarifa_por_hora'] as num?)?.toDouble() ?? double.tryParse('${_area?['tarifa_por_hora']}') ?? 0;
    _monto.text = (rate * _durationMinutes / 60).toStringAsFixed(2);
  }

  Future<void> _save() async {
    if (_areaId == null || !_hasSelection || !_selectionIsContiguous) { setState(() => _error = 'Selecciona uno o más bloques continuos de 30 minutos.'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      final id = await _db.rpc('crear_reserva_directa_gestor', params: {
        'p_area_id': _areaId,
        'p_fecha': _dateSql,
        'p_hora_inicio': _time(_start),
        'p_hora_fin': _time(_end),
        'p_cliente_nombre': _cliente.text.trim(),
        'p_cliente_telefono': _telefono.text.trim(),
        'p_monto': double.tryParse(_monto.text.replaceAll(',', '.')) ?? 0,
        'p_metodo_pago': _method,
      });
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Reserva registrada'), content: Text('Reserva presencial #$id confirmada y pagada por ${_method == 'efectivo' ? 'efectivo' : _method.toUpperCase()}.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))]));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo registrar la reserva: $e');
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final colors = theme.colorScheme;
    final bg = AppTheme.headerBackgroundFor(context.watch<ThemeController>().selection);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Generar reserva'), backgroundColor: colors.primary, foregroundColor: colors.onPrimary, flexibleSpace: bg == null ? null : Container(decoration: BoxDecoration(image: DecorationImage(image: AssetImage(bg), fit: BoxFit.cover, opacity: .42)))),
      body: Stack(children: [if (bg != null) Positioned.fill(child: Opacity(opacity:.08, child:Image.asset(bg,fit:BoxFit.cover))), ListView(padding: const EdgeInsets.all(18), children: [
        Text('Reserva presencial', style: theme.textTheme.titleLarge), const SizedBox(height: 4), const Text('Registra una atención en local. El pago queda confirmado de inmediato.'), const SizedBox(height: 18),
        DropdownButtonFormField<int>(value: _areaId, decoration: const InputDecoration(labelText: 'Cancha'), items: widget.areas.map((a) => DropdownMenuItem(value:_asInt(a['id']), child: Text('${a['nombre_area']} · ${_centerName(a)}'))).toList(), onChanged: (value) { setState(() { _areaId=value; _selectedSlotMinutes.clear(); }); _load(); }),
        const SizedBox(height: 14), Card(child: ListTile(leading: const Icon(Icons.calendar_month), title: Text(_dateSql), subtitle: const Text('Fecha de la reserva'), onTap: () async { final picked=await showDatePicker(context:context, initialDate:_day, firstDate:DateTime.now(), lastDate:DateTime.now().add(const Duration(days:365))); if(picked!=null){setState(()=>_day=DateUtils.dateOnly(picked)); await _load();} })),
        const SizedBox(height: 18), Text('Disponibilidad del día', style: theme.textTheme.titleMedium), const SizedBox(height: 8),
        const Text('Selecciona uno o más bloques continuos de 30 minutos.'), const SizedBox(height: 8),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child:CircularProgressIndicator())) else if (_horarios.isEmpty) const Card(child: ListTile(leading: Icon(Icons.event_busy), title: Text('La cancha no tiene horario disponible este día'))) else Wrap(spacing:8, runSpacing:8, children:_availableSlots.map((slot)=>ChoiceChip(label:Text(_time(slot).substring(0,5)), selected:_selectedSlotMinutes.contains(_minutes(slot)), onSelected:(_)=>_toggleSlot(slot))).toList()),
        if (_hasSelection) Padding(padding: const EdgeInsets.only(top: 12), child: Card(child: ListTile(leading: const Icon(Icons.schedule), title: Text('${_time(_start).substring(0, 5)} – ${_time(_end).substring(0, 5)}'), subtitle: Text('$_durationMinutes minutos seleccionados')))),
        const SizedBox(height: 16), Text('Turnos ya ocupados', style: theme.textTheme.titleSmall), if (_reservas.isEmpty) const Text('No hay reservas registradas.') else ..._reservas.map((r)=>ListTile(dense:true, leading:const Icon(Icons.lock_clock_outlined), title:Text('${r['hora_inicio']}–${r['hora_fin']}'), subtitle:Text('${r['estado']}'))),
        const SizedBox(height: 18), Text('Datos del cliente', style: theme.textTheme.titleMedium), const SizedBox(height:8), TextField(controller:_cliente, decoration: const InputDecoration(labelText:'Nombre del cliente (opcional)')), const SizedBox(height:12), TextField(controller:_telefono, keyboardType:TextInputType.phone, decoration: const InputDecoration(labelText:'Teléfono (opcional)')),
        const SizedBox(height:18), DropdownButtonFormField<String>(value:_method, decoration:const InputDecoration(labelText:'Método de pago'), items: const [DropdownMenuItem(value:'efectivo',child:Text('Efectivo')),DropdownMenuItem(value:'yape',child:Text('Yape verificado en local')),DropdownMenuItem(value:'paypal',child:Text('PayPal verificado en local'))], onChanged:(value)=>setState(()=>_method=value??'efectivo')),
        const SizedBox(height:12), TextField(controller:_monto, keyboardType:const TextInputType.numberWithOptions(decimal:true), decoration:const InputDecoration(labelText:'Monto cobrado (S/)')),
        if (_error != null) Padding(padding: const EdgeInsets.only(top:12), child:Text(_error!,style:TextStyle(color:colors.error))), const SizedBox(height:20), FilledButton.icon(onPressed:_saving?null:_save, icon:const Icon(Icons.check_circle_outline), label:Text(_saving?'Registrando...':'Confirmar reserva presencial')),
      ])]),
    );
  }

  String _centerName(Map<String,dynamic> area) { final id=area['institucion_deportiva_id']; return widget.centros.where((c)=>c['id']==id).map((c)=>'${c['nombre']}').firstOrNull ?? 'Centro'; }
}
