import 'package:flutter/material.dart';
import '../models/tarea.dart';

class EisenhowerMatrix extends StatelessWidget {
  final List<Tarea> tareas;
  final Future<void> Function(Tarea tarea, bool completada)? onToggle;

  const EisenhowerMatrix({super.key, required this.tareas, this.onToggle});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            '${items.length} tareas',
            // style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q1 = _filter(true, true); // Urgent & Important
    final q2 = _filter(false, true); // Not Urgent & Important
    final q3 = _filter(true, false); // Urgent & Not Important
    final q4 = _filter(false, false); // Not Urgent & Not Important
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Mobile / narrow layout: stack quadrants vertically so they fit small screens.
        if (width < 600) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _quadrant('Urgente e Importante', Colors.red, q1),
                const SizedBox(height: 8),
                _quadrant('No urgente e Importante', Colors.orange, q2),
                const SizedBox(height: 8),
                _quadrant('Urgente y No importante', Colors.yellow, q3),
                const SizedBox(height: 8),
                _quadrant('No urgente y No importante', Colors.green, q4),
              ],
            ),
          );
        }

        // Wider screens: present a two-column matrix with balanced quadrants.
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _quadrant('Urgente e Importante', Colors.red, q1),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
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
        );
      },
    );
  }
}
