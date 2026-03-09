import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
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
                        activeColor: tarea.color,
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
