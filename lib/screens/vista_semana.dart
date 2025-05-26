import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tarea.dart';
import '../dialogs/agregar_tarea.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

class VisSemana extends StatefulWidget {
  final List<Color> coloresDisponibles;

  const VisSemana({super.key, required this.coloresDisponibles});

  @override
  _VisSemanaState createState() => _VisSemanaState();
}

class _VisSemanaState extends State<VisSemana> {
  DateTime _selectedDay = DateTime.now();
  Map<String, List<Tarea>> _tareas = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es');
    _selectedDay = DateTime.now();
    _setupFirestoreListener();
  }

  DateTime get _firstDayOfWeek {
    return _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
  }

  String _getTaskKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _cargarTareas() async {
    setState(() => _isLoading = true);

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
      _isLoading = false;
    });
  }

  void _setupFirestoreListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('tareas')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

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
                color: Color(
                  int.parse(data['color'] ?? '0xFF000000', radix: 16),
                ),
                completada: data['completada'] ?? false,
                fechaCreacion: (data['creadoEn'] as Timestamp).toDate(),
              );

              final clave = data['fecha'] as String;
              _tareas.putIfAbsent(clave, () => []).add(tarea);
            }
            _isLoading = false;
          });
        });
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
        'creadoEn': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      await _cargarTareas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    }
  }

  void _agregarTarea(DateTime dia) {
    showAddTaskDialog(
      context: context,
      onSave: _guardarTarea,
      initialDate: dia,
      availableColors: widget.coloresDisponibles,
    );
  }

  List<Tarea> _tareasDelDia(DateTime day) {
    final clave = _getTaskKey(day);
    return _tareas[clave] ?? [];
  }

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

  String _formatDate(DateTime date) {
    final format = DateFormat('EEEE d MMMM', 'es');
    return format.format(date);
  }

  String _formatHour(int hour) {
    final time = TimeOfDay(hour: hour, minute: 0);
    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Semanal'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarTareas),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
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
                              color:
                                  isSelected
                                      ? Colors.blue[300]
                                      : Colors.transparent,
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
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
                          onPressed: () => _agregarTarea(_selectedDay),
                          tooltip: 'Agregar tarea',
                        ),
                      ],
                    ),
                  ),
                  // Lista de horas con tareas
                  Expanded(
                    child: ListView.builder(
                      itemCount: 17, // De 6AM a 10PM (17 horas)
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final hour = index + 6; // Hora actual (6AM + index)
                        final hourString = _formatHour(hour);
                        final tasks =
                            _tareasDelDia(_selectedDay).where((t) {
                              final taskHour =
                                  int.tryParse(t.id.split('-').last) ?? hour;
                              return taskHour == hour;
                            }).toList();

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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Línea vertical
                                Container(
                                  width: 1,
                                  height: tasks.isEmpty ? 40 : null,
                                  color: Colors.grey.withOpacity(0.5),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
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
                                                tasks.map((tarea) {
                                                  return Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: tarea.color
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: tarea.color,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          tarea.completada
                                                              ? Icons
                                                                  .check_circle
                                                              : Icons
                                                                  .circle_outlined,
                                                          color: tarea.color,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                tarea.title,
                                                                style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  decoration:
                                                                      tarea.completada
                                                                          ? TextDecoration
                                                                              .lineThrough
                                                                          : null,
                                                                ),
                                                              ),
                                                              if (tarea
                                                                  .descripcion
                                                                  .isNotEmpty)
                                                                Text(
                                                                  tarea
                                                                      .descripcion,
                                                                  style:
                                                                      const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons
                                                                .delete_outline,
                                                            size: 16,
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  _eliminarTarea(
                                                                    tarea,
                                                                  ),
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
        onPressed: () => _agregarTarea(_selectedDay),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTareaItem(Tarea tarea) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tarea.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tarea.color, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            tarea.completada ? Icons.check_circle : Icons.circle_outlined,
            color: tarea.color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration:
                        tarea.completada ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (tarea.descripcion.isNotEmpty)
                  Text(tarea.descripcion, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            onPressed: () => _eliminarTarea(tarea),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta tarea?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmado == true) {
      try {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(tarea.id)
            .delete();
        await _cargarTareas();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
        );
      }
    }
  }
}
