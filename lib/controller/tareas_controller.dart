import 'package:avas_eto/models/tarea.dart';
import 'package:avas_eto/services/local_storage_service.dart';
import 'package:avas_eto/repositories/tareas_repository.dart';
import 'package:avas_eto/services/conectividad_service.dart';
import 'package:avas_eto/utils/task_key_generator.dart';

/// Controller que centraliza la lógica de negocio para las tareas.
class TareasController {
  final TareasRepository _repository;
  final LocalStorageService _localStorage;
  final ConectividadService _conectividad;

  final Map<String, List<Tarea>> tareas = {};
  final Set<Tarea> tareasExpandida = {};
  String _ordenActual = 'reciente';

  TareasController(this._repository, this._localStorage, this._conectividad);

  /// Carga inicial: prioriza local y deja que el repo sincronice si es necesario.
  Future<void> init() async {
    final local = await _localStorage.getTareas();
    tareas.clear();
    for (var tarea in local) {
      final clave =
          tarea.fechaVencimiento.year.toString() +
          '-' +
          tarea.fechaVencimiento.month.toString().padLeft(2, '0') +
          '-' +
          tarea.fechaVencimiento.day.toString().padLeft(2, '0') +
          '-' +
          tarea.fechaVencimiento.hour.toString().padLeft(2, '0') +
          '-' +
          tarea.fechaVencimiento.minute.toString().padLeft(2, '0');
      tareas.putIfAbsent(clave, () => []);
      if (!tareas[clave]!.any((t) => t.id == tarea.id))
        tareas[clave]!.add(tarea);
    }
  }

  List<Tarea> filtrar(bool completadas) {
    final list =
        tareas.values
            .expand((e) => e)
            .where((t) => t.completada == completadas)
            .toList();

    if (_ordenActual == 'reciente') {
      list.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    } else if (_ordenActual == 'prioridad') {
      final prioridadValor = {'Alta': 3, 'Media': 2, 'Baja': 1};
      list.sort((a, b) {
        final valA = prioridadValor[a.prioridad] ?? 0;
        final valB = prioridadValor[b.prioridad] ?? 0;
        if (valA != valB) return valB.compareTo(valA);
        return a.fechaVencimiento.compareTo(b.fechaVencimiento);
      });
    }

    return list;
  }

  void toggleExpandida(Tarea tarea) {
    if (tareasExpandida.contains(tarea)) {
      tareasExpandida.remove(tarea);
    } else {
      tareasExpandida.add(tarea);
    }
  }

  void ordenar(String tipoOrdenamiento) {
    _ordenActual = tipoOrdenamiento;
  }

  Future<void> guardar(Tarea tarea, bool online) async {
    final clave = TaskKeyGenerator.generateKeyFromDateTime(
      tarea.fechaVencimiento,
    );
    await _repository.guardar(tarea, clave, online);
    await init();
  }

  Future<void> actualizar(Tarea tarea, String clave) async {
    try {
      await _repository.guardar(tarea, clave, _conectividad.isOnline);
    } catch (_) {
      await _localStorage.saveTarea(tarea);
    }
    await init();
  }

  Future<void> eliminar(Tarea tarea, bool online) async {
    await _repository.eliminar(tarea, online);
    await init();
  }

  Future<void> marcarCompletada(
    Tarea tarea,
    bool completada,
    bool online,
  ) async {
    await _repository.marcarCompletada(tarea, completada, online);
    await init();
  }

  Future<void> moverTarea(
    Tarea tarea,
    String claveVieja,
    String claveNueva,
  ) async {
    await actualizar(tarea, claveNueva);
  }
}
