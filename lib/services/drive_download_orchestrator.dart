import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../utils/attachment_utils.dart';
import 'conectividad_service.dart';
import 'inicia_con_google.dart';
import 'local_storage_service.dart';

class DriveDownloadOrchestrator {
  final LocalStorageService _localStorage;
  final ConectividadService _conectividadService;

  bool _isProcessing = false;

  DriveDownloadOrchestrator(this._localStorage, this._conectividadService);

  Future<Map<String, dynamic>?> ensureAttachmentDownloaded({
    required String taskId,
    required Map<String, dynamic> attachment,
  }) async {
    final normalized = normalizeAttachment(attachment);
    final localPath = attachmentPathOf(normalized);
    if (localPath != null && localPath.isNotEmpty) {
      final exists = await File(localPath).exists();
      if (exists) {
        return normalized;
      }
    }

    final driveId = attachmentDriveIdOf(normalized);
    if (driveId == null || driveId.isEmpty) {
      return normalized;
    }

    final online = await _isOnline();
    if (!online) return null;

    final token = await getGoogleAccessToken(
      requestDrive: true,
      interactiveScopePrompt: false,
    );
    if (token == null) return null;

    final fileName = attachmentNameOf(normalized) ?? 'drive_$driveId.bin';
    final downloadedPath = await _downloadDriveFile(
      token: token,
      driveId: driveId,
      fileName: fileName,
    );
    if (downloadedPath == null || downloadedPath.isEmpty) {
      return null;
    }

    final updatedAttachment = <String, dynamic>{
      ...normalized,
      'path': downloadedPath,
    };
    final attachmentId = attachmentIdOf(normalized);
    if (attachmentId != null && attachmentId.isNotEmpty) {
      await _localStorage.updateAttachment(
        taskId,
        attachmentId,
        updatedAttachment,
      );
    }

    return updatedAttachment;
  }

  Future<void> downloadMissingAttachmentsForCurrentUser() async {
    if (_isProcessing) return;

    final online = await _isOnline();
    if (!online) return;

    _isProcessing = true;
    try {
      final token = await getGoogleAccessToken(
        requestDrive: true,
        interactiveScopePrompt: false,
      );
      if (token == null) return;

      final tareas = await _localStorage.getTareas();
      for (final tarea in tareas) {
        final updatedAdjuntos = <Map<String, dynamic>>[];
        var changed = false;

        for (final attachment in tarea.adjuntos) {
          final normalized = normalizeAttachment(attachment);
          final updatedAttachment = await _downloadAttachmentIfMissing(
            token: token,
            taskId: tarea.id,
            attachment: normalized,
          );

          if (updatedAttachment != null) {
            changed = true;
            updatedAdjuntos.add(updatedAttachment);
          } else {
            updatedAdjuntos.add(normalized);
          }
        }

        if (changed) {
          await _localStorage.saveTarea(
            tarea.copyWith(adjuntos: updatedAdjuntos),
          );
        }
      }
    } catch (e, s) {
      debugPrint('DriveDownloadOrchestrator error: $e');
      debugPrintStack(stackTrace: s);
    } finally {
      _isProcessing = false;
    }
  }

  Future<Map<String, dynamic>?> _downloadAttachmentIfMissing({
    required String token,
    required String taskId,
    required Map<String, dynamic> attachment,
  }) async {
    final localPath = attachmentPathOf(attachment);
    if (localPath != null && localPath.isNotEmpty) {
      final exists = await File(localPath).exists();
      if (exists) return null;
    }

    final driveId = attachmentDriveIdOf(attachment);
    if (driveId == null || driveId.isEmpty) return null;

    final fileName = attachmentNameOf(attachment) ?? 'drive_$driveId.bin';
    final downloadedPath = await _downloadDriveFile(
      token: token,
      driveId: driveId,
      fileName: fileName,
    );
    if (downloadedPath == null || downloadedPath.isEmpty) {
      return null;
    }

    final updatedAttachment = <String, dynamic>{
      ...attachment,
      'path': downloadedPath,
    };
    final attachmentId = attachmentIdOf(attachment);
    if (attachmentId != null && attachmentId.isNotEmpty) {
      await _localStorage.updateAttachment(
        taskId,
        attachmentId,
        updatedAttachment,
      );
    }

    return updatedAttachment;
  }

  Future<String?> _downloadDriveFile({
    required String token,
    required String driveId,
    required String fileName,
  }) async {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse(
          'https://www.googleapis.com/drive/v3/files/$driveId?alt=media',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Drive download failed ($driveId): ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final appDir = await getApplicationSupportDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final targetPath = '${attachmentsDir.path}/${driveId}_$safeName';
      final targetFile = File(targetPath);

      await targetFile.writeAsBytes(response.bodyBytes, flush: true);
      return targetFile.path;
    } catch (e, s) {
      debugPrint('Drive download exception ($driveId): $e');
      debugPrintStack(stackTrace: s);
      return null;
    } finally {
      client.close();
    }
  }

  Future<bool> _isOnline() async {
    final networkTypes = await _conectividadService.currentConnections();
    return networkTypes.isNotEmpty &&
        !networkTypes.contains(ConnectivityResult.none);
  }
}
