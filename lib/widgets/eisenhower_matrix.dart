import 'package:flutter/material.dart';
import '../models/tarea.dart';

class EisenhowerMatrix extends StatefulWidget {
  final List<Tarea> tareas;
  final Future<void> Function(Tarea tarea, bool completada)? onToggle;
  final void Function(Tarea tarea)? onTapTask;
  final void Function(String title, Color color, List<Tarea> tasks)?
  onTapQuadrant;

  const EisenhowerMatrix({
    super.key,
    required this.tareas,
    this.onToggle,
    this.onTapTask,
    this.onTapQuadrant,
  });

  @override
  State<EisenhowerMatrix> createState() => _EisenhowerMatrixState();
}

class _EisenhowerMatrixState extends State<EisenhowerMatrix> {
  late List<Tarea> _tareasLocales;

  @override
  void initState() {
    super.initState();
    _tareasLocales = List.from(widget.tareas);
  }

  @override
  void didUpdateWidget(EisenhowerMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tareas != oldWidget.tareas) {
      _tareasLocales = List.from(widget.tareas);
    }
  }

  Future<void> _handleToggle(Tarea tarea, bool completada) async {
    // Mover la tarea al final de su lista antes de llamar el callback
    setState(() {
      final index = _tareasLocales.indexWhere((t) => t.id == tarea.id);
      if (index != -1) {
        final tareaActualizada = _tareasLocales[index].copyWith(completada: completada);
        _tareasLocales.removeAt(index);
        _tareasLocales.add(tareaActualizada);
      }
    });

    // Llamar el callback original
    if (widget.onToggle != null) {
      await widget.onToggle!(tarea, completada);
    }
  }

  List<Tarea> _filter(bool urgent, bool important) {
    // Simple heuristic: prioridad Alta -> important, fechaVencimiento próxima -> urgent
    final now = DateTime.now();
    final filteredTasks = _tareasLocales.where((t) {
      final importantMatch =
          t.prioridad.toLowerCase() == 'alta' ||
          t.prioridad.toLowerCase() == 'media';
      final urgentMatch = t.fechaVencimiento.isBefore(
        now.add(const Duration(days: 2)),
      );
      return (urgent ? urgentMatch : !urgentMatch) &&
          (important ? importantMatch : !importantMatch);
    }).toList();

    // Ordenar: completadas al final
    filteredTasks.sort((a, b) {
      if (a.completada && !b.completada) return 1;
      if (!a.completada && b.completada) return -1;
      return 0;
    });

    return filteredTasks;
  }

  Widget _taskRow(BuildContext context, Tarea tarea, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color:
              tarea.completada ? Colors.grey.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: tarea.completada ? 0.75 : 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTapTask == null ? null : () => widget.onTapTask!(tarea),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: tarea.completada,
                    onChanged: (value) {
                      if (value == null || widget.onToggle == null) return;
                      _handleToggle(tarea, value);
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
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      color:
                          tarea.completada
                              ? Colors.grey.shade600
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87),
                      fontSize: 16,
                      decoration:
                          tarea.completada
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                    ),
                    child: Text(
                      tarea.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quadrant({
    required BuildContext context,
    required String numeral,
    required String title,
    required Color accent,
    required List<Tarea> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quadrantBg =
        isDark ? const Color(0xFF191B20) : Theme.of(context).cardColor;
    final emptyColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return InkWell(
      onTap:
          widget.onTapQuadrant == null
              ? null
              : () => widget.onTapQuadrant!(title, accent, items),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: quadrantBg,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 25,
                  height: 25,
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
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
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
                          style: TextStyle(color: emptyColor, fontSize: 20),
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
            context: context,
            numeral: 'I',
            title: 'Urgente e importante',
            accent: const Color(0xFFFF5F6D),
            items: q1,
          ),
          _quadrant(
            context: context,
            numeral: 'II',
            title: 'No urgente pero importante',
            accent: const Color(0xFFFFBC1F),
            items: q2,
          ),
          _quadrant(
            context: context,
            numeral: 'III',
            title: 'Urgente pero no importante',
            accent: const Color(0xFF4E7BFF),
            items: q3,
          ),
          _quadrant(
            context: context,
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
