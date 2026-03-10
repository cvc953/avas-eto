import 'package:flutter/material.dart';
import '../models/tarea.dart';
import 'tareas_list.dart';

class QuadrantDetailScreen extends StatefulWidget {
  final String title;
  final Color accentColor;
  final List<Tarea> tareas;
  final Function(Tarea, bool)? onToggle;
  final Function(Tarea)? onTapTask;
  final Function(Tarea)? onDelete;

  const QuadrantDetailScreen({
    super.key,
    required this.title,
    required this.accentColor,
    required this.tareas,
    this.onToggle,
    this.onTapTask,
    this.onDelete,
  });

  @override
  State<QuadrantDetailScreen> createState() => _QuadrantDetailScreenState();
}

class _QuadrantDetailScreenState extends State<QuadrantDetailScreen> {
  late List<Tarea> _tareasLocales;

  @override
  void initState() {
    super.initState();
    _tareasLocales = List.from(widget.tareas);
  }

  @override
  void didUpdateWidget(QuadrantDetailScreen oldWidget) {
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

  void _handleToggle(Tarea tarea, bool value) async {
    // Actualización optimista local
    setState(() {
      final index = _tareasLocales.indexWhere((t) => t.id == tarea.id);
      if (index != -1) {
        _tareasLocales[index] = _tareasLocales[index].copyWith(
          completada: value,
        );
      }
    });

    // Llamar al callback del padre
    if (widget.onToggle != null) {
      await widget.onToggle!(tarea, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 30,
              decoration: BoxDecoration(
                color: widget.accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
            ),
          ],
        ),
      ),
      body:
          _tareasLocales.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay tareas en este cuadrante',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : TareasList(
                tareas: _tareasLocales,
                onEliminar: widget.onDelete ?? (_) {},
                onEditar: widget.onTapTask ?? (_) {},
                onCheck: _handleToggle,
              ),
    );
  }
}
