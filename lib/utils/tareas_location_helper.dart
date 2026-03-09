import '../models/tarea.dart';

MapEntry<String, int> buscarUbicacionTarea(
  Map<String, List<Tarea>> tareas,
  Tarea tarea,
) {
  for (final entry in tareas.entries) {
    for (var i = 0; i < entry.value.length; i++) {
      if (entry.value[i].id == tarea.id) {
        return MapEntry(entry.key, i);
      }
    }
  }
  throw Exception('Tarea no encontrada');
}
