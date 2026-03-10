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
    // Solo resetear si cambia el conteo de tareas o hay tareas diferentes (por ID)
    if (widget.tareas.length != oldWidget.tareas.length ||
        !_tieneMismosIds(widget.tareas, oldWidget.tareas)) {
      _tareasLocales = List.from(widget.tareas);
    } else {
      // Sincronizar estados actualizados sin perder el orden local
      _sincronizarEstados();
    }
  }

  bool _tieneMismosIds(List<Tarea> lista1, List<Tarea> lista2) {
    if (lista1.length != lista2.length) return false;
    final ids1 = lista1.map((t) => t.id).toSet();
    final ids2 = lista2.map((t) => t.id).toSet();
    return ids1.difference(ids2).isEmpty && ids2.difference(ids1).isEmpty;
  }

  void _sincronizarEstados() {
    // Actualizar cada tarea local con los datos más recientes del widget
    final mapaActualizado = {for (var t in widget.tareas) t.id: t};
    setState(() {
      _tareasLocales =
          _tareasLocales.map((t) {
            return mapaActualizado[t.id] ?? t;
          }).toList();
    });
  }

  void _handleCheck(Tarea tarea, bool completada) {
    // Mover la tarea al final de la lista antes de llamar el callback
    setState(() {
      final index = _tareasLocales.indexWhere((t) => t.id == tarea.id);
      if (index != -1) {
        final tareaActualizada = _tareasLocales[index].copyWith(
          completada: completada,
        );
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
