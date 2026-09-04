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
  String? _error;

  bool get procesando => _procesando;
  bool get reservaCreada => _reservaCreada;
  String? get orderId => _orderId;
  String? get approvalUrl => _approvalUrl;
  String? get error => _error;

  ReservaResumenViewModel({
    required this.area,
    required this.calendarioVM,
    required this.userId,
    SupabaseClient? supabaseClient,
  }) : supabase = supabaseClient ?? Supabase.instance.client;

  // Monto original en soles (tarifa * duración)
  double get costoTotal => calendarioVM.costoTotal(area.tarifaPorHora);

  // Tipo de cambio temporal (hardcode) hasta integrar API de conversión
  static const double _tipoCambioTemporal = 3.7; // 1 USD ≈ 3.7 PEN (temporal)

  // Monto convertido a USD para enviar a PayPal (redondeado a 2 decimales al usarlo)
  double get costoTotalUsd => costoTotal / _tipoCambioTemporal;

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
      final usd = double.parse(costoTotalUsd.toStringAsFixed(2));
      print(
        '[VM] Creando orden PayPal por $usd USD (equiv S/. ${costoTotal.toStringAsFixed(2)})',
      );
      final data = await service.createOrder(usd, currency: 'USD');
      _orderId = data['orderId'];
      _approvalUrl = data['approvalUrl'];
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
    final productName = buildProductName(context);
    print('[VM] Abriendo WebView PayPal con URL $_approvalUrl');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PayPalWebView(
          paypalUrl: _approvalUrl!,
          productName: productName,
          amount: costoTotal,
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
        print('[VM] Creando reserva en BD');
        // Tras capturar un pago exitoso establecemos la reserva como Confirmada
        // Extraer datos relevantes de la captura (si vienen en la respuesta)
        final amountCapturedUsd =
            double.tryParse(
              (capture['amount']?['value'] ?? capture['amount'])?.toString() ??
                  '',
            ) ??
            costoTotalUsd; // fallback
        final amountCapturedSoles = amountCapturedUsd * _tipoCambioTemporal;

        // Validación ligera (no bloqueante) de consistencia de monto
        final diff = (amountCapturedSoles - costoTotal).abs();
        if (diff > 0.05) {
          print(
            '[VM][WARN] Diferencia entre monto calculado (S/. ${costoTotal.toStringAsFixed(2)}) y capturado (~S/. ${amountCapturedSoles.toStringAsFixed(2)}).',
          );
        }

        final res = await calendarioVM.crearReserva(
          idUsuario: userId,
          estado: 'Confirmada',
          // Guardamos el monto pagado en soles (monto local para tus reportes)
          montoPagado: double.parse(amountCapturedSoles.toStringAsFixed(2)),
          metodoPago: 'paypal',
          fechaPago: DateTime.now(),
          paypalOrderId: _orderId,
        );
        if (res.ok) {
          _reservaCreada = true;

          // Actualizar automáticamente la lista de reservas
          await ReservasListViewModel.refreshIfActive(int.parse(userId));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((r) => r.isFirst);
        } else {
          _setError(res.message ?? 'Error creando reserva');
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
    _reservaCreada = false;
    _error = null;
    notifyListeners();
  }
}
