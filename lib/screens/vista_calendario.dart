import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/tarea.dart';
import '../dialogs/agregar_tarea.dart';
import '../services/local_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarioTareas extends StatefulWidget {
  final List<Color> coloresDisponibles;

  const CalendarioTareas({super.key, required this.coloresDisponibles});

  @override
  _CalendarioTareasState createState() => _CalendarioTareasState();
}

class _CalendarioTareasState extends State<CalendarioTareas> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<String, List<Tarea>> _tareas;
  final LocalDatabase _localDb = LocalDatabase();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _tareas = {};
    _cargarTareas();
  }

  Future<void> _cargarTareas() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('tareas')
            .where('userId', isEqualTo: userId)
            .get();

    setState(() {
      _tareas.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final tarea = Tarea(
          id: doc.id,
          title: data['titulo'] ?? '',
          descripcion: data['descripcion'] ?? '',
          profesor: data['profesor'] ?? '',
          creditos: data['creditos'] ?? 0,
          nrc: data['nrc'] ?? 0,
          prioridad: data['prioridad'] ?? 'Media',
          color: Color(int.parse(data['color'] ?? '0xFF000000', radix: 16)),
          completada: data['completada'] ?? false,
          fechaCreacion: (data['creadoEn'] as Timestamp).toDate(),
        );

        final clave = data['fecha'] as String;
        _tareas.putIfAbsent(clave, () => []).add(tarea);
      }
    });
  }

  String _getTaskKey(DateTime day, int hour) {
    return '${day.year}-${day.month}-${day.day}-$hour';
  }

  Future<void> _guardarTarea(Tarea tarea, String clave) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await FirebaseFirestore.instance.collection('tareas').add({
        'titulo': tarea.title,
        'descripcion': tarea.descripcion,
        'profesor': tarea.profesor,
        'creditos': tarea.creditos,
        'nrc': tarea.nrc,
        'prioridad': tarea.prioridad,
        'color': tarea.color.value.toRadixString(16),
        'completada': tarea.completada,
        'fecha': clave,
        'hora': clave.split('-').last,
        'creadoEn': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      await _cargarTareas(); // Recargar tareas después de guardar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    }
  }

  void _agregarTarea(DateTime selectedDay) {
    showAddTaskDialog(
      context: context,
      onSave: _guardarTarea,
      initialDate: selectedDay,
      availableColors: widget.coloresDisponibles,
    );
  }

  List<Tarea> _tareasDelDia(DateTime day) {
    final clave = '${day.year}-${day.month}-${day.day}';
    return _tareas.entries
        .where((entry) => entry.key.startsWith(clave))
        .expand((entry) => entry.value)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tareasHoy = _tareasDelDia(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _agregarTarea(_selectedDay),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              return _tareasDelDia(day).isNotEmpty ? ['Tareas'] : [];
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tareasHoy.length,
              itemBuilder: (context, index) {
                final tarea = tareasHoy[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tarea.color,
                      child: const Icon(Icons.assignment, color: Colors.white),
                    ),
                    title: Text(tarea.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tarea.descripcion),
                        Text('Prioridad: ${tarea.prioridad}'),
                      ],
                    ),
                    trailing: Checkbox(
                      value: tarea.completada,
                      onChanged: (value) {
                        // Implementar lógica para marcar como completada
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _agregarTarea(_selectedDay),
        child: const Icon(Icons.add),
      ),
    );
  }
}
