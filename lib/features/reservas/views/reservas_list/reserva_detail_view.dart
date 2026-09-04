import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gameon/features/reservas/models/reserva.dart';
import 'package:gameon/features/reservas/viewmodels/reservas_list_viewmodel.dart';

class ReservaDetailView extends StatefulWidget {
  final int reservaId;

  const ReservaDetailView.fromId({super.key, required this.reservaId});

  @override
  State<ReservaDetailView> createState() => _ReservaDetailViewState();
}

class _ReservaDetailViewState extends State<ReservaDetailView> {
  Reserva? reserva;
  ReservasListViewModel? listVm;
  AreaLite? area;
  InstitucionLite? inst;
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _load();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es_ES', null);
  }

  Future<void> _load() async {
    await _loadFromId(widget.reservaId);
  }

  Future<void> _loadFromId(int id) async {
    try {
      final vm = ReservasListViewModel();
      final details = await vm.getReservaWithDetails(id);

      if (details == null) {
        if (mounted) {
          setState(() {
            errorMessage = 'No se pudo encontrar la reserva';
            loading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          reserva = details.reserva;
          area = details.area;
          inst = details.institucion;
          listVm = vm;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error al cargar: ${e.toString()}';
          loading = false;
        });
      }
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return Icons.check_circle;
      case 'pendiente':
        return Icons.schedule;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = reserva;

    // Barra de estado transparente con iconos claros
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Header moderno con gradiente verde
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
                      // Botón atrás
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reserva',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r != null ? 'Detalle #${r.id}' : 'Cargando...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Estado badge (solo si hay reserva)
                      if (r != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(r.estado).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getEstadoColor(r.estado).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getEstadoIcon(r.estado),
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                r.estado,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
            const SizedBox(height: 20),
            // Contenido
            Expanded(
              child: errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.green[600],
                      ),
                    )
                  : r == null
                  ? const Center(child: Text('No hay datos'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Card de horario
                          _ModernCard(
                            icon: Icons.schedule,
                            title: 'Horario',
                            children: [
                              _InfoRow(
                                icon: Icons.calendar_today,
                                label: 'Fecha',
                                value: DateFormat(
                                  'EEEE, dd \'de\' MMMM \'de\' yyyy',
                                  'es_ES',
                                ).format(r.fecha),
                              ),
                              _InfoRow(
                                icon: Icons.access_time,
                                label: 'Inicio',
                                value: r.horaInicio.substring(0, 5),
                              ),
                              _InfoRow(
                                icon: Icons.access_time_filled,
                                label: 'Fin',
                                value: r.horaFin.substring(0, 5),
                              ),
                              _InfoRow(
                                icon: Icons.timer,
                                label: 'Duración',
                                value: _duracionLabel(r.horaInicio, r.horaFin),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Card de área deportiva (movida aquí para ser la primera después del horario)
                          _ModernCard(
                            icon: Icons.sports_soccer,
                            title: 'Área Deportiva',
                            children: [
                              // Imagen del área deportiva
                              if (area?.imagenArea != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      area!.imagenArea!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.green[600],
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.image_not_supported,
                                                    size: 48,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Error al cargar imagen',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              _InfoRow(
                                icon: Icons.label,
                                label: 'Nombre',
                                value: area?.nombre ?? 'Cargando...',
                              ),
                              if (area != null)
                                _InfoRow(
                                  icon: Icons.attach_money,
                                  label: 'Tarifa/hora',
                                  value:
                                      'S/. ${area!.tarifaPorHora.toStringAsFixed(2)}',
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Card de instalación
                          _ModernCard(
                            icon: Icons.location_on,
                            title: 'Instalación',
                            children: [
                              _InfoRow(
                                icon: Icons.business,
                                label: 'Nombre',
                                value: inst?.nombre ?? 'Cargando...',
                              ),
                              _InfoRow(
                                icon: Icons.place,
                                label: 'Dirección',
                                value: inst?.direccion ?? 'No disponible',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Card de pago
                          _ModernCard(
                            icon: Icons.payment,
                            title: 'Información de Pago',
                            children: [
                              _InfoRow(
                                icon: Icons.monetization_on,
                                label: 'Monto pagado',
                                value: r.montoPagado != null
                                    ? 'S/. ${r.montoPagado!.toStringAsFixed(2)}'
                                    : 'No especificado',
                              ),
                              _InfoRow(
                                icon: Icons.credit_card,
                                label: 'Método',
                                value: r.metodoPago ?? 'No especificado',
                              ),
                              if (r.culqiChargeId != null)
                                _InfoRow(
                                  icon: Icons.receipt,
                                  label: 'ID Culqi',
                                  value: r.culqiChargeId!,
                                ),
                              if (r.paypalPaymentId != null)
                                _InfoRow(
                                  icon: Icons.receipt_long,
                                  label: 'ID PayPal',
                                  value: r.paypalPaymentId!,
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _duracionLabel(String inicio, String fin) {
    int toMin(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    final diff = toMin(fin) - toMin(inicio);
    if (diff >= 60) {
      if (diff % 60 == 0) return '${diff ~/ 60} h';
      return '${(diff / 60).toStringAsFixed(1)} h';
    }
    return '$diff min';
  }
}

class _ModernCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ModernCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la card
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.green.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Contenido
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
