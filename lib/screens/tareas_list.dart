import 'package:avas_eto/models/tarea.dart';
import 'package:avas_eto/widgets/tarea_card.dart';
import 'package:flutter/material.dart';

class TareasList extends StatefulWidget {
  final List<Tarea> tareas;
  final void Function(Tarea) onEliminar;
  final void Function(Tarea) onEditar;
  final void Function(Tarea, bool) onCheck;

  const TareasList({
    super.key,
    required this.tareas,
    required this.onEliminar,
    required this.onEditar,
    required this.onCheck,
  });

  @override
  State<TareasList> createState() => _TareasListState();
}

class _TareasListState extends State<TareasList> {
  late List<Tarea> _tareasLocales;

  @override
  void initState() {
    super.initState();
    _tareasLocales = List.from(widget.tareas);
  }

  @override
  void didUpdateWidget(TareasList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tareas != oldWidget.tareas) {
      _tareasLocales = List.from(widget.tareas);
    }
  }

  void _handleCheck(Tarea tarea, bool completada) {
    // Mover la tarea al final de la lista antes de llamar el callback
    setState(() {
      final index = _tareasLocales.indexWhere((t) => t.id == tarea.id);
      if (index != -1) {
        final tareaActualizada = _tareasLocales[index].copyWith(completada: completada);
        _tareasLocales.removeAt(index);
        _tareasLocales.add(tareaActualizada);
      }
    });

    // Llamar el callback original
    widget.onCheck(tarea, completada);
  }

  @override
  Widget build(BuildContext context) {
    if (_tareasLocales.isEmpty) {
      return Center(
        child: Text(
          'No hay tareas',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final tarea = _tareasLocales[index];
            return TareaCard(
              key: ValueKey(tarea.id),
              tarea: tarea,
              onCheck: (val) => _handleCheck(tarea, val ?? false),
              onTap: () => widget.onEditar(tarea),
            );
          }, childCount: _tareasLocales.length),
        ),
      ],
    );
  }
}
