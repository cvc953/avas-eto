import 'package:avas_eto/models/tarea.dart';
import 'package:avas_eto/services/local_storage_service.dart';
import 'package:avas_eto/repositories/tareas_repository.dart';
import 'package:avas_eto/services/conectividad_service.dart';
import 'package:avas_eto/utils/task_key_generator.dart';
import 'package:avas_eto/services/local_database.dart';

/// Controller que centraliza la lógica de negocio para las tareas.
class TareasController {
  final TareasRepository _repository;
  final LocalStorageService _localStorage;
  final ConectividadService _conectividad;

  final Map<String, List<Tarea>> tareas = {};
  final Set<Tarea> tareasExpandida = {};
  String _ordenActual = 'reciente';

  TareasController(this._repository, this._localStorage, this._conectividad);

  /// Crea e inicializa un controlador con los servicios internos.
  /// Facilita mantener la construcción de servicios fuera de la UI.
  static Future<TareasController> create() async {
    final localDb = LocalDatabase();
    final localStorage = LocalStorageService(localDb);
    final conectividad = ConectividadService();
    final repo = TareasRepository(localStorage);

    final controller = TareasController(repo, localStorage, conectividad);
    await controller.init();

    return controller;
  }

  /// Expone el estado de conectividad actual.
  bool get isOnline => _conectividad.isOnline;

  /// Permite a la UI suscribirse a cambios de conectividad.
  void setupConnectivityListener(void Function(bool) onChange) {
    _conectividad.setupListener(onChange);
  }

  /// Limpia recursos asociados (p.ej. listeners).
  void dispose() {
    _conectividad.dispose();
  }

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
    final actualizada = tarea.copyWith(completada: completada);

    // Try to update remote; don't reload everything afterwards to keep UI snappy.
    try {
      await _repository.marcarCompletada(tarea, completada, online);
    } catch (_) {}

    // Ensure local storage reflects the change.
    await _localStorage.saveTarea(actualizada);

    // Update in-memory map to reflect the new state.
    for (final entry in tareas.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        if (entry.value[i].id == actualizada.id) {
          entry.value[i] = actualizada;
        }
      }
    }
  }

  /// Apply a local, optimistic completed toggle immediately.
  /// Fires a background save to local storage (not awaited) so the UI can update instantly.
  void markCompletadaLocal(Tarea tarea, bool completada) {
    final actualizada = tarea.copyWith(completada: completada);

    for (final entry in tareas.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        if (entry.value[i].id == actualizada.id) {
          entry.value[i] = actualizada;
        }
      }
    }

    // Fire-and-forget local save to keep persistence fast.
    _localStorage.saveTarea(actualizada);
  }

  Future<void> moverTarea(
    Tarea tarea,
    String claveVieja,
    String claveNueva,
  ) async {
    await actualizar(tarea, claveNueva);
  }
}
