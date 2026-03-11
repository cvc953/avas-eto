import '../models/tarea.dart';
import 'conectividad_service.dart';
import 'drive_download_orchestrator.dart';
import 'local_database.dart';
import 'local_storage_service.dart';

class AttachmentAvailabilityService {
  final DriveDownloadOrchestrator _downloadOrchestrator;

  AttachmentAvailabilityService._(this._downloadOrchestrator);

  factory AttachmentAvailabilityService.withDefaults() {
    final localDb = LocalDatabase();
    final localStorage = LocalStorageService(localDb);
    final conectividad = ConectividadService();

    return AttachmentAvailabilityService._(
      DriveDownloadOrchestrator(localStorage, conectividad),
    );
  }

  Future<Map<String, dynamic>?> ensureAttachmentAvailable({
    required Tarea tarea,
    required Map<String, dynamic> attachment,
  }) {
    return _downloadOrchestrator.ensureAttachmentDownloaded(
      taskId: tarea.id,
      attachment: attachment,
    );
  }
}
