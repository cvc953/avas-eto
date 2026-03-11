import 'package:sembast/sembast.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_database.dart';
import '../models/tarea.dart';
import '../utils/attachment_utils.dart';

class LocalStorageService {
  static const String _ownerUserIdKey = '_ownerUserId';
  static const String _deviceOwnerIdKey = '_deviceOwnerId';
  static const String _anonymousUserId = '__anonymous__';

  final StoreRef<String, Map<String, dynamic>> _store =
      StoreRef<String, Map<String, dynamic>>.main();
  final LocalDatabase _localDb;

  LocalStorageService(this._localDb);

  Future<String> _activeOwnerId() async {
    final current = FirebaseAuth.instance.currentUser?.uid;
    if (current != null) return current;

    final persisted = await _getPersistedDeviceOwnerId();
    if (persisted != null && persisted.isNotEmpty) return persisted;

    return _anonymousUserId;
  }

  Future<void> setDeviceOwnerId(String? uid) async {
    try {
      final database = await _localDb.db;
      if (uid == null) {
        await _store.record(_deviceOwnerIdKey).delete(database);
      } else {
        await _store.record(_deviceOwnerIdKey).put(database, {'value': uid});
      }
    } catch (e) {
      debugPrint('Error persisting deviceOwnerId: $e');
    }
  }

  Future<String?> _getPersistedDeviceOwnerId() async {
    try {
      final database = await _localDb.db;
      final data = await _store.record(_deviceOwnerIdKey).get(database);
      if (data == null) return null;
      if (data['value'] is String) return data['value'] as String;
      return null;
    } catch (e) {
      debugPrint('Error leyendo deviceOwnerId: $e');
      return null;
    }
  }

  /// Devuelve el device owner id persistido (usado por tests y diagnósticos).
  Future<String?> getDeviceOwnerId() async =>
      await _getPersistedDeviceOwnerId();

  Future<void> saveTarea(Tarea tarea) async {
    await saveTareaAndReturn(tarea);
  }

  Future<Tarea> saveTareaAndReturn(Tarea tarea) async {
    try {
      final database = await _localDb.db;

      // Genera un ID local único si no existe.
      final tareaConId =
          tarea.localId.isEmpty
              ? tarea.copyWith(
                localId: DateTime.now().millisecondsSinceEpoch.toString(),
              )
              : tarea;

      final map = tareaConId.toMap();
      map[_ownerUserIdKey] = await _activeOwnerId();

      await _store.record(tareaConId.localId).put(database, map);
      debugPrint('Tarea guardada LOCALMENTE: ${tareaConId.localId}');
      return tareaConId;
    } catch (e) {
      debugPrint('Error guardando localmente: $e');
      throw Exception('Error en saveTarea: $e');
    }
  }

  Future<Tarea?> getTareaById(String id) async {
    try {
      final database = await _localDb.db;
      Map<String, dynamic>? data = await _store.record(id).get(database);
      if (data == null) {
        final records = await _store.find(
          database,
          finder: Finder(filter: Filter.equals('id', id)),
        );
        if (records.isNotEmpty) {
          data = records.first.value;
        }
      }
      if (data == null) return null;

      final storedOwner = data[_ownerUserIdKey] as String?;
      final activeOwner = await _activeOwnerId();
      if (storedOwner != null && storedOwner != activeOwner) {
        return null;
      }

      return Tarea.fromMap(data);
    } catch (e) {
      debugPrint('Error obteniendo tarea $id: $e');
      return null;
    }
  }

  /// Lookup interno para procesos de sincronizacion/upload.
  /// Ignora el filtro de owner porque puede ejecutarse en background isolate
  /// sin `FirebaseAuth.currentUser` inicializado.
  Future<Tarea?> getTareaByIdInternal(String id) async {
    try {
      final database = await _localDb.db;
      Map<String, dynamic>? data = await _store.record(id).get(database);
      if (data == null) {
        final records = await _store.find(
          database,
          finder: Finder(filter: Filter.equals('id', id)),
        );
        if (records.isNotEmpty) {
          data = records.first.value;
        }
      }
      if (data == null) return null;
      return Tarea.fromMap(data);
    } catch (e) {
      debugPrint('Error obteniendo tarea interna $id: $e');
      return null;
    }
  }

  Future<void> updateAttachment(
    String taskId,
    String attachmentId,
    Map<String, dynamic> updatedAttachment,
  ) async {
    final tarea = await getTareaById(taskId);
    if (tarea == null) return;

    final attachments = tarea.adjuntos
        .map((attachment) {
          if (attachmentIdOf(attachment) == attachmentId) {
            return normalizeAttachment(updatedAttachment);
          }
          return normalizeAttachment(attachment);
        })
        .toList(growable: false);

    await saveTarea(tarea.copyWith(adjuntos: attachments));
  }

  Future<List<Tarea>> getTareas() async {
    try {
      final database = await _localDb.db;
      final records = await _store.find(database);
      final ownerId = await _activeOwnerId();

      final visibles = records.where((record) {
        final storedOwner = record.value[_ownerUserIdKey] as String?;
        if (storedOwner == null) {
          // Datos heredados sin owner: solo visibles en modo anonimo.
          return ownerId == _anonymousUserId;
        }
        return storedOwner == ownerId;
      });

      return visibles.map((record) {
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
            fechaInicio: DateTime.now(),
            fechaVencimiento: DateTime.now(),
            duracionMinutos: 60,
            todoElDia: false,
            adjuntos: const [],
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
