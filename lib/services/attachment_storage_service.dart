import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio responsable de mover adjuntos seleccionados a almacenamiento
/// interno estable de la app, para que sigan disponibles en subidas diferidas.
class AttachmentStorageService {
  const AttachmentStorageService();

  Future<List<Map<String, dynamic>>> persistPickedFiles(
    List<PlatformFile> files,
  ) async {
    final persisted = <Map<String, dynamic>>[];

    for (final file in files) {
      final originalPath = file.path;
      if (originalPath == null) continue;

      final stablePath = await _persistAttachmentPath(originalPath, file.name);
      if (stablePath == null) continue;

      persisted.add({'path': stablePath, 'name': file.name, 'size': file.size});
    }

    return persisted;
  }

  Future<String?> _persistAttachmentPath(
    String originalPath,
    String fileName,
  ) async {
    try {
      final source = File(originalPath);
      if (!await source.exists()) return originalPath;

      // Use getApplicationSupportDirectory() which maps to <appDataDir>/files/
      // on Android — covered by FileProvider's <files-path path="."> entry.
      // getApplicationDocumentsDirectory() maps to app_flutter/ which is NOT
      // covered by FileProvider and causes IllegalArgumentException when opening.
      final appDir = await getApplicationSupportDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final targetPath =
          '${attachmentsDir.path}/${DateTime.now().microsecondsSinceEpoch}_$safeName';

      final copied = await source.copy(targetPath);
      return copied.path;
    } catch (e) {
      debugPrint('No se pudo persistir adjunto "$fileName": $e');
      return originalPath;
    }
  }
}
