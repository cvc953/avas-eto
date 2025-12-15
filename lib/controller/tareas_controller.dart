import 'package:avas_eto/models/tarea.dart';

class TareasController {
  final Map<String, List<Tarea>> tareas;
  final Set<Tarea> tareasExpandida;

  TareasController(this.tareas, this.tareasExpandida);

  List<Tarea> filtrar(bool completadas) {
    return tareas.values
        .expand((e) => e)
        .where((t) => t.completada == completadas)
        .toList();
  }

  void toggleExpandida(Tarea tarea) {
    tareasExpandida.contains(tarea)
        ? tareasExpandida.remove(tarea)
        : tareasExpandida.add(tarea);
  }
}
