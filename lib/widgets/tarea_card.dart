import 'package:flutter/material.dart';
import '../models/tarea.dart';
import 'package:intl/intl.dart';
import '../utils/tarea_helpers.dart';

class TareaCard extends StatelessWidget {
  final Tarea tarea;
  final bool expandida;
  final VoidCallback onToggleExpand;
  final ValueChanged<bool?> onCheck;
  final VoidCallback onEliminar;
  final VoidCallback onEditar;

  const TareaCard({
    super.key,
    required this.tarea,
    required this.expandida,
    required this.onToggleExpand,
    required this.onCheck,
    required this.onEliminar,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onToggleExpand,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: tarea.completada,
                        onChanged: onCheck,
                        activeColor: tarea.color,
                      ),
                      CircleAvatar(
                        backgroundColor: tarea.color,
                        child: const Icon(Icons.menu_book, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tarea.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                            ),
                            Text(
                              'Finaliza el:\n ${DateFormat('dd/MM/yyyy').format(tarea.fechaVencimiento)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Icon(expandida ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              if (expandida) ...[
                const SizedBox(height: 8),

                Text(
                  "Finaliza a: ${tarea.fechaVencimiento.hour.toString().padLeft(2, '0')}:"
                  "${tarea.fechaVencimiento.minute.toString().padLeft(2, '0')}",
                ),
                Text(
                  'Prioridad: ${tarea.prioridad}',
                  style: TextStyle(
                    color: getPrioridadColor(tarea.prioridad),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("Descripción: ${tarea.descripcion}"),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onEditar,
                    child: const Text(
                      'Editar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: onEliminar,
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.white),
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
