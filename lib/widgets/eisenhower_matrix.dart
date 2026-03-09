import 'package:flutter/material.dart';
import '../models/tarea.dart';

class EisenhowerMatrix extends StatelessWidget {
  final List<Tarea> tareas;

  /// Callback invoked when a task is toggled (marcar/desmarcar completada).
  /// The callback receives the tarea and the new `completada` value.
  final Future<void> Function(Tarea tarea, bool completada)? onToggle;

  const EisenhowerMatrix({super.key, required this.tareas, this.onToggle});

  List<Tarea> _filter(bool urgent, bool important) {
    final now = DateTime.now();
    return tareas.where((t) {
      final prioridad = t.prioridad.toLowerCase();
      // Importante: Alta o Media
      // No importante: Baja o Ninguna
      final importantMatch = prioridad == 'alta' || prioridad == 'media';
      final urgentMatch = t.fechaVencimiento.isBefore(
        now.add(const Duration(hours: 24)),
      );
      return (urgent ? urgentMatch : !urgentMatch) &&
          (important ? importantMatch : !importantMatch);
    }).toList();
  }

  Widget _quadrantContainer(
    BuildContext context,
    String roman,
    String title,
    Color color,
    List<Tarea> items,
  ) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    roman,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                items.isEmpty
                    ? Center(
                      child: Text(
                        'Sin tareas',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                    : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final t = items[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: t.completada,
                              onChanged: (val) async {
                                if (onToggle != null) {
                                  await onToggle!(t, val ?? false);
                                }
                              },
                              activeColor: color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.title,
                                style: TextStyle(
                                  color:
                                      t.completada ? Colors.grey : Colors.white,
                                  decoration:
                                      t.completada
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q1 = _filter(true, true);
    final q2 = _filter(false, true);
    final q3 = _filter(true, false);
    final q4 = _filter(false, false);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Matriz de Eisenhower',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _quadrantContainer(
                          context,
                          'I',
                          'Urgente e Importante',
                          Colors.red,
                          q1,
                        ),
                      ),
                      Expanded(
                        child: _quadrantContainer(
                          context,
                          'II',
                          'No urgente e Importante',
                          Colors.orange,
                          q2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _quadrantContainer(
                          context,
                          'III',
                          'Urgente y No importante',
                          Colors.yellow,
                          q3,
                        ),
                      ),
                      Expanded(
                        child: _quadrantContainer(
                          context,
                          'IV',
                          'No urgente y No importante',
                          Colors.green,
                          q4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
