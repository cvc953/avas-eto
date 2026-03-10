// ignore_for_file: uri_does_not_exist, undefined_function

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import '../services/conectividad_service.dart';
import '../services/drive_upload_orchestrator.dart';
import '../services/local_database.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/upload_queue_service.dart';

class BackgroundTasks {
  static const String periodicUploadTask = 'drive-upload-periodic-task';
  static const String oneOffUploadTask = 'drive-upload-now-task';
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    final firebaseSupported = kIsWeb || Platform.isAndroid || Platform.isIOS;
    if (firebaseSupported) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (_) {}
    }

    final localDb = LocalDatabase();
    final localStorage = LocalStorageService(localDb);
    final queueService = UploadQueueService(localDb);
    final connectivity = ConectividadService();
    final orchestrator = DriveUploadOrchestrator(
      queueService,
      localStorage,
      connectivity,
      NotificationService(),
      firebaseSupported ? FirebaseFirestore.instance : null,
    );

    switch (task) {
      case BackgroundTasks.periodicUploadTask:
      case BackgroundTasks.oneOffUploadTask:
        await orchestrator.processPendingUploads();
        return Future.value(true);
      default:
        return Future.value(true);
    }
  });
}
