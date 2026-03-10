import 'background_upload_scheduler_noop.dart'
    if (dart.library.io) 'background_upload_scheduler_workmanager.dart'
    as impl;

class BackgroundUploadScheduler {
  static Future<void> initialize() => impl.initialize();
  static Future<void> ensureScheduled() => impl.ensureScheduled();
  static Future<void> triggerNow() => impl.triggerNow();
}
