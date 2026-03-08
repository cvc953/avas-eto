import 'package:flutter/material.dart';
import '../models/tarea.dart';

class EisenhowerMatrix extends StatelessWidget {
  final List<Tarea> tareas;

  const EisenhowerMatrix({super.key, required this.tareas});

  List<Tarea> _filter(bool urgent, bool important) {
    // Simple heuristic: prioridad Alta -> important, fechaVencimiento próxima -> urgent
    final now = DateTime.now();
    return tareas.where((t) {
      final importantMatch =
          t.prioridad.toLowerCase() == 'alta' ||
          t.prioridad.toLowerCase() == 'media';
      final urgentMatch = t.fechaVencimiento.isBefore(
        now.add(Duration(hours: 24)),
      );
      return (urgent ? urgentMatch : !urgentMatch) &&
          (important ? importantMatch : !importantMatch);
    }).toList();
  }

  Widget _quadrant(String title, Color color, List<Tarea> items) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
        Widget _header(String roman, String title, Color color) {
          return Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(roman, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }

        Widget _quadrantContainer(BuildContext context, String roman, String title, Color color, List<Tarea> items) {
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
                _header(roman, title, color),
                const SizedBox(height: 8),
                Expanded(
                  child: items.isEmpty
                      ? Center(child: Text('Sin tareas', style: TextStyle(color: Colors.grey[500])))
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
                                  onChanged: (_) {},
                                  activeColor: color,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.title,
                                    style: TextStyle(
                                      color: t.completada ? Colors.grey : Colors.white,
                                      decoration: t.completada ? TextDecoration.lineThrough : TextDecoration.none,
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
          AspectRatio(
            aspectRatio: 2,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _quadrant(
                          'Urgente e Importante',
                          Colors.red,
                          q1,
                        ),
                      ),
                      Expanded(
                        child: _quadrant(
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
                        child: _quadrant(
                          'Urgente y No importante',
                          Colors.yellow,
                          q3,
                        ),
                      ),
                      Expanded(
                        child: _quadrant(
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
