import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../services/local_storage_service.dart';
import 'dart:async';
import '../utils/tarea_helpers.dart';

class TareasRepository {
  final LocalStorageService localStorage;

  TareasRepository(this.localStorage);

  Future<void> guardar(Tarea tarea, String clave, bool online) async {
    if (online) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('tareas')
            .add(tareaToFirestoreMap(tarea, clave)..['userId'] = user.uid);
      }
    }
    await localStorage.saveTarea(tarea);
  }

  Future<void> eliminar(Tarea tarea, bool online) async {
    if (online) {
      await FirebaseFirestore.instance
          .collection('tareas')
          .doc(tarea.id)
          .delete();
    }
    await localStorage.deleteTarea(tarea.id);
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
  }
}
