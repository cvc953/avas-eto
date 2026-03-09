import 'package:flutter/material.dart';
import '../models/tarea.dart';
import 'tareas_list.dart';

class TareasTabsView extends StatelessWidget {
  final List<Tarea> tareasPendientes;
  final List<Tarea> tareasCompletadas;
  final Function(Tarea) onEliminar;
  final Function(Tarea) onEditar;
  final Function(Tarea, bool) onCheck;

  const TareasTabsView({
    super.key,
    required this.tareasPendientes,
    required this.tareasCompletadas,
    required this.onEliminar,
    required this.onEditar,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        TareasList(
          tareas: tareasPendientes,
          onEliminar: onEliminar,
          onEditar: onEditar,
          onCheck: onCheck,
        ),
        TareasList(
          tareas: tareasCompletadas,
          onEliminar: onEliminar,
          onEditar: onEditar,
          onCheck: onCheck,
        ),
      ],
    );
  }
}
