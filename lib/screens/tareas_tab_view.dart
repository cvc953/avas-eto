import 'package:avas_eto/controller/tareas_controller.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/tarea.dart';
import 'tareas_list.dart';

class TareasTabsView extends StatelessWidget {
  final Function(Tarea) onEliminar;
  final Function(Tarea) onEditar;
  final Function(Tarea, bool) onCheck;

  const TareasTabsView({
    super.key,
    required this.onEliminar,
    required this.onEditar,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TareasController>(context, listen: false);

    return TabBarView(
      children: [
        TareasList(
          tareas: controller.filtrar(false),
          onEliminar: onEliminar,
          onEditar: onEditar,
          onCheck: onCheck,
        ),
        TareasList(
          tareas: controller.filtrar(true),
          onEliminar: onEliminar,
          onEditar: onEditar,
          onCheck: onCheck,
        ),
      ],
    );
  }
}
