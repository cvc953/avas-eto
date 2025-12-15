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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de Tareas')),
      body:
          user == null
              ? const Center(
                child: Text('Inicia sesión para ver el calendario'),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('tareas')
                        .where('userId', isEqualTo: user.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Procesar tareas y agruparlas por día
                  final tareasPorDia = <DateTime, List<Tarea>>{};

                  for (var doc in snapshot.data?.docs ?? []) {
                    try {
                      final data = doc.data() as Map<String, dynamic>;
                      final fecha = data['fecha'] as String?;

                      if (fecha == null) continue;

                      final dateOnly = fecha.split('-').take(3).join('-');
                      final parsedDate = DateTime.parse(dateOnly);

                      final tarea = Tarea(
                        id: doc.id,
                        title: data['titulo'] ?? 'Sin título',
                        descripcion: data['descripcion'] ?? '',
                        prioridad: data['prioridad'] ?? 'Media',
                        color: Color(
                          int.tryParse(
                                data['color'] ?? '0xFF000000',
                                radix: 16,
                              ) ??
                              0xFF000000,
                        ),
                        completada: data['completada'] ?? false,
                        fechaCreacion:
                            data['creadoEn'] != null
                                ? (data['creadoEn'] as Timestamp).toDate()
                                : DateTime.now(),
                        fechaVencimiento: parsedDate,
                        fechaCompletada: DateTime.now(),
                      );

                      tareasPorDia.putIfAbsent(parsedDate, () => []).add(tarea);
                    } catch (e) {
                      debugPrint('Error procesando documento: $e');
                    }
                  }

                  return Column(
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
                          eventLoader:
                              (day) =>
                                  tareasPorDia[DateTime(
                                    day.year,
                                    day.month,
                                    day.day,
                                  )] ??
                                  [],
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              final tareas =
                                  tareasPorDia[DateTime(
                                    day.year,
                                    day.month,
                                    day.day,
                                  )] ??
                                  [];
                              final hasEvents = tareas.isNotEmpty;

                              return Container(
                                margin: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      hasEvents
                                          ? Colors.blue.withValues(alpha: 0.3)
                                          : Colors.transparent,
                                  border:
                                      isSameDay(day, _selectedDay)
                                          ? Border.all(
                                            color: Colors.blue,
                                            width: 2,
                                          )
                                          : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      day.day.toString(),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    if (hasEvents)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              final tareas =
                                  tareasPorDia[DateTime(
                                    day.year,
                                    day.month,
                                    day.day,
                                  )] ??
                                  [];
                              final hasEvents = tareas.isNotEmpty;

                              return Container(
                                margin: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                  border:
                                      hasEvents
                                          ? Border.all(
                                            color: Colors.red,
                                            width: 2,
                                          )
                                          : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      day.day.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (hasEvents)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
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
                                    (tareasPorDia[DateTime(
                                              _selectedDay!.year,
                                              _selectedDay!.month,
                                              _selectedDay!.day,
                                            )] ??
                                            [])
                                        .isEmpty
                                ? const Center(
                                  child: Text('No hay tareas para este día'),
                                )
                                : ListView(
                                  children:
                                      (tareasPorDia[DateTime(
                                                _selectedDay!.year,
                                                _selectedDay!.month,
                                                _selectedDay!.day,
                                              )] ??
                                              [])
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
                  );
                },
              ),
    );
  }
}
