import 'package:sembast/sembast.dart';

import '../models/tarea.dart';
import '../models/upload_queue_item.dart';
import '../utils/attachment_utils.dart';
import 'local_database.dart';

class UploadQueueService {
  static const String pendingStatus = AttachmentSyncState.pending;
  static const String uploadingStatus = AttachmentSyncState.uploading;
  static const String failedStatus = AttachmentSyncState.failed;

  final LocalDatabase _localDb;
  final StoreRef<String, Map<String, dynamic>> _store = stringMapStoreFactory
      .store('drive_upload_queue');

  UploadQueueService(this._localDb);

  Future<void> enqueueAttachmentsForTask(Tarea tarea) async {
    final database = await _localDb.db;

    for (final attachment in tarea.adjuntos) {
      if (!attachmentNeedsUpload(attachment)) continue;

      final normalized = normalizeAttachment(attachment);
      final attachmentId = attachmentIdOf(normalized);
      final localPath = attachmentPathOf(normalized);
      if (attachmentId == null || localPath == null) continue;

      final existing = await _store.record(attachmentId).get(database);
      final now = DateTime.now();

      final item = UploadQueueItem(
        id: attachmentId,
        taskId: tarea.id,
        attachmentId: attachmentId,
        localPath: localPath,
        fileName: attachmentNameOf(normalized) ?? 'Adjunto',
        size: (normalized['size'] as num?)?.toInt() ?? 0,
        status:
            existing == null
                ? pendingStatus
                : (existing['status'] as String? ?? pendingStatus),
        retryCount: (existing?['retryCount'] as num?)?.toInt() ?? 0,
        createdAt:
            existing != null
                ? DateTime.parse(existing['createdAt'] as String)
                : now,
        updatedAt: now,
        lastError: existing?['lastError'] as String?,
      );

      await _store.record(attachmentId).put(database, item.toMap());
    }
  }

  Future<List<UploadQueueItem>> getProcessableItems({
    int maxRetries = 5,
  }) async {
    final database = await _localDb.db;
    final finder = Finder(sortOrders: [SortOrder('createdAt')]);
    final records = await _store.find(database, finder: finder);

    final items = records
        .map((record) => UploadQueueItem.fromMap(record.value))
        .where(
          (item) =>
              item.retryCount < maxRetries &&
              (item.status == pendingStatus || item.status == failedStatus),
        )
        .toList(growable: false);

    return items;
  }

  Future<void> markUploading(String attachmentId) async {
    await _updateStatus(attachmentId, uploadingStatus, clearError: true);
  }

  Future<void> markPending(String attachmentId) async {
    await _updateStatus(attachmentId, pendingStatus);
  }

  Future<void> markUploaded(String attachmentId) async {
    final database = await _localDb.db;
    await _store.record(attachmentId).delete(database);
  }

  Future<void> markFailed(String attachmentId, String error) async {
    final database = await _localDb.db;
    final record = await _store.record(attachmentId).get(database);
    if (record == null) return;

    final item = UploadQueueItem.fromMap(record).copyWith(
      status: failedStatus,
      retryCount: UploadQueueItem.fromMap(record).retryCount + 1,
      updatedAt: DateTime.now(),
      lastError: error,
    );

    await _store.record(attachmentId).put(database, item.toMap());
  }

  Future<void> deleteByTaskId(String taskId) async {
    final database = await _localDb.db;
    final finder = Finder(filter: Filter.equals('taskId', taskId));
    await _store.delete(database, finder: finder);
  }

  Future<int> pendingCount() async {
    final items = await getProcessableItems();
    return items.length;
  }

  Future<void> _updateStatus(
    String attachmentId,
    String status, {
    bool clearError = false,
  }) async {
    final database = await _localDb.db;
    final record = await _store.record(attachmentId).get(database);
    if (record == null) return;

    final current = UploadQueueItem.fromMap(record);
    final updated = current.copyWith(
      status: status,
      updatedAt: DateTime.now(),
      clearLastError: clearError,
    );

    await _store.record(attachmentId).put(database, updated.toMap());
  }
}
