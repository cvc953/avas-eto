import 'package:flutter/material.dart';
import '../models/tarea.dart';
import 'tareas_list.dart';

class QuadrantDetailScreen extends StatelessWidget {
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
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
            ),
          ],
        ),
      ),
      body:
          tareas.isEmpty
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
                tareas: tareas,
                onEliminar: onDelete ?? (_) {},
                onEditar: onTapTask ?? (_) {},
                onCheck: (tarea, value) {
                  if (onToggle != null) {
                    onToggle!(tarea, value);
                  }
                },
              ),
    );
  }
}
