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

  Widget _taskRow(BuildContext context, Tarea tarea, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: tarea.completada,
              onChanged: (value) {
                if (value == null || onToggle == null) return;
                onToggle!.call(tarea, value);
              },
              side: BorderSide(
                color: tarea.completada ? Colors.grey.shade700 : accent,
                width: 1.6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              activeColor: Colors.grey.shade800,
              checkColor: Colors.grey.shade300,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tarea.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tarea.completada ? Colors.grey.shade600 : Colors.white,
                fontSize: 20,
                decoration:
                    tarea.completada
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quadrant({
    required String numeral,
    required String title,
    required Color accent,
    required List<Tarea> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF191B20),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  numeral,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                items.isEmpty
                    ? Center(
                      child: Text(
                        'Sin tareas',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 20,
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: items.length,
                      itemBuilder:
                          (context, index) =>
                              _taskRow(context, items[index], accent),
                    ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
        children: [
          _quadrant(
            numeral: 'I',
            title: 'Urgente e importante',
            accent: const Color(0xFFFF5F6D),
            items: q1,
          ),
          _quadrant(
            numeral: 'II',
            title: 'No urgente pero importante',
            accent: const Color(0xFFFFBC1F),
            items: q2,
          ),
          _quadrant(
            numeral: 'III',
            title: 'Urgente pero no importante',
            accent: const Color(0xFF4E7BFF),
            items: q3,
          ),
          _quadrant(
            numeral: 'IV',
            title: 'No urgente y no importante',
            accent: const Color(0xFF00D4B5),
            items: q4,
          ),
        ],
      ),
    );
  }
}
