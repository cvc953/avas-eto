import 'package:flutter/material.dart';
import '../models/tarea.dart';
import 'package:intl/intl.dart';
import '../utils/tarea_utils.dart';

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
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
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
                        Text(
                          tarea.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: tarea.completada ? TextDecoration.lineThrough : TextDecoration.none,
                            color: tarea.completada ? Colors.grey : Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tarea.descripcion.isNotEmpty ? tarea.descripcion : 'Sin descripción',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
    );
  }
}
