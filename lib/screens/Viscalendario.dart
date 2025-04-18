import 'package:ap/main.dart';
import 'package:flutter/material.dart';

class Viscalendario extends StatefulWidget {
  const Viscalendario({super.key});

  @override
  State<Viscalendario> createState() => _ViscalendarioState();
}

class _ViscalendarioState extends State<Viscalendario> {
  DateTime selectedDate = DateTime.now();
  late DateTime displayMonth;

  // Mapa de actividades por fecha (clave: "año-mes-día")
  Map<String, List<String>> actividades = {};

  @override
  void initState() {
    super.initState();
    displayMonth = DateTime(selectedDate.year, selectedDate.month);
  }

  // Obtener una clave de fecha formateada
  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  // Obtener actividades para una fecha
  List<String> _getActividades(DateTime date) {
    String key = _getDateKey(date);
    return actividades[key] ?? [];
  }

  // Obtener nombre del mes
  String _getMonthName(int month) {
    List<String> months = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre",
    ];
    return months[month - 1];
  }

  // Ir al mes anterior
  void _prevMonth() {
    setState(() {
      if (displayMonth.month == 1) {
        displayMonth = DateTime(displayMonth.year - 1, 12);
      } else {
        displayMonth = DateTime(displayMonth.year, displayMonth.month - 1);
      }
    });
  }

  // Ir al mes siguiente
  void _nextMonth() {
    setState(() {
      if (displayMonth.month == 12) {
        displayMonth = DateTime(displayMonth.year + 1, 1);
      } else {
        displayMonth = DateTime(displayMonth.year, displayMonth.month + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: Column(
        children: [
          // Navegación del mes
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _prevMonth,
                ),
                Text(
                  "${_getMonthName(displayMonth.month)} ${displayMonth.year}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Encabezados de los días de la semana
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text("L", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("M", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("X", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("J", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("V", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("S", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("D", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Calendario
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CalendarGrid(
                displayMonth: displayMonth,
                selectedDate: selectedDate,
                onSelectDate: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
                getActividades: _getActividades,
              ),
            ),
          ),

          // Información del día seleccionado
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "${selectedDate.day} de ${_getMonthName(selectedDate.month)} de ${selectedDate.year}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Lista de actividades
          Expanded(
            child:
                _getActividades(selectedDate).isEmpty
                    ? const Center(
                      child: Text('No hay actividades para este día'),
                    )
                    : ListView.builder(
                      itemCount: _getActividades(selectedDate).length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.event, color: Colors.white),
                          ),
                          title: Text(_getActividades(selectedDate)[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                String key = _getDateKey(selectedDate);
                                if (actividades.containsKey(key)) {
                                  actividades[key]?.removeAt(index);
                                  if (actividades[key]!.isEmpty) {
                                    actividades.remove(key);
                                  }
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddActivityDialog();
        },
      ),
    );
  }

  void _showAddActivityDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Agregar actividad'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nombre de la actividad',
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Agregar'),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      String key = _getDateKey(selectedDate);
                      if (actividades.containsKey(key)) {
                        actividades[key]!.add(controller.text);
                      } else {
                        actividades[key] = [controller.text];
                      }
                    });
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
    );
  }
}

class CalendarGrid extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime selectedDate;
  final Function(DateTime) onSelectDate;
  final List<String> Function(DateTime) getActividades;

  const CalendarGrid({
    super.key,
    required this.displayMonth,
    required this.selectedDate,
    required this.onSelectDate,
    required this.getActividades,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> calendarCells = [];

    // Determinar el primer día del mes
    DateTime firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    int firstWeekday = firstDay.weekday; // 1 = lunes, 7 = domingo

    // Agregar días del mes anterior para completar la primera semana
    DateTime prevMonth;
    if (displayMonth.month == 1) {
      prevMonth = DateTime(displayMonth.year - 1, 12);
    } else {
      prevMonth = DateTime(displayMonth.year, displayMonth.month - 1);
    }

    int daysInPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;

    for (int i = 0; i < firstWeekday - 1; i++) {
      final date = DateTime(
        prevMonth.year,
        prevMonth.month,
        daysInPrevMonth - (firstWeekday - 2 - i),
      );
      calendarCells.add(_buildDayCell(date, false));
    }

    // Agregar días del mes actual
    int daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(displayMonth.year, displayMonth.month, i);
      calendarCells.add(_buildDayCell(date, true));
    }

    // Agregar días del mes siguiente para completar la última semana
    int remainingCells =
        42 - calendarCells.length; // 6 filas x 7 días = 42 celdas en total

    DateTime nextMonth;
    if (displayMonth.month == 12) {
      nextMonth = DateTime(displayMonth.year + 1, 1);
    } else {
      nextMonth = DateTime(displayMonth.year, displayMonth.month + 1);
    }

    for (int i = 1; i <= remainingCells; i++) {
      final date = DateTime(nextMonth.year, nextMonth.month, i);
      calendarCells.add(_buildDayCell(date, false));
    }

    return GridView.count(crossAxisCount: 7, children: calendarCells);
  }

  Widget _buildDayCell(DateTime date, bool isCurrentMonth) {
    bool isSelected =
        date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;

    bool hasActivities = getActividades(date).isNotEmpty;

    return GestureDetector(
      onTap: () => onSelectDate(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${date.day}",
              style: TextStyle(
                color:
                    !isCurrentMonth
                        ? Colors.grey
                        : isSelected
                        ? Colors.white
                        : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasActivities)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
