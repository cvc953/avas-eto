import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../mappers/tarea_mapper.dart';
import '../models/upload_queue_item.dart';
import '../utils/task_key_generator.dart';
import '../utils/attachment_utils.dart';
import 'conectividad_service.dart';
import 'drive_service.dart';
import 'inicia_con_google.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';
import 'upload_preferences_service.dart';
import 'upload_queue_service.dart';

class DriveUploadOrchestrator {
  final UploadQueueService _queueService;
  final LocalStorageService _localStorage;
  final ConectividadService _conectividadService;
  final NotificationService _notificationService;
  final FirebaseFirestore? _firestore;

  bool _isProcessing = false;

  DriveUploadOrchestrator(
    this._queueService,
    this._localStorage,
    this._conectividadService,
    this._notificationService,
    this._firestore,
  );

  Future<void> processPendingUploads() async {
    if (_isProcessing) return;

    final canUpload = await _canUploadNow();
    if (!canUpload) {
      await _notificationService.cancelDriveUploadStatus();
      return;
    }

    _isProcessing = true;
    try {
      final items = await _queueService.getProcessableItems();
      if (items.isEmpty) {
        await _notificationService.cancelDriveUploadStatus();
        return;
      }

      final token = await getGoogleAccessToken(
        requestDrive: true,
        interactiveScopePrompt: false,
      );
      if (token == null) {
        debugPrint('DriveUploadOrchestrator: no hay token Drive disponible.');
        await _notificationService.failDriveUploadStatus(
          'No hay una sesion valida de Google Drive para completar la subida.',
        );
        return;
      }

      var completed = 0;
      final total = items.length;
      for (final item in items) {
        if (!await _canUploadNow()) break;

        await _queueService.markUploading(item.attachmentId);
        await _notificationService.showDriveUploadStatus(
          fileName: item.fileName,
          completed: completed,
          total: total,
        );

        final success = await _processSingleItem(item, token);
        if (success) {
          completed++;
        }

        await _notificationService.showDriveUploadStatus(
          fileName: item.fileName,
          completed: completed,
          total: total,
        );
      }

      if (completed == total) {
        await _notificationService.completeDriveUploadStatus(total);
      } else if (completed > 0) {
        await _notificationService.failDriveUploadStatus(
          'Se subieron $completed de $total adjuntos.',
        );
      } else {
        await _notificationService.cancelDriveUploadStatus();
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _processSingleItem(UploadQueueItem item, String token) async {
    final localFile = File(item.localPath);
    if (!await localFile.exists()) {
      await _queueService.markFailed(
        item.attachmentId,
        'El archivo local ya no existe.',
      );
      final failedAttachment = await _updateAttachmentStatus(
        item.taskId,
        item.attachmentId,
        (attachment) =>
            markAttachmentFailed(attachment, 'El archivo local ya no existe.'),
      );
      return failedAttachment != null;
    }

    await _updateAttachmentStatus(
      item.taskId,
      item.attachmentId,
      markAttachmentUploading,
    );

    final driveId = await uploadFileToDrive(localFile, token);
    if (driveId == null) {
      await _queueService.markFailed(
        item.attachmentId,
        'No se pudo completar la subida a Drive.',
      );
      await _updateAttachmentStatus(
        item.taskId,
        item.attachmentId,
        (attachment) => markAttachmentFailed(
          attachment,
          'No se pudo completar la subida a Drive.',
        ),
      );
      return false;
    }

    final updatedAttachment = await _updateAttachmentStatus(
      item.taskId,
      item.attachmentId,
      (attachment) => markAttachmentUploaded(attachment, driveId),
    );

    if (updatedAttachment == null) {
      await _queueService.markFailed(
        item.attachmentId,
        'No se encontro la tarea asociada al adjunto.',
      );
      return false;
    }

    await _queueService.markUploaded(item.attachmentId);
    await _syncTaskToFirestore(item.taskId);
    return true;
  }

  Future<Map<String, dynamic>?> _updateAttachmentStatus(
    String taskId,
    String attachmentId,
    Map<String, dynamic> Function(Map<String, dynamic>) transform,
  ) async {
    final tarea = await _localStorage.getTareaById(taskId);
    if (tarea == null) return null;

    Map<String, dynamic>? updatedAttachment;
    final updatedAttachments = tarea.adjuntos
        .map((attachment) {
          if (attachmentIdOf(attachment) != attachmentId) {
            return normalizeAttachment(attachment);
          }
          updatedAttachment = transform(attachment);
          return updatedAttachment!;
        })
        .toList(growable: false);

    if (updatedAttachment == null) return null;

    await _localStorage.saveTarea(tarea.copyWith(adjuntos: updatedAttachments));
    return updatedAttachment;
  }

  Future<void> _syncTaskToFirestore(String taskId) async {
    if (_firestore == null) return;

    final tarea = await _localStorage.getTareaById(taskId);
    if (tarea == null || tarea.id.isEmpty) return;

    try {
      final clave = TaskKeyGenerator.generateKeyFromDateTime(
        tarea.fechaVencimiento,
      );
      final data = TareaMapper.toFirestoreMap(tarea, clave);
      await _firestore.collection('tareas').doc(tarea.id).set(data);
    } catch (error) {
      debugPrint('Error sincronizando upload a Firestore: $error');
    }
  }

  Future<bool> _canUploadNow() async {
    final networkTypes = await _conectividadService.currentConnections();
    final isOnline =
        networkTypes.isNotEmpty &&
        !networkTypes.contains(ConnectivityResult.none);
    if (!isOnline) return false;

    if (networkTypes.contains(ConnectivityResult.wifi) ||
        networkTypes.contains(ConnectivityResult.ethernet)) {
      return true;
    }

    if (networkTypes.contains(ConnectivityResult.mobile)) {
      return await UploadPreferencesService.isMobileDataUploadEnabled();
    }

    return false;
  }
}
