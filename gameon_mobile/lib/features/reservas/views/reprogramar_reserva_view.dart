import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reserva.dart';
import '../services/reprogramacion_service.dart';
import '../viewmodels/reservas_list_viewmodel.dart';

class ReprogramarReservaView extends StatefulWidget {
  final Reserva reserva;
  const ReprogramarReservaView({super.key, required this.reserva});

  @override
  State<ReprogramarReservaView> createState() => _ReprogramarReservaViewState();
}

class _ReprogramarReservaViewState extends State<ReprogramarReservaView> {
  late DateTime _fecha = widget.reserva.fecha;
  late TimeOfDay _hora = TimeOfDay(
    hour: widget.reserva.inicioMin ~/ 60,
    minute: widget.reserva.inicioMin % 60,
  );
  bool _guardando = false;
  String? _error;

  Future<void> _guardar() async {
    if (_guardando) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar reprogramación'),
        content: Text(
          'Mover la reserva #${widget.reserva.id} al '
          '${DateFormat('dd/MM/yyyy').format(_fecha)} a las ${_hora.format(context)}. '
          'Se conservarán la duración y el pago de la reserva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final hora =
          '${_hora.hour.toString().padLeft(2, '0')}:'
          '${_hora.minute.toString().padLeft(2, '0')}:00';
      final reserva = await ReprogramacionService(Supabase.instance.client)
          .reprogramar(
            reservaId: widget.reserva.id,
            fecha: _fecha,
            horaInicio: hora,
          );
      await ReservasListViewModel.refreshIfActive(reserva.idUsuario);
      if (mounted) Navigator.pop(context, reserva);
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.code) {
            '23P01' => 'El horario ya está ocupado. Elige otro horario.',
            '42501' => 'Solo puedes reprogramar tus propias reservas.',
            '22023' =>
              'Selecciona un horario futuro disponible. La reserva debe estar pendiente o confirmada.',
            'PGRST202' =>
              'El servicio de reprogramación aún no está disponible.',
            _ => 'No se pudo reprogramar. Inténtalo nuevamente.',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo confirmar la operación. Consulta tu reserva antes de volver a intentar.',
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_guardando,
    child: Scaffold(
      appBar: AppBar(title: const Text('Reprogramar reserva')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Reserva #${widget.reserva.id}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Duración: ${widget.reserva.finMin - widget.reserva.inicioMin} minutos. '
            'Se conserva la misma reserva, área deportiva y pago. Horarios de Perú.',
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Nueva fecha'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _guardando
                ? null
                : () async {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final day = await showDatePicker(
                      context: context,
                      initialDate: _fecha.isBefore(today) ? today : _fecha,
                      firstDate: today,
                      lastDate: DateTime(today.year + 5, 12, 31),
                    );
                    if (mounted && day != null) setState(() => _fecha = day);
                  },
          ),
          ListTile(
            title: const Text('Nueva hora de inicio'),
            subtitle: Text(_hora.format(context)),
            trailing: const Icon(Icons.schedule),
            onTap: _guardando
                ? null
                : () async {
                    final hora = await showTimePicker(
                      context: context,
                      initialTime: _hora,
                    );
                    if (mounted && hora != null) setState(() => _hora = hora);
                  },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_calendar),
            label: Text(_guardando ? 'Guardando...' : 'Reprogramar'),
          ),
        ],
      ),
    ),
  );
}
