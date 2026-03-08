import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../services/local_storage_service.dart';
import 'dart:async';
import '../mappers/tarea_mapper.dart';
import '../services/notification_service.dart';

class TareasRepository {
  final LocalStorageService localStorage;

  TareasRepository(this.localStorage);

  Future<void> guardar(Tarea tarea, String clave, bool online) async {
    if (online) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = TareaMapper.toFirestoreMap(tarea, clave);
        data['userId'] = user.uid;
        final docRef = await FirebaseFirestore.instance
            .collection('tareas')
            .add(data);

        // Persist the generated Firestore ID locally to avoid duplicates
        final tareaConId = tarea.copyWith(id: docRef.id);
        await localStorage.saveTarea(tareaConId);
        // Programar notificaciones para la tarea
        await NotificationService().notifyTaskCreated(tareaConId);
        return;
      }
    }
    await localStorage.saveTarea(tarea);
    await NotificationService().notifyTaskCreated(tarea);
  }

  Future<void> eliminar(Tarea tarea, bool online) async {
    if (online) {
      await FirebaseFirestore.instance
          .collection('tareas')
          .doc(tarea.id)
          .delete();
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

    if (online) {
      await FirebaseFirestore.instance
          .collection('tareas')
          .doc(tarea.id)
          .update({'completada': completada});
    }

    await localStorage.saveTarea(actualizada);
    if (completada) {
      await NotificationService().cancelNotifications(tarea);
    }
  }
}
