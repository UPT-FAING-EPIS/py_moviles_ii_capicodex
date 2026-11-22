import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../home/models/area_deportiva.dart';
import '../viewmodels/reserva_calendario_viewmodel.dart';
import '../viewmodels/reservas_list_viewmodel.dart';
import '../services/paypal_service.dart';
import '../views/paypal_webview.dart';

/// ViewModel responsable de manejar el estado y la lógica
/// del resumen y flujo de pago de una reserva.
class ReservaResumenViewModel extends ChangeNotifier {
  final AreaDeportiva area;
  final ReservaCalendarioViewModel calendarioVM;
  final String userId;
  final SupabaseClient supabase;

  bool _procesando = false;
  bool _reservaCreada = false;
  String? _orderId;
  String? _approvalUrl;
  String? _amountUsd;
  String? _exchangeRate;
  String? _error;

  bool get procesando => _procesando;
  bool get reservaCreada => _reservaCreada;
  String? get orderId => _orderId;
  String? get approvalUrl => _approvalUrl;
  String? get amountUsd => _amountUsd;
  String? get error => _error;

  ReservaResumenViewModel({
    required this.area,
    required this.calendarioVM,
    required this.userId,
    SupabaseClient? supabaseClient,
  }) : supabase = supabaseClient ?? Supabase.instance.client;

  // Monto original en soles (tarifa * duración)
  double get costoTotal => calendarioVM.costoTotal(area.tarifaPorHora);

  String buildProductName(BuildContext context) {
    final fecha = calendarioVM.selectedDay!;
    final fechaStr = DateFormat('dd/MM/yyyy').format(fecha);
    final horaInicio = calendarioVM.startTime!.format(context);
    final horaFin = calendarioVM.endTime != null
        ? calendarioVM.endTime!.format(context)
        : TimeOfDay(
            hour: calendarioVM.startTime!.hour,
            minute:
                calendarioVM.startTime!.minute + calendarioVM.intervaloMinutos,
          ).format(context);
    return 'Reserva ${area.nombreArea} - $fechaStr ($horaInicio - $horaFin)';
  }

  void _setProcesando(bool value) {
    _procesando = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> crearOrdenPayPal() async {
    if (_orderId != null && _approvalUrl != null) return; // Ya creada
    _setProcesando(true);
    _setError(null);
    try {
      final service = PayPalService(supabase);
      String format(TimeOfDay t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
      final data = await service.createOrder(
        areaId: area.id,
        fecha: DateFormat('yyyy-MM-dd').format(calendarioVM.selectedDay!),
        inicio: format(calendarioVM.startTime!),
        fin: format(calendarioVM.horaFinReal),
      );
      _orderId = data['orderId'];
      _approvalUrl = data['approvalUrl'];
      _amountUsd = data['amountUsd']?.toString();
      _exchangeRate = data['exchangeRate']?.toString();
      print('[VM] Orden creada. orderId=$_orderId');
      if (_orderId == null || _approvalUrl == null) {
        throw 'Respuesta incompleta del servidor PayPal';
      }
    } catch (e) {
      print('[VM][ERROR] creando orden: $e');
      _setError('Error creando orden: $e');
    } finally {
      _setProcesando(false);
    }
  }

  /// Abre el WebView. Si aún no existe orden, la crea primero.
  Future<void> abrirFlujoPago(BuildContext context) async {
    if (procesando) return;
    await crearOrdenPayPal();
    if (_approvalUrl == null) return;
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Confirmar pago PayPal'),
      content: Text('Tarifa: S/ ${costoTotal.toStringAsFixed(2)}. Se enviará a PayPal US\$ ${_amountUsd ?? '0.00'} (referencia: 1 USD ≈ S/ ${_exchangeRate ?? '—'}, fuente Frankfurter). PayPal o tu banco pueden aplicar otra conversión y comisiones.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Continuar a PayPal'))],
    ));
    if (confirmed != true) {
      try {
        if (_orderId != null && await PayPalService(supabase).cancelOrder(_orderId!)) resetearPago();
      } catch (_) { _setError('No se pudo cancelar la orden. Puedes reintentar el pago.'); }
      return;
    }
    if (!context.mounted) return;
    final productName = buildProductName(context);
    print('[VM] Abriendo WebView PayPal con URL $_approvalUrl');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PayPalWebView(
          paypalUrl: _approvalUrl!,
          productName: productName,
          amount: double.tryParse(_amountUsd ?? '') ?? 0,
        ),
      ),
    );
    print('[VM] Usuario regresó del WebView con result=$result');

    // Si el WebView devolvió true significa que se detectó la pantalla final de PayPal
    // (usuario aprobó el pago). Procedemos a captura automática.
    if (result == true) {
      print('[VM] Aprobación detectada. Iniciando captura automática...');
      await capturarPagoYCrearReserva(context);
    } else {
      print(
        '[VM] El usuario salió sin aprobación final detectada (result=$result).',
      );
      try {
        if (_orderId != null && await PayPalService(supabase).cancelOrder(_orderId!)) {
          resetearPago();
        }
      } catch (_) {
        _setError('No se pudo verificar si PayPal canceló la orden. Puedes reintentar.');
      }
    }
  }

  /// Intenta capturar el pago y crear la reserva.
  Future<void> capturarPagoYCrearReserva(BuildContext context) async {
    if (_orderId == null) {
      _setError('No hay orden para capturar');
      return;
    }
    if (_reservaCreada) return; // Ya hecha
    _setProcesando(true);
    _setError(null);
    try {
      final service = PayPalService(supabase);
      print('[VM] Capturando pago para orderId=$_orderId');
      final capture = await service.capturePayment(_orderId!);
      print('[VM] Resultado captura (raw): $capture');
      if (capture['success'] == true) {
        if (capture['reservationId'] != null) {
          _reservaCreada = true;

          // Actualizar automáticamente la lista de reservas
          await ReservasListViewModel.refreshIfActive(int.parse(userId));

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((r) => r.isFirst);
        } else {
          _setError('No se confirmó la reserva. Reintenta la verificación.');
        }
      } else {
        _setError('Captura fallida: ${capture['status']}');
      }
    } catch (e) {
      print('[VM][ERROR] capturando pago / creando reserva: $e');
      _setError('Error capturando pago: $e');
    } finally {
      _setProcesando(false);
    }
  }

  // Métodos de utilidad / debugging opcional
  void resetearPago() {
    _orderId = null;
    _approvalUrl = null;
    _amountUsd = null;
    _exchangeRate = null;
    _reservaCreada = false;
    _error = null;
    notifyListeners();
  }
}
