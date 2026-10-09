import 'package:flutter/material.dart';
import 'package:gameon/features/reservas/views/reservas_list/widgets/estado_chip.dart';
import 'package:gameon/features/reservas/views/reservas_list/widgets/info_chip.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/reservas_list_viewmodel.dart';
import 'reserva_detail_view.dart';

class ReservaCard extends StatefulWidget {
  final dynamic reserva; // Reserva
  const ReservaCard({required this.reserva});

  @override
  State<ReservaCard> createState() => ReservaCardState();
}

class ReservaCardState extends State<ReservaCard> {
  AreaLite? area;
  InstitucionLite? inst;
  bool loadingExtra = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    if (!loadingExtra) return;
    final vm = context.read<ReservasListViewModel>();
    final a = await vm.getArea(widget.reserva.areaDeportivaId as int);
    final i = a == null ? null : await vm.getInstitucion(a.institucionId);
    if (mounted) {
      setState(() {
        area = a;
        inst = i;
        loadingExtra = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final estado = r.estado as String;
    final colorEstado = _estadoColor(estado, context);
    final icono = _estadoIcon(estado);
    final inicio = (r.horaInicio as String).substring(0, 5);
    final fin = (r.horaFin as String).substring(0, 5);
    final duracion = _duracionMin(r.horaInicio, r.horaFin);
    final durLabel = duracion >= 60
        ? '${(duracion / 60).toStringAsFixed(duracion % 60 == 0 ? 0 : 1)} h'
        : '$duracion min';

    final areaNombre = loadingExtra
        ? 'Cargando área...'
        : (area?.nombre ?? 'Área desconocida');
    final instNombre = loadingExtra ? '' : (inst?.nombre ?? '');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorEstado.withOpacity(.15), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ReservaDetailView.fromId(reservaId: r.id as int),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorEstado.withOpacity(.15),
                            colorEstado.withOpacity(.25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icono, color: colorEstado, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reserva #${r.id}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            areaNombre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    EstadoChip(estado: estado),
                  ],
                ),
                const SizedBox(height: 14),
                if (!loadingExtra && area?.imagenArea != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        area!.imagenArea!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (instNombre.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          instNombre,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      icon: Icons.schedule,
                      label: '$inicio - $fin',
                      color: Colors.blue,
                    ),
                    InfoChip(
                      icon: Icons.timelapse,
                      label: durLabel,
                      color: Colors.orange,
                    ),
                    if (r.montoPagado != null)
                      InfoChip(
                        icon: Icons.payments,
                        label: 'S/. ${r.montoPagado.toStringAsFixed(2)}',
                        color: Colors.green,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _duracionMin(String inicio, String fin) {
    int _toMin(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    return _toMin(fin) - _toMin(inicio);
  }

  Color _estadoColor(String estado, BuildContext context) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange.shade600;
      case 'confirmada':
      case 'pagada':
        return Colors.green.shade600;
      case 'cancelada':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _estadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.hourglass_top_rounded;
      case 'confirmada':
        return Icons.event_available_rounded;
      case 'pagada':
        return Icons.verified_rounded;
      case 'cancelada':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
