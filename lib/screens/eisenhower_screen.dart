import 'package:flutter/material.dart';
import 'package:avas_eto/controller/tareas_controller.dart';
import 'package:avas_eto/dialogs/agregar_tarea.dart';
import 'package:avas_eto/widgets/eisenhower_matrix.dart';
import 'package:avas_eto/widgets/bottom_navigation_bar.dart';
import '../models/tarea.dart';

class EisenhowerScreen extends StatefulWidget {
  final TareasController controller;
  final Future<void> Function(Tarea tarea) onAddTask;
  final Future<void> Function(Tarea tarea, bool completada)? onToggle;
  final List<Color> coloresDisponibles;
  final int currentIndex;

  const EisenhowerScreen({
    super.key,
    required this.controller,
    required this.onAddTask,
    this.onToggle,
    this.coloresDisponibles = const [],
    this.currentIndex = 0,
  });

  @override
  State<EisenhowerScreen> createState() => _EisenhowerScreenState();
}

class _EisenhowerScreenState extends State<EisenhowerScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _showAdd() async {
    await showAddTaskDialog(
      context: context,
      onSave: (tarea, clave) async {
        await widget.onAddTask(tarea);
        setState(() {});
      },
      initialDate: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tareas = widget.controller.tareas.values.expand((e) => e).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Matriz de Eisenhower'),
        automaticallyImplyLeading: true,
      ),
      body: EisenhowerMatrix(tareas: tareas, onToggle: widget.onToggle),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar:
          widget.coloresDisponibles.isNotEmpty
              ? CustomBottomNavBar(
                parentContext: context,
                currentIndex: widget.currentIndex,
                onSelect: (i) {
                  if (i == 1) {
                    Navigator.pop(context);
                  } else if (i == 2) {
                    Navigator.pushReplacementNamed(context, '/more');
                  }
                },
                coloresDisponibles: widget.coloresDisponibles,
              )
              : null,
    );
  }
}
