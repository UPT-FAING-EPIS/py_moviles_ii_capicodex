import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/home/models/area_deportiva.dart';
import 'package:gameon/features/reservas/viewmodels/reserva_calendario_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/reserva_resumen_viewmodel.dart';
import '../services/yape_service.dart';
import '../viewmodels/reservas_list_viewmodel.dart';

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
  late final Future<Map<String, dynamic>?> _cobroYape;
  bool _yapeBusy = false;
  bool _yapeSubmitted = false;
  String? _yapeError;

  @override
  void initState() {
    super.initState();
    _cobroYape = YapeService(
      Supabase.instance.client,
    ).cobroDelCentro(widget.area.institucionDeportivaId);
  }

  Future<void> _pagarYape() async {
    if (_yapeBusy || _yapeSubmitted) return;
    final vm = widget.viewModel;
    final day = vm.selectedDay;
    final start = vm.startTime;
    if (day == null || start == null || !vm.tieneRangoValido) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _yapeBusy = true;
      _yapeError = null;
    });
    String format(TimeOfDay time) =>
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    int? id;
    try {
      id = await YapeService(Supabase.instance.client).subirEvidenciaYReservar(
        areaId: widget.area.id,
        fecha: day,
        inicio: format(start),
        fin: format(vm.horaFinReal),
      );
    } catch (e) {
      if (mounted) setState(() => _yapeError = 'No se pudo enviar: $e');
    } finally {
      if (mounted) setState(() => _yapeBusy = false);
    }
    if (id == null || !mounted) return;
    // La RPC ya creó la reserva. Un fallo al actualizar la lista o navegar
    // nunca debe presentarse como fallo del pago ni permitir otro envío.
    setState(() => _yapeSubmitted = true);
    try {
      await ReservasListViewModel.refreshIfActive(int.parse(widget.userId));
    } catch (_) {
      // La lista se recargará al abrir la pestaña Reservas.
    }
    if (messenger.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Reserva #$id pendiente. El gestor verificará el pago en Yape.',
          ),
        ),
      );
    }
    if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
  }

  Widget _buildYapeOption() => FutureBuilder<Map<String, dynamic>?>(
    future: _cobroYape,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const ListTile(
          title: Text('Yape no disponible'),
          subtitle: Text(
            'No se pudo consultar la configuración de cobros del centro.',
          ),
        );
      }
      final cobro = snapshot.data;
      if (cobro == null)
        return const ListTile(
          title: Text('Yape no configurado'),
          subtitle: Text('Este centro todavía no ha publicado su QR de cobro.'),
        );
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pagar directamente al centro con Yape',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text(
                'Titular: ${cobro['yape_titular']} · Celular: ${cobro['yape_celular']}',
              ),
              const SizedBox(height: 8),
              Text(
                'Importe exacto: S/ ${widget.viewModel.costoTotal(widget.area.tarifaPorHora).toStringAsFixed(2)}',
              ),
              const SizedBox(height: 10),
              Center(
                child: Image.network(
                  '${cobro['yape_qr_url']}',
                  height: 190,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Text('No se pudo mostrar el QR'),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Paga desde Yape y adjunta la captura. El horario quedará pendiente y ocupado hasta que el gestor verifique el ingreso y apruebe o rechace la reserva.',
              ),
              if (_yapeError != null)
                Text(_yapeError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _yapeBusy || _yapeSubmitted ? null : _pagarYape,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _yapeBusy
                        ? 'Enviando...'
                        : _yapeSubmitted
                        ? 'Reserva enviada'
                        : 'Enviar captura de Yape',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final area = widget.area;
    final colors = Theme.of(context).colorScheme;
    final background = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );

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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              // Header moderno
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primary, colors.primaryContainer],
                  ),
                  image: background == null
                      ? null
                      : DecorationImage(
                          image: AssetImage(background),
                          fit: BoxFit.cover,
                          opacity: .32,
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
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Column(
                  children: [
                    // Header moderno con gradiente verde
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.primary, colors.primaryContainer],
                        ),
                        image: background == null
                            ? null
                            : DecorationImage(
                                image: AssetImage(background),
                                fit: BoxFit.cover,
                                opacity: .32,
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
                            const SizedBox(height: 16),
                            _buildYapeOption(),
                            const SizedBox(height: 20),
                            if (resumenVM.error != null) ...[
                              const SizedBox(height: 20),
                              _buildErrorMessage(context, resumenVM.error!),
                            ],
                            if (resumenVM.orderId != null &&
                                !resumenVM.reservaCreada) ...[
                              const SizedBox(height: 20),
                              _buildOrderInfo(context, resumenVM.orderId!),
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
                            color: colors.surface,
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
                                    colors.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Procesando pago...',
                                style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No cierres la app',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
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
  final colors = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.surface,
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
            Icon(Icons.receipt_long, color: colors.secondary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Resumen de Reserva',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ModernInfoRow(
          icon: Icons.sports_soccer,
          label: 'Cancha',
          value: nombreArea,
          iconColor: colors.secondary,
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
              colors: [
                colors.primary.withValues(alpha: .12),
                colors.primary.withValues(alpha: .2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primary.withValues(alpha: .5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 15,
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'S/. ${costoTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.secondary,
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
  final colors = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.surface,
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
            Icon(Icons.payment, color: colors.secondary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Método de Pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
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

Widget _buildErrorMessage(BuildContext context, String error) {
  final colors = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.errorContainer,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.error.withValues(alpha: .4)),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: colors.onErrorContainer, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            error,
            style: TextStyle(color: colors.onErrorContainer, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

Widget _buildOrderInfo(BuildContext context, String orderId) {
  final colors = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.primary.withValues(alpha: .4)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: colors.secondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Orden creada: $orderId',
            style: TextStyle(color: colors.onSurface, fontSize: 13),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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
