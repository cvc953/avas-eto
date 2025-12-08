import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/tarea.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarioTareas extends StatefulWidget {
  final List<Color> coloresDisponibles;
  const CalendarioTareas({Key? key, required this.coloresDisponibles})
    : super(key: key);

  @override
  State<CalendarioTareas> createState() => _CalendarioTareasState();
}

class _CalendarioTareasState extends State<CalendarioTareas> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Tarea>> _tareasPorDia = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTareas();
  }

  Future<void> _loadTareas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('tareas')
            .where('userId', isEqualTo: user.uid)
            .get();
    final tareasPorDia = <DateTime, List<Tarea>>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();

      final tarea = Tarea(
        id: doc.id,
        title: data['titulo'] ?? '',
        materia: data['materia'] ?? '',
        descripcion: data['descripcion'] ?? '',
        profesor: data['profesor'] ?? '',
        creditos: data['creditos'] ?? 0,
        nrc: data['nrc'] ?? 0,
        prioridad: data['prioridad'] ?? 'Media',
        color: Color(int.parse(data['color'] ?? '0xFF000000', radix: 16)),
        completada: data['completada'] ?? false,
        fechaCreacion: DateTime.now(),
      );
      final fechaFinal = data['fecha'] as String;
      tareasPorDia.putIfAbsent(fechaFinal as DateTime, () => []).add(tarea);
    }
    setState(() {
      _tareasPorDia = tareasPorDia;
      _loading = false;
    });
  }

  List<Tarea> _getTareasDelDia(DateTime day) {
    return _tareasPorDia[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de Tareas')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate:
                          (day) => isSameDay(_selectedDay, day),
                      eventLoader: _getTareasDelDia,
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                  ),
                  Expanded(
                    child:
                        _selectedDay == null ||
                                _getTareasDelDia(_selectedDay!).isEmpty
                            ? const Center(
                              child: Text('No hay tareas para este día'),
                            )
                            : ListView(
                              children:
                                  _getTareasDelDia(_selectedDay!)
                                      .map(
                                        (tarea) => ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: tarea.color,
                                            child: const Icon(
                                              Icons.menu_book,
                                              color: Colors.white,
                                            ),
                                          ),
                                          title: Text(tarea.title),
                                          subtitle: Text(
                                            'prioridad: ${tarea.prioridad}',
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                  ),
                ],
              ),
    );
  }
}
