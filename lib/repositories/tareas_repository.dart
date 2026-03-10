import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../services/local_storage_service.dart';
import '../mappers/tarea_mapper.dart';
import '../services/notification_service.dart';
import '../services/drive_upload_orchestrator.dart';
import '../services/background_upload_scheduler.dart';
import '../services/upload_queue_service.dart';
import '../utils/attachment_utils.dart';

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
        await _firestore.collection('tareas').doc(tarea.id).set(tarea.toMap());
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
      final snapshot = await _firestore.collection('tareas').get();
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
        await _firestore.collection('tareas').doc(id).delete();
      } catch (e) {
        print('Error eliminando tarea de Firestore: $e');
      }
    }
  }
}

/// Backwards-compatible wrapper providing the old `TareasRepository` API
/// (guardar/eliminar/marcarCompletada).
class TareasRepository {
  final LocalStorageService localStorage;
  final UploadQueueService _uploadQueueService;
  final DriveUploadOrchestrator _driveUploadOrchestrator;

  TareasRepository(
    this.localStorage,
    this._uploadQueueService,
    this._driveUploadOrchestrator,
  );

  /// Descarga las tareas del usuario autenticado y las persiste en local.
  ///
  /// Retorna cuantas tareas se procesaron desde Firestore.
  Future<int> sincronizarDesdeServidor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('tareas')
              .where('userId', isEqualTo: user.uid)
              .get();

      for (final doc in snapshot.docs) {
        final tarea = TareaMapper.fromFirestoreQueryDocument(doc);
        await localStorage.saveTarea(tarea);
      }

      return snapshot.docs.length;
    } catch (e) {
      print('Error sincronizando tareas desde Firestore: $e');
      return 0;
    }
  }

  Future<void> processPendingUploads() async {
    await _driveUploadOrchestrator.processPendingUploads();
  }

  Future<void> guardar(Tarea tarea, String clave, bool online) async {
    final tareaPersistida = await localStorage.saveTareaAndReturn(tarea);

    if (online) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = TareaMapper.toFirestoreMap(tareaPersistida, clave);
        data['userId'] = user.uid;

        try {
          await FirebaseFirestore.instance
              .collection('tareas')
              .doc(tareaPersistida.id)
              .set(data);
        } catch (e) {
          print('Error actualizando tarea en Firestore: $e');
        }
      }
    }

    await _uploadQueueService.enqueueAttachmentsForTask(tareaPersistida);
    await NotificationService().cancelNotifications(tareaPersistida);
    await NotificationService().notifyTaskCreated(tareaPersistida);

    if (tareaPersistida.adjuntos.any(attachmentNeedsUpload)) {
      unawaited(_driveUploadOrchestrator.processPendingUploads());
      unawaited(BackgroundUploadScheduler.triggerNow());
    }
  }

  Future<void> eliminar(Tarea tarea, bool online) async {
    if (online && tarea.id.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(tarea.id)
            .delete();
      } catch (_) {}
    }
    await localStorage.deleteTarea(tarea.id);
    await _uploadQueueService.deleteByTaskId(tarea.id);
    await NotificationService().cancelNotifications(tarea);
  }

  Future<void> marcarCompletada(
    Tarea tarea,
    bool completada,
    bool online,
  ) async {
    final actualizada = tarea.copyWith(completada: completada);

    if (online && tarea.id.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(tarea.id)
            .update({'completada': completada});
      } catch (_) {}
    }

    await localStorage.saveTarea(actualizada);
    if (completada) {
      // Use the updated tarea (same id) to cancel any scheduled notifications.
      await NotificationService().cancelNotifications(actualizada);
    }
  }
}
