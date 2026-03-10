import 'dart:math';

class AttachmentSyncState {
  static const String pending = 'pending';
  static const String uploading = 'uploading';
  static const String uploaded = 'uploaded';
  static const String failed = 'failed';

  static const Set<String> values = {pending, uploading, uploaded, failed};
}

const String attachmentIdKey = 'attachmentId';
const String attachmentStateKey = 'state';
const String attachmentUpdatedAtKey = 'updatedAt';
const String attachmentUploadedAtKey = 'uploadedAt';
const String attachmentRetryCountKey = 'retryCount';
const String attachmentLastErrorKey = 'lastError';

final Random _attachmentRandom = Random();

List<Map<String, dynamic>> normalizeAttachments(
  List<Map<String, dynamic>> attachments,
) {
  return attachments.map(normalizeAttachment).toList(growable: false);
}

Map<String, dynamic> normalizeAttachment(Map<String, dynamic> attachment) {
  final normalized = Map<String, dynamic>.from(attachment);
  final localPath = _asNonEmptyString(normalized['path']);
  final driveId = _asNonEmptyString(normalized['driveId']);
  final name =
      _asNonEmptyString(normalized['name']) ?? _extractNameFromPath(localPath);

  normalized[attachmentIdKey] =
      _asNonEmptyString(normalized[attachmentIdKey]) ??
      _generateAttachmentId(localPath, name);

  if (name != null) {
    normalized['name'] = name;
  }

  if (localPath != null && localPath.isNotEmpty) {
    normalized['path'] = localPath;
  }

  if (driveId != null && driveId.isNotEmpty) {
    normalized['driveId'] = driveId;
  }

  normalized[attachmentRetryCountKey] = _asInt(
    normalized[attachmentRetryCountKey],
  );

  final requestedState = _asNonEmptyString(normalized[attachmentStateKey]);
  final resolvedState =
      driveId != null
          ? AttachmentSyncState.uploaded
          : AttachmentSyncState.values.contains(requestedState)
          ? requestedState!
          : AttachmentSyncState.pending;
  normalized[attachmentStateKey] = resolvedState;

  normalized[attachmentUpdatedAtKey] =
      _asNonEmptyString(normalized[attachmentUpdatedAtKey]) ??
      DateTime.now().toIso8601String();

  if (resolvedState == AttachmentSyncState.uploaded) {
    normalized[attachmentUploadedAtKey] =
        _asNonEmptyString(normalized[attachmentUploadedAtKey]) ??
        DateTime.now().toIso8601String();
    normalized.remove(attachmentLastErrorKey);
  }

  return normalized;
}

bool attachmentNeedsUpload(Map<String, dynamic> attachment) {
  final normalized = normalizeAttachment(attachment);
  return _asNonEmptyString(normalized['path']) != null &&
      _asNonEmptyString(normalized['driveId']) == null;
}

Map<String, dynamic> markAttachmentUploading(Map<String, dynamic> attachment) {
  final normalized = normalizeAttachment(attachment);
  normalized[attachmentStateKey] = AttachmentSyncState.uploading;
  normalized[attachmentUpdatedAtKey] = DateTime.now().toIso8601String();
  normalized.remove(attachmentLastErrorKey);
  return normalized;
}

Map<String, dynamic> markAttachmentUploaded(
  Map<String, dynamic> attachment,
  String driveId,
) {
  final normalized = normalizeAttachment(attachment);
  normalized['driveId'] = driveId;
  normalized[attachmentStateKey] = AttachmentSyncState.uploaded;
  normalized[attachmentUpdatedAtKey] = DateTime.now().toIso8601String();
  normalized[attachmentUploadedAtKey] = DateTime.now().toIso8601String();
  normalized.remove(attachmentLastErrorKey);
  return normalized;
}

Map<String, dynamic> markAttachmentFailed(
  Map<String, dynamic> attachment,
  String error,
) {
  final normalized = normalizeAttachment(attachment);
  normalized[attachmentStateKey] = AttachmentSyncState.failed;
  normalized[attachmentUpdatedAtKey] = DateTime.now().toIso8601String();
  normalized[attachmentRetryCountKey] =
      _asInt(normalized[attachmentRetryCountKey]) + 1;
  normalized[attachmentLastErrorKey] = error;
  return normalized;
}

String? attachmentIdOf(Map<String, dynamic> attachment) {
  return _asNonEmptyString(attachment[attachmentIdKey]);
}

String? attachmentNameOf(Map<String, dynamic> attachment) {
  return _asNonEmptyString(attachment['name']);
}

String? attachmentPathOf(Map<String, dynamic> attachment) {
  return _asNonEmptyString(attachment['path']);
}

String? attachmentDriveIdOf(Map<String, dynamic> attachment) {
  return _asNonEmptyString(attachment['driveId']);
}

String _generateAttachmentId(String? localPath, String? name) {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final seed = localPath ?? name ?? 'attachment';
  final entropy = _attachmentRandom.nextInt(1 << 20);
  return '${seed.hashCode.abs()}-$timestamp-$entropy';
}

String? _extractNameFromPath(String? path) {
  if (path == null || path.isEmpty) return null;
  final segments = path.split('/');
  return segments.isEmpty ? null : segments.last;
}

String? _asNonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
