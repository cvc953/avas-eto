// ignore_for_file: uri_does_not_exist, undefined_function, undefined_identifier

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../utils/background_tasks.dart';
import 'upload_preferences_service.dart';

Future<void> initialize() async {
  if (!Platform.isAndroid || kIsWeb) return;
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
}

Future<void> ensureScheduled() async {
  if (!Platform.isAndroid || kIsWeb) return;

  final mobileEnabled =
      await UploadPreferencesService.isMobileDataUploadEnabled();

  await Workmanager().registerPeriodicTask(
    'drive-upload-periodic',
    BackgroundTasks.periodicUploadTask,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingWorkPolicy.update,
    constraints: Constraints(
      networkType:
          mobileEnabled ? NetworkType.connected : NetworkType.unmetered,
    ),
    initialDelay: const Duration(minutes: 1),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 2),
  );
}

Future<void> triggerNow() async {
  if (!Platform.isAndroid || kIsWeb) return;

  final mobileEnabled =
      await UploadPreferencesService.isMobileDataUploadEnabled();

  await Workmanager().registerOneOffTask(
    'drive-upload-now-${DateTime.now().millisecondsSinceEpoch}',
    BackgroundTasks.oneOffUploadTask,
    constraints: Constraints(
      networkType:
          mobileEnabled ? NetworkType.connected : NetworkType.unmetered,
    ),
    initialDelay: const Duration(seconds: 10),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 1),
  );
}
