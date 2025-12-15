import '../models/tarea.dart';

MapEntry<String, int> buscarUbicacionTarea(
  Map<String, List<Tarea>> tareas,
  Tarea tarea,
) {
  for (final entry in tareas.entries) {
    final index = entry.value.indexOf(tarea);
    if (index != -1) {
      return MapEntry(entry.key, index);
    }
  }
  throw Exception('Tarea no encontrada');
}
