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
    final colors = Theme.of(context).colorScheme;
    if (vm.selectedDay == null) return const SizedBox.shrink();

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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.schedule, color: colors.secondary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Selecciona un horario',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
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
                    Icon(
                      Icons.event_busy,
                      size: 48,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay horarios disponibles para este día',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14,
                      ),
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
                                  colors.primary,
                                  colors.primaryContainer,
                                ],
                              )
                            : null,
                        color: isOcupado
                            ? Colors.red[100]
                            : selected &&
                                  (vm.endTime == null || vm.startTime == null)
                            ? colors.primary
                            : colors.surfaceContainerHighest,
                        border: Border.all(
                          color: isOcupado
                              ? Colors.red[300]!
                              : selected
                              ? colors.primary
                              : Theme.of(context).dividerColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: .3),
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
                                    ? colors.onPrimary
                                    : colors.onSurface,
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
