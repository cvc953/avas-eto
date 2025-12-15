import 'package:sembast/sembast.dart';
import 'package:flutter/material.dart';
import 'local_database.dart';
import '../models/tarea.dart';

class LocalStorageService {
  final StoreRef<String, Map<String, dynamic>> _store =
      StoreRef<String, Map<String, dynamic>>.main();
  final LocalDatabase _localDb;

  LocalStorageService(this._localDb);

  Future<void> saveTarea(Tarea tarea) async {
    try {
      final database = await _localDb.db;

      // Genera un ID único si no existe
      final tareaConId =
          tarea.id.isEmpty
              ? tarea.copyWith(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              )
              : tarea;

      await _store.record(tareaConId.id).put(database, tareaConId.toMap());
      debugPrint('Tarea guardada LOCALMENTE: ${tareaConId.id}');
    } catch (e) {
      debugPrint('Error guardando localmente: $e');
      throw Exception('Error en saveTarea: $e');
    }
  }

  Future<List<Tarea>> getTareas() async {
    try {
      final database = await _localDb.db;
      final records = await _store.find(database);

      return records.map((record) {
        try {
          return Tarea.fromMap(record.value);
        } catch (e) {
          debugPrint('Error procesando tarea ${record.key}: $e');
          return Tarea(
            id: record.key,
            title: 'Error',
            descripcion: '',
            prioridad: 'media',
            color: Colors.grey,
            fechaCreacion: DateTime.now(),
            fechaVencimiento: DateTime.now(),
            fechaCompletada: DateTime.now(),
          );
        }
      }).toList();
    } catch (e) {
      debugPrint('Error obteniendo tareas: $e');
      return [];
    }
  }

  Future<void> deleteTarea(String id) async {
    try {
      final database = await _localDb.db;
      await _store.record(id).delete(database);
      debugPrint('Tarea eliminada: $id');
    } catch (e) {
      debugPrint('Error eliminando tarea $id: $e');
      throw Exception('Failed to delete task');
    }
  }
}
