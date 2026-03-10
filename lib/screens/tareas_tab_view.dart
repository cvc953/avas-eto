import 'package:flutter/material.dart';
import '../models/tarea.dart';
import 'tareas_list.dart';

class TareasTabsView extends StatelessWidget {
  final List<Tarea> tareasFoco;
  final List<Tarea> tareasTodas;
  final Function(Tarea) onEliminar;
  final Function(Tarea) onEditar;
  final Function(Tarea, bool) onCheck;

  const TareasTabsView({
    super.key,
    required this.tareasFoco,
    required this.tareasTodas,
    required this.onEliminar,
    required this.onEditar,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        TareasList(
          tareas: tareasFoco,
          onEliminar: onEliminar,
          onEditar: onEditar,
          onCheck: onCheck,
        ),
        TareasList(
          tareas: tareasTodas,
          onEliminar: onEliminar,
          onEditar: onEditar,
          onCheck: onCheck,
        ),
      ],
    );
  }
}
