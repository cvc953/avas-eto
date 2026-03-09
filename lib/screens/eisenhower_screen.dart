import 'package:flutter/material.dart';
import 'package:avas_eto/controller/tareas_controller.dart';
import 'package:provider/provider.dart';
import 'package:avas_eto/dialogs/agregar_tarea.dart';
import 'package:avas_eto/dialogs/editar_tarea.dart';
import 'package:avas_eto/screens/tareas_inicio.dart';
import 'package:avas_eto/utils/task_key_generator.dart';
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
  DateTime? _lastBackPressedAt;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressedAt == null ||
        now.difference(_lastBackPressedAt!) > const Duration(seconds: 1)) {
      _lastBackPressedAt = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Presiona nuevamente para salir'),
            duration: Duration(seconds: 1),
          ),
        );
      return false;
    }
    return true;
  }

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

  Future<void> _handleToggle(Tarea tarea, bool completada) async {
    if (widget.onToggle == null) return;

    // Immediate visual feedback in the matrix.
    if (mounted) setState(() {});

    await widget.onToggle!(tarea, completada);

    // Rebuild again after controller sync/persistence.
    if (mounted) setState(() {});
  }

  Future<void> _openEditTask(Tarea tarea) async {
    if (!mounted) return;

    final controller = Provider.of<TareasController>(context, listen: false);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => EditTaskDialog(
            tarea: tarea,
            onSave: (tareaEditada, clave) {
              Navigator.pop(sheetContext, {
                'tarea': tareaEditada,
                'clave': clave,
              });
            },
            onDelete: () {
              Navigator.pop(sheetContext, {'delete': true});
            },
          ),
    );

    if (result == null || !mounted) return;

    try {
      if (result['delete'] == true) {
        await controller.eliminar(tarea, controller.isOnline);
      } else {
        final tareaEditada = result['tarea'] as Tarea;
        final nuevaClave = result['clave'] as String;
        final claveVieja = TaskKeyGenerator.generateKeyFromDateTime(
          tarea.fechaVencimiento,
        );

        if (nuevaClave == claveVieja) {
          await controller.actualizar(tareaEditada, claveVieja);
        } else {
          await controller.moverTarea(tareaEditada, claveVieja, nuevaClave);
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al editar tarea: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TareasController>(context, listen: false);
    final tareas = controller.tareas.values.expand((e) => e).toList();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Text(
            'Matriz de Eisenhower',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          automaticallyImplyLeading: false,
        ),
        body: EisenhowerMatrix(
          tareas: tareas,
          onToggle: _handleToggle,
          onTapTask: _openEditTask,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAdd,
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: widget.currentIndex,
          onSelect: (i) {
            if (i == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TareasInicio()),
              );
              return;
            }

            if (i == 2) {
              Navigator.pushReplacement(
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
      ),
    );
  }
}
