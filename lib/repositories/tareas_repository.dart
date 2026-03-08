import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../services/local_storage_service.dart';
import '../mappers/tarea_mapper.dart';
import '../services/notification_service.dart';
import '../services/tarea_repository.dart' as canonical;

/// Adapter preserving the older `TareasRepository` API while delegating
/// canonical behavior to `TareaRepository` (defined in
/// `lib/services/tarea_repository.dart`). This keeps existing callers
/// working while centralizing the implementation.
class TareasRepository {
  final LocalStorageService localStorage;
  final canonical.TareaRepository _inner;

  TareasRepository(this.localStorage)
      : _inner = canonical.TareaRepository(FirebaseFirestore.instance, localStorage);

  Future<void> guardar(Tarea tarea, String clave, bool online) async {
    if (online) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = TareaMapper.toFirestoreMap(tarea, clave);
        data['userId'] = user.uid;
        final docRef = await FirebaseFirestore.instance.collection('tareas').add(data);

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
        await FirebaseFirestore.instance.collection('tareas').doc(tarea.id).delete();
      } catch (_) {}
    }
    await localStorage.deleteTarea(tarea.id);
    await NotificationService().cancelNotifications(tarea);
  }

  Future<void> marcarCompletada(Tarea tarea, bool completada, bool online) async {
    final actualizada = tarea.copyWith(completada: completada);

    if (online && tarea.id != null && tarea.id.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('tareas').doc(tarea.id).update({'completada': completada});
      } catch (_) {}
    }

    await localStorage.saveTarea(actualizada);
    if (completada) {
      await NotificationService().cancelNotifications(tarea);
    }
  }

  // Delegate useful methods to canonical implementation where appropriate
  Future<void> saveTarea(Tarea tarea) => _inner.saveTarea(tarea);
  Future<List<Tarea>> getTareas() => _inner.getTareas();
  Future<void> deleteTarea(String id) => _inner.deleteTarea(id);
}
