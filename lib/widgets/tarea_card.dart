import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tarea.dart';

class TareaCard extends StatelessWidget {
  final Tarea tarea;
  final ValueChanged<bool?> onCheck;
  final VoidCallback onTap;

  const TareaCard({
    super.key,
    required this.tarea,
    required this.onCheck,
    required this.onTap,
  });

  Color _quadrantColor(Tarea tarea) {
    final now = DateTime.now();
    final isImportant =
        tarea.prioridad.toLowerCase() == 'alta' ||
        tarea.prioridad.toLowerCase() == 'media';
    final isUrgent = tarea.fechaVencimiento.isBefore(
      now.add(const Duration(days: 2)),
    );

    if (isUrgent && isImportant) return const Color(0xFFFF5F6D);
    if (!isUrgent && isImportant) return const Color(0xFFFFBC1F);
    if (isUrgent && !isImportant) return const Color(0xFF4E7BFF);
    return const Color(0xFF00D4B5);
  }

  bool _isOverdue(Tarea tarea, DateTime now) {
    return !tarea.completada && tarea.fechaVencimiento.isBefore(now);
  }

  String _buildOverdueLabel(Tarea tarea) {
    final pattern = tarea.todoElDia ? 'd MMM yyyy' : 'd MMM yyyy, HH:mm';
    final formatted = DateFormat(pattern, 'es').format(tarea.fechaVencimiento);
    return 'Vencio: $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final quadrantColor = _quadrantColor(tarea);
    final showOverdue = _isOverdue(tarea, now);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color:
            tarea.completada
                ? Theme.of(context).cardColor.withAlpha(210)
                : Theme.of(context).cardColor,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: tarea.completada ? 0.78 : 1,
        child: Card(
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: tarea.completada,
                        onChanged: onCheck,
                        activeColor: quadrantColor,
                        side: BorderSide(color: quadrantColor, width: 1.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration:
                                    tarea.completada
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                color:
                                    tarea.completada
                                        ? Colors.grey
                                        : Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.color,
                              ),
                              child: Text(
                                tarea.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showOverdue) ...[
                              const SizedBox(height: 2),
                              Text(
                                _buildOverdueLabel(tarea),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    tarea.completada
                                        ? Colors.grey[600]!
                                        : Colors.grey[500]!,
                              ),
                              child: Text(
                                tarea.descripcion.isNotEmpty
                                    ? tarea.descripcion
                                    : 'Sin descripción',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
