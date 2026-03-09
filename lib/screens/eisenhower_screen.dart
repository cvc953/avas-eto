import 'package:flutter/material.dart';
import 'package:avas_eto/controller/tareas_controller.dart';
import 'package:provider/provider.dart';
import 'package:avas_eto/dialogs/agregar_tarea.dart';
import 'package:avas_eto/widgets/eisenhower_matrix.dart';
import 'package:avas_eto/widgets/bottom_navigation_bar.dart';
import 'package:avas_eto/screens/more_options.dart';
import '../models/tarea.dart';

class EisenhowerScreen extends StatefulWidget {
  final Future<void> Function(Tarea tarea) onAddTask;
  final Future<void> Function(Tarea tarea, bool completada)? onToggle;
  final int currentIndex;

  const EisenhowerScreen({
    super.key,
    required this.onAddTask,
    this.onToggle,
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
    final controller = Provider.of<TareasController>(context, listen: false);
    final tareas = controller.tareas.values.expand((e) => e).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Matriz de Eisenhower',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        automaticallyImplyLeading: false,
      ),
      body: EisenhowerMatrix(tareas: tareas, onToggle: widget.onToggle),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        backgroundColor:
            Theme.of(context).floatingActionButtonTheme.backgroundColor,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: widget.currentIndex,
        onSelect: (i) {
          if (i == 1) {
            Navigator.pop(context);
            return;
          }

          if (i == 2) {
            // Push MoreOptions and pass controller + callbacks so MoreOptions can act.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => MoreOptions(
                      onAddTask: (t) async => await widget.onAddTask(t),
                      onToggle: (dynamic tarea, bool completada) async {
                        if (widget.onToggle != null) {
                          await widget.onToggle!(tarea as Tarea, completada);
                        }
                      },
                    ),
              ),
            );
            return;
          }
        },
      ),
    );
  }
}
