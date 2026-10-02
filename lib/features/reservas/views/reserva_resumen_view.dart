import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/home/models/area_deportiva.dart';
import 'package:gameon/features/reservas/viewmodels/reserva_calendario_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/reserva_resumen_viewmodel.dart';

class ReservaResumenView extends StatefulWidget {
  final AreaDeportiva area;
  final ReservaCalendarioViewModel viewModel;
  final String userId;

  const ReservaResumenView({
    super.key,
    required this.area,
    required this.viewModel,
    required this.userId,
  });

  @override
  State<ReservaResumenView> createState() => _ReservaResumenViewState();
}

class _ReservaResumenViewState extends State<ReservaResumenView> {
  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final area = widget.area;

    // Status bar transparente con iconos claros
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    if (vm.selectedDay == null || !vm.tieneRangoValido) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              // Header moderno
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade600, Colors.green.shade800],
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
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
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
                        const Text(
                          'Error',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: Datos de reserva inválidos',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fecha = vm.selectedDay!;
    final fechaStr = DateFormat('dd/MM/yyyy').format(fecha);
    final horaInicio = vm.startTime!.format(context);
    // Usar horaFinReal para obtener el tiempo final correcto (incluye el intervalo del último slot)
    final horaFin = vm.horaFinReal.format(context);

    // ViewModel de resumen (creado perezosamente con Provider)
    return ChangeNotifierProvider<ReservaResumenViewModel>(
      create: (_) => ReservaResumenViewModel(
        area: area,
        calendarioVM: vm,
        userId: widget.userId,
      ),
      builder: (context, _) {
        final resumenVM = context.watch<ReservaResumenViewModel>();
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: Colors.grey[50],
                body: Column(
                  children: [
                    // Header moderno con gradiente verde
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green.shade600,
                            Colors.green.shade800,
                          ],
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
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Botón atrás
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
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
                                  // Título
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Confirmar',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          area.nombreArea,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botón reset (si existe orden)
                                  if (resumenVM.orderId != null &&
                                      !resumenVM.reservaCreada)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextButton(
                                        onPressed: resumenVM.procesando
                                            ? null
                                            : () => resumenVM.resetearPago(),
                                        child: const Text(
                                          'Reset',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Contenido scrolleable
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildResumenCard(
                              context,
                              area.nombreArea,
                              fechaStr,
                              horaInicio,
                              horaFin,
                              vm.costoTotal(area.tarifaPorHora),
                            ),
                            const SizedBox(height: 20),
                            _buildSeccionPago(context, resumenVM),
                            const SizedBox(height: 20),
                            _buildMensajeSeguridad(),
                            if (resumenVM.error != null) ...[
                              const SizedBox(height: 20),
                              _buildErrorMessage(resumenVM.error!),
                            ],
                            if (resumenVM.orderId != null &&
                                !resumenVM.reservaCreada) ...[
                              const SizedBox(height: 20),
                              _buildOrderInfo(resumenVM.orderId!),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (resumenVM.procesando)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 48),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.green[600]!,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Procesando pago...',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No cierres la app',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------- Widgets privados extraídos para limpieza ----------
Widget _buildResumenCard(
  BuildContext context,
  String nombreArea,
  String fechaStr,
  String horaInicio,
  String horaFin,
  double costoTotal,
) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.green[700], size: 22),
            const SizedBox(width: 10),
            Text(
              'Resumen de Reserva',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ModernInfoRow(
          icon: Icons.sports_soccer,
          label: 'Cancha',
          value: nombreArea,
          iconColor: Colors.blue[600]!,
        ),
        const SizedBox(height: 12),
        _ModernInfoRow(
          icon: Icons.calendar_today,
          label: 'Fecha',
          value: fechaStr,
          iconColor: Colors.orange[600]!,
        ),
        const SizedBox(height: 12),
        _ModernInfoRow(
          icon: Icons.access_time,
          label: 'Horario',
          value: '$horaInicio - $horaFin',
          iconColor: Colors.purple[600]!,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.green[100]!],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[300]!, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'S/. ${costoTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildSeccionPago(
  BuildContext context,
  ReservaResumenViewModel resumenVM,
) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payment, color: Colors.green[700], size: 22),
            const SizedBox(width: 10),
            Text(
              'Método de Pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Botón de pago - PROMINENTE
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [const Color(0xFF0070BA), const Color(0xFF003087)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0070BA).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: resumenVM.procesando
                    ? null
                    : () => resumenVM.abrirFlujoPago(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: resumenVM.procesando
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 26,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              resumenVM.orderId == null
                                  ? 'Pagar con PayPal'
                                  : resumenVM.error != null
                                  ? 'Reintentar Pago'
                                  : 'Ver Pago en PayPal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Estado compacto
        if (resumenVM.orderId != null || resumenVM.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  resumenVM.reservaCreada
                      ? Icons.check_circle
                      : resumenVM.error != null
                      ? Icons.error
                      : Icons.pending,
                  color: resumenVM.reservaCreada
                      ? Colors.green[600]
                      : resumenVM.error != null
                      ? Colors.red[600]
                      : Colors.orange[600],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  resumenVM.reservaCreada
                      ? 'Reserva exitosa'
                      : resumenVM.error != null
                      ? 'Error en el pago'
                      : 'Finalizando reserva...',
                  style: TextStyle(
                    color: resumenVM.reservaCreada
                        ? Colors.green[700]
                        : resumenVM.error != null
                        ? Colors.red[700]
                        : Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

Widget _buildMensajeSeguridad() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.green[50],
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.green[200]!),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user, color: Colors.green[700], size: 16),
        const SizedBox(width: 10),
        Text(
          'Pago seguro protegido por PayPal',
          style: TextStyle(
            color: Colors.green[800],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _buildErrorMessage(String error) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.red[200]!),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red[700], size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            error,
            style: TextStyle(color: Colors.red[700], fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

Widget _buildOrderInfo(String orderId) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue[200]!),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Orden creada: $orderId',
            style: TextStyle(color: Colors.blue[700], fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _ModernInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _ModernInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
