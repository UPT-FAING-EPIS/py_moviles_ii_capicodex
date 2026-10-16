import 'package:flutter/material.dart';
import 'package:gameon/features/reservas/viewmodels/reserva_calendario_viewmodel.dart';

class SlotsGrid extends StatefulWidget {
  final ReservaCalendarioViewModel viewModel;
  final VoidCallback? onSelectionChanged;
  const SlotsGrid({
    super.key,
    required this.viewModel,
    this.onSelectionChanged,
  });

  @override
  State<SlotsGrid> createState() => _SlotsGridState();
}

class _SlotsGridState extends State<SlotsGrid> {
  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    if (vm.selectedDay == null) return const SizedBox.shrink();

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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.schedule, color: Colors.green[700], size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Selecciona un horario',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (vm.slots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No hay horarios disponibles para este día',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: vm.slots.length,
              itemBuilder: (context, index) {
                final t = vm.slots[index];
                final start = vm.startTime;
                final end = vm.endTime;
                final isOcupado = vm.isSlotOcupado(t);

                bool selected = false;
                if (start != null && end == null) {
                  selected = start == t;
                } else if (start != null && end != null) {
                  final tMin = t.hour * 60 + t.minute;
                  final sMin = start.hour * 60 + start.minute;
                  final eMin = end.hour * 60 + end.minute;
                  selected = tMin >= sMin && tMin <= eMin;
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isOcupado
                        ? null
                        : () => setState(() {
                            vm.seleccionarHora(t);
                            widget.onSelectionChanged?.call();
                          }),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient:
                            selected &&
                                vm.endTime != null &&
                                vm.startTime != null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.green[600]!,
                                  Colors.green[800]!,
                                ],
                              )
                            : null,
                        color: isOcupado
                            ? Colors.red[100]
                            : selected &&
                                  (vm.endTime == null || vm.startTime == null)
                            ? Colors.green[700]
                            : Colors.grey[50],
                        border: Border.all(
                          color: isOcupado
                              ? Colors.red[300]!
                              : selected
                              ? Colors.green[700]!
                              : Colors.grey[200]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t.format(context),
                              style: TextStyle(
                                color: isOcupado
                                    ? Colors.red[700]
                                    : selected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: selected || isOcupado
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (isOcupado)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Ocupado',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
