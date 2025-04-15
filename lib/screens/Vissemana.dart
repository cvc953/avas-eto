import 'package:flutter/material.dart';

class Vissemana extends StatefulWidget {
  const Vissemana({super.key});

  @override
  _VissemanaState createState() => _VissemanaState();
}

class _VissemanaState extends State<Vissemana> {
  DateTime _selectedDay = DateTime.now();

  // Obtener el primer día de la semana
  DateTime get _firstDayOfWeek {
    return _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
  }

  // Lista de horas del día (de 6:00 AM a 10:00 PM)
  final List<String> _horas = List.generate(
    17,
    (index) =>
        "${(index + 6) % 12 == 0 ? 12 : (index + 6) % 12}:00 ${index + 6 < 12 ? "AM" : "PM"}",
  );

  // Ejemplo de tareas organizadas por fecha y hora
  final Map<String, List<String>> _tareas = {
    "2025-04-07-10": ["Reunión de equipo"],
    "2025-04-08-14": ["Entrega de proyecto"],
    "2025-04-09-16": ["Estudio de arquitectura"],
  };

  // Obtener una clave única para cada combinación de fecha y hora
  String _getTaskKey(DateTime date, int hour) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-$hour";
  }

  // Obtener tareas para una fecha y hora específica
  List<String> _getTasksForHour(DateTime date, int hour) {
    final key = _getTaskKey(date, hour);
    return _tareas[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista Semanal')),
      body: Column(
        children: [
          // Header con días de la semana
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final day = _firstDayOfWeek.add(Duration(days: index));
                final isSelected =
                    day.day == _selectedDay.day &&
                    day.month == _selectedDay.month &&
                    day.year == _selectedDay.year;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[300] : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ['L', 'M', 'X', 'J', 'V', 'S', 'D'][index],
                          style: TextStyle(
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        Text(
                          "${day.day}",
                          style: TextStyle(
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // Título del día seleccionado
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Text(
                  _getDayTitle(_selectedDay),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addTask(),
                  tooltip: 'Agregar tarea',
                ),
              ],
            ),
          ),
          // Lista de horas con tareas
          Expanded(
            child: ListView.builder(
              itemCount: _horas.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final hour = index + 6; // Hora actual (6AM + index)
                final hourString = _horas[index];
                final tasks = _getTasksForHour(_selectedDay, hour);

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hora
                        SizedBox(
                          width: 70,
                          child: Text(
                            hourString,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Línea vertical
                        Container(
                          width: 1,
                          height: tasks.isEmpty ? 40 : null,
                          color: Colors.grey.withOpacity(0.5),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        // Tareas
                        Expanded(
                          child:
                              tasks.isEmpty
                                  ? const SizedBox(height: 40)
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        tasks.map((task) {
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.blueAccent,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.task_alt,
                                                  color: Colors.blueAccent,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text(task)),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 16,
                                                  ),
                                                  onPressed: () {
                                                    // Implementar eliminar tarea
                                                    _deleteTask(hour, task);
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Obtener título del día
  String _getDayTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate.isAtSameMomentAs(today)) {
      return 'Hoy, ${_formatDate(date)}';
    } else if (selectedDate.isAtSameMomentAs(yesterday)) {
      return 'Ayer, ${_formatDate(date)}';
    } else if (selectedDate.isAtSameMomentAs(tomorrow)) {
      return 'Mañana, ${_formatDate(date)}';
    } else {
      return _formatDate(date);
    }
  }

  // Formatear fecha
  String _formatDate(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final weekday =
        date.weekday > 0 && date.weekday <= 7 ? date.weekday - 1 : 0;

    return '${days[weekday]} ${date.day} de ${months[date.month - 1]}';
  }

  // Agregar tarea
  void _addTask() {
    final taskController = TextEditingController();
    int selectedHour = DateTime.now().hour;

    if (selectedHour < 6) selectedHour = 6;
    if (selectedHour > 22) selectedHour = 22;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Agregar tarea'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: taskController,
                    decoration: const InputDecoration(
                      labelText: 'Tarea',
                      hintText: 'Nombre de la tarea',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Hora:'),
                  DropdownButton<int>(
                    value: selectedHour,
                    isExpanded: true,
                    items: List.generate(17, (index) {
                      final hour = index + 6;
                      return DropdownMenuItem<int>(
                        value: hour,
                        child: Text(_horas[index]),
                      );
                    }),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedHour = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (taskController.text.isNotEmpty) {
                      setState(() {
                        final key = _getTaskKey(_selectedDay, selectedHour);
                        final tasks = _tareas[key] ?? [];
                        tasks.add(taskController.text);
                        _tareas[key] = tasks;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Eliminar tarea
  void _deleteTask(int hour, String task) {
    setState(() {
      final key = _getTaskKey(_selectedDay, hour);
      if (_tareas.containsKey(key)) {
        _tareas[key]!.remove(task);
        if (_tareas[key]!.isEmpty) {
          _tareas.remove(key);
        }
      }
    });
  }
}
