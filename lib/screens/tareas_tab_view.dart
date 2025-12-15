import 'package:avas_eto/controller/tareas_controller.dart';
import 'package:flutter/material.dart';
import '../models/tarea.dart';
import 'tareas_list.dart';

class TareasTabsView extends StatelessWidget {
  final TareasController controller;
  final Function(Tarea) onEliminar;
  final Function(Tarea) onEditar;
  final Function(Tarea, bool) onCheck;
  final Function(Tarea) onToggle;

  const TareasTabsView({
    super.key,
    required this.controller,
    required this.onEliminar,
    required this.onEditar,
    required this.onCheck,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        TareasList(
          tareas: controller.filtrar(false),
          expandida: controller.tareasExpandida,
          onToggle: onToggle,
          onEliminar: onEliminar,
          onEditar: onEditar,
          onCheck: onCheck,
        ),
        TareasList(
          tareas: controller.filtrar(true),
          expandida: controller.tareasExpandida,
          onToggle: onToggle,
          onEliminar: onEliminar,
          onEditar: onEditar,
          onCheck: onCheck,
        ),
      ],
    );
  }
}
