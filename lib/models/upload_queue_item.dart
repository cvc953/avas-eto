class UploadQueueItem {
  final String id;
  final String taskId;
  final String attachmentId;
  final String localPath;
  final String fileName;
  final int size;
  final String status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastError;

  const UploadQueueItem({
    required this.id,
    required this.taskId,
    required this.attachmentId,
    required this.localPath,
    required this.fileName,
    required this.size,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
  });

  UploadQueueItem copyWith({
    String? id,
    String? taskId,
    String? attachmentId,
    String? localPath,
    String? fileName,
    int? size,
    String? status,
    int? retryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastError,
    bool clearLastError = false,
  }) {
    return UploadQueueItem(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      attachmentId: attachmentId ?? this.attachmentId,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'attachmentId': attachmentId,
      'localPath': localPath,
      'fileName': fileName,
      'size': size,
      'status': status,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastError': lastError,
    };
  }

  factory UploadQueueItem.fromMap(Map<String, dynamic> map) {
    return UploadQueueItem(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      attachmentId: map['attachmentId'] as String,
      localPath: map['localPath'] as String,
      fileName: map['fileName'] as String? ?? 'Adjunto',
      size: (map['size'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      lastError: map['lastError'] as String?,
    );
  }
}
