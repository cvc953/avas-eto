import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../services/local_storage_service.dart';
import '../mappers/tarea_mapper.dart';
import '../services/notification_service.dart';
import '../services/drive_download_orchestrator.dart';
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
    final persisted = await _localStorage.saveTareaAndReturn(tarea);

    if (_firestore != null) {
      try {
        final remoteId = persisted.firestoreId;
        if (remoteId != null && remoteId.isNotEmpty) {
          await _firestore
              .collection('tareas')
              .doc(remoteId)
              .set(persisted.toMap(), SetOptions(merge: true));
        } else {
          final docRef = await _firestore
              .collection('tareas')
              .add(persisted.toMap());
          await _localStorage.saveTarea(
            persisted.copyWith(firestoreId: docRef.id),
          );
        }
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
    final local = await _localStorage.getTareaByIdInternal(id);
    await _localStorage.deleteTarea(id);

    if (_firestore != null) {
      try {
        final remoteId = local?.firestoreId;
        if (remoteId != null && remoteId.isNotEmpty) {
          await _firestore.collection('tareas').doc(remoteId).delete();
        }
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
  final DriveDownloadOrchestrator _driveDownloadOrchestrator;

  TareasRepository(
    this.localStorage,
    this._uploadQueueService,
    this._driveUploadOrchestrator,
    this._driveDownloadOrchestrator,
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
        final tareaFirestore = TareaMapper.fromFirestoreQueryDocument(doc);

        // Firestore no guarda la ruta local del dispositivo. Si la tarea ya
        // existe localmente con adjuntos pendientes de subir, restauramos el
        // path para que la subida diferida pueda continuar.
        final tareaLocal = await localStorage.getTareaByIdInternal(
          tareaFirestore.id,
        );
        final adjuntosMerged = _mergeAdjuntosConLocal(
          tareaFirestore.adjuntos,
          tareaLocal?.adjuntos ?? const [],
        );

        await localStorage.saveTarea(
          tareaFirestore.copyWith(adjuntos: adjuntosMerged),
        );
      }

      // Descarga en segundo plano los adjuntos remotos que aun no existen
      // localmente en este dispositivo.
      unawaited(
        _driveDownloadOrchestrator.downloadMissingAttachmentsForCurrentUser(),
      );

      return snapshot.docs.length;
    } catch (e) {
      print('Error sincronizando tareas desde Firestore: $e');
      return 0;
    }
  }

  /// Combina los adjuntos descargados de Firestore con los locales.
  ///
  /// Firestore no almacena el `path` local, por lo que si un adjunto
  /// pendiente de subir ya existe en la BD local (con su ruta), se le
  /// devuelve esa ruta para que el proceso de subida pueda continuar.
  static List<Map<String, dynamic>> _mergeAdjuntosConLocal(
    List<Map<String, dynamic>> fromFirestore,
    List<Map<String, dynamic>> fromLocal,
  ) {
    if (fromLocal.isEmpty) return fromFirestore;

    return fromFirestore
        .map((firestoreAdj) {
          final id = attachmentIdOf(firestoreAdj);
          if (id == null) return firestoreAdj;

          final localAdj = fromLocal.firstWhere(
            (a) => attachmentIdOf(a) == id,
            orElse: () => <String, dynamic>{},
          );
          final localPath = attachmentPathOf(localAdj);
          if (localPath == null) return firestoreAdj;

          return <String, dynamic>{...firestoreAdj, 'path': localPath};
        })
        .toList(growable: false);
  }

  Future<void> processPendingUploads() async {
    await _driveUploadOrchestrator.processPendingUploads();
  }

  Future<void> processPendingDownloads() async {
    await _driveDownloadOrchestrator.downloadMissingAttachmentsForCurrentUser();
  }

  Future<void> synchronizeNow() async {
    await sincronizarDesdeServidor();
    await processPendingUploads();
    await processPendingDownloads();
  }

  Future<void> guardar(Tarea tarea, String clave, bool online) async {
    final tareaPersistida = await localStorage.saveTareaAndReturn(tarea);

    if (online) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = TareaMapper.toFirestoreMap(tareaPersistida, clave);
        data['userId'] = user.uid;

        try {
          final remoteId = tareaPersistida.firestoreId;
          if (remoteId != null && remoteId.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('tareas')
                .doc(remoteId)
                .set(data, SetOptions(merge: true));
          } else {
            final docRef = await FirebaseFirestore.instance
                .collection('tareas')
                .add(data);
            await localStorage.saveTarea(
              tareaPersistida.copyWith(firestoreId: docRef.id),
            );
          }
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
    final remoteId = tarea.firestoreId;
    if (online && remoteId != null && remoteId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(remoteId)
            .delete();
      } catch (_) {}
    }
    await localStorage.deleteTarea(tarea.localId);
    await _uploadQueueService.deleteByTaskId(tarea.localId);
    await NotificationService().cancelNotifications(tarea);
  }

  Future<void> marcarCompletada(
    Tarea tarea,
    bool completada,
    bool online,
  ) async {
    final actualizada = tarea.copyWith(completada: completada);

    final remoteId = tarea.firestoreId;
    if (online && remoteId != null && remoteId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(remoteId)
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
