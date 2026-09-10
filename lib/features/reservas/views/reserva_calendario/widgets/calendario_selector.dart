import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gameon/features/reservas/viewmodels/reserva_calendario_viewmodel.dart';

class CalendarioSelector extends StatefulWidget {
  final ReservaCalendarioViewModel viewModel;
  final VoidCallback? onChanged;
  const CalendarioSelector({
    super.key,
    required this.viewModel,
    this.onChanged,
  });

  @override
  State<CalendarioSelector> createState() => _CalendarioSelectorState();
}

class _CalendarioSelectorState extends State<CalendarioSelector> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
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
                child: Icon(
                  Icons.calendar_month,
                  color: Colors.green[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Selecciona una fecha',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Envolver el calendario para permitir scroll vertical en la vista
          // mientras se mantiene el scroll horizontal para cambiar meses
          IgnorePointer(
            ignoring: false,
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 60)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(vm.selectedDay, day),
              enabledDayPredicate: (day) => vm.diaDisponible(day),
              onDaySelected: (selectedDay, focusedDay) async {
                setState(() => _focusedDay = focusedDay);
                await vm.seleccionarDiaAsync(selectedDay);
                if (mounted) widget.onChanged?.call();
              },
              calendarFormat: CalendarFormat.month,
              // Deshabilitar gestos de página en el calendario
              // para que no interfiera con el scroll vertical
              availableGestures: AvailableGestures.horizontalSwipe,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Colors.green[700],
                  size: 28,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.green[700],
                  size: 28,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: Colors.green[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.green[300],
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[800]!],
                  ),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                defaultDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!),
                ),
                weekendDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green[100]!),
                ),
                disabledDecoration: BoxDecoration(shape: BoxShape.circle),
                disabledTextStyle: TextStyle(color: Colors.grey[300]),
                outsideDaysVisible: false,
                cellMargin: const EdgeInsets.all(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
