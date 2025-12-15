import 'package:avas_eto/models/tarea.dart';
import 'package:avas_eto/widgets/tarea_card.dart';
import 'package:flutter/material.dart';

class TareasList extends StatelessWidget {
  final List<Tarea> tareas;
  final Set<Tarea> expandida;
  final void Function(Tarea) onToggle;
  final void Function(Tarea) onEliminar;
  final void Function(Tarea) onEditar;
  final void Function(Tarea, bool) onCheck;

  const TareasList({
    super.key,
    required this.tareas,
    required this.expandida,
    required this.onToggle,
    required this.onEliminar,
    required this.onEditar,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    if (tareas.isEmpty) {
      return Center(
        child: Text(
          'No hay tareas',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final tarea = tareas[index];
            final isExpandida = expandida.contains(tarea);
            return TareaCard(
              key: ValueKey('${tarea.id}_$isExpandida'),
              tarea: tarea,
              expandida: isExpandida,
              onToggleExpand: () => onToggle(tarea),
              onCheck: (val) => onCheck(tarea, val ?? false),
              onEliminar: () => onEliminar(tarea),
              onEditar: () => onEditar(tarea),
            );
          }, childCount: tareas.length),
        ),
      ],
    );
  }
}
