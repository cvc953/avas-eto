import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../services/local_storage_service.dart';
import '../mappers/tarea_mapper.dart';
import '../services/notification_service.dart';

/// Canonical repository implementation that centralizes local + optional
/// Firestore sync behavior.
class TareaRepository {
  final FirebaseFirestore? _firestore;
  final LocalStorageService _localStorage;

  TareaRepository(this._firestore, this._localStorage);

  Future<void> saveTarea(Tarea tarea) async {
    await _localStorage.saveTarea(tarea);

    if (_firestore != null) {
      try {
        await _firestore!.collection('tareas').doc(tarea.id).set(tarea.toMap());
      } catch (e) {
        print('Error al sincronizar con Firestore: $e');
      }
    }
  }

  Future<List<Tarea>> getTareas() async {
    if (_firestore == null) {
      return await _localStorage.getTareas();
    }

    try {
      final snapshot = await _firestore!.collection('tareas').get();
      final tareas = <Tarea>[];

      for (var doc in snapshot.docs) {
        try {
          final tareaData = Map<String, dynamic>.from(doc.data());
          tareaData['id'] = doc.id;
          final tarea = Tarea.fromMap(tareaData);
          await _localStorage.saveTarea(tarea);
          tareas.add(tarea);
        } catch (e) {
          print('Error procesando documento ${doc.id}: $e');
        }
      }

      return tareas;
    } catch (e) {
      print('Error obteniendo tareas de Firestore: $e');
      return await _localStorage.getTareas();
    }
  }

  Future<void> deleteTarea(String id) async {
    await _localStorage.deleteTarea(id);

    if (_firestore != null) {
      try {
        await _firestore!.collection('tareas').doc(id).delete();
      } catch (e) {
        print('Error eliminando tarea de Firestore: $e');
      }
    }
  }
}

/// Backwards-compatible wrapper providing the old `TareasRepository` API
/// (guardar/eliminar/marcarCompletada) delegating to the canonical
/// `TareaRepository` where appropriate.
class TareasRepository {
  final LocalStorageService localStorage;
  final TareaRepository _inner;

  TareasRepository(this.localStorage)
    : _inner = TareaRepository(FirebaseFirestore.instance, localStorage);

  Future<void> guardar(Tarea tarea, String clave, bool online) async {
    if (online) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = TareaMapper.toFirestoreMap(tarea, clave);
        data['userId'] = user.uid;
        final docRef = await FirebaseFirestore.instance
            .collection('tareas')
            .add(data);

        final tareaConId = tarea.copyWith(id: docRef.id);
        await localStorage.saveTarea(tareaConId);
        await NotificationService().notifyTaskCreated(tareaConId);
        return;
      }
    }

    await localStorage.saveTarea(tarea);
    await NotificationService().notifyTaskCreated(tarea);
  }

  Future<void> eliminar(Tarea tarea, bool online) async {
    if (online && tarea.id != null && tarea.id.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(tarea.id)
            .delete();
      } catch (_) {}
    }
    await localStorage.deleteTarea(tarea.id);
    await NotificationService().cancelNotifications(tarea);
  }

  Future<void> marcarCompletada(
    Tarea tarea,
    bool completada,
    bool online,
  ) async {
    final actualizada = tarea.copyWith(completada: completada);

    if (online && tarea.id != null && tarea.id.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(tarea.id)
            .update({'completada': completada});
      } catch (_) {}
    }

    await localStorage.saveTarea(actualizada);
    if (completada) {
      await NotificationService().cancelNotifications(tarea);
    }
  }
}
