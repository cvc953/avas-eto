import 'dart:async';

import 'package:avas_eto/models/tarea.dart';
import 'package:avas_eto/repositories/tareas_repository.dart';
import 'package:avas_eto/services/conectividad_service.dart';
import 'package:avas_eto/services/drive_download_orchestrator.dart';
import 'package:avas_eto/services/drive_upload_orchestrator.dart';
import 'package:avas_eto/services/local_storage_service.dart';
import 'package:avas_eto/services/notification_service.dart';
import 'package:avas_eto/services/upload_queue_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

class TestLocalDb {
  final Database _db;
  TestLocalDb._(this._db);

  static Future<TestLocalDb> create() async {
    final db = await databaseFactoryMemory.openDatabase('repo-test.db');
    return TestLocalDb._(db);
  }

  Future<Database> get db async => _db;
}

Tarea buildTarea() {
  final now = DateTime.now();
  return Tarea(
    id: '',
    title: 'Tarea offline-first',
    prioridad: 'Alta',
    color: Colors.blue,
    fechaCreacion: now,
    fechaInicio: now.add(const Duration(hours: 1)),
    fechaVencimiento: now.add(const Duration(hours: 2)),
    fechaCompletada: DateTime(0),
    adjuntos: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'guardar no espera sync remoto y persiste local inmediatamente',
    () async {
      final testDb = await TestLocalDb.create();
      final localStorage = LocalStorageService(testDb as dynamic);
      final uploadQueue = UploadQueueService(testDb as dynamic);
      final conectividad = ConectividadService();

      final repository = TareasRepository(
        localStorage,
        uploadQueue,
        DriveUploadOrchestrator(
          uploadQueue,
          localStorage,
          conectividad,
          NotificationService(),
          null,
        ),
        DriveDownloadOrchestrator(localStorage, conectividad),
        cancelNotificationsOverride: (_) async {},
        notifyTaskCreatedOverride: (_) async {},
        syncTaskOverride: (_, __) async {
          await Future<void>.delayed(const Duration(seconds: 2));
        },
      );

      final stopwatch = Stopwatch()..start();
      await repository.guardar(buildTarea(), '2026-03-11-10-00', true);
      stopwatch.stop();

      final tareas = await localStorage.getTareas();
      expect(tareas.length, 1);
      expect(tareas.first.localId.isNotEmpty, isTrue);

      // Si guardar esperara Firestore, este elapsed seria ~2s.
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    },
  );

  test(
    'marcarCompletada registra evento de comportamiento al completar',
    () async {
      final testDb = await TestLocalDb.create();
      final localStorage = LocalStorageService(testDb as dynamic);
      final uploadQueue = UploadQueueService(testDb as dynamic);
      final conectividad = ConectividadService();
      final completions = <DateTime>[];

      final repository = TareasRepository(
        localStorage,
        uploadQueue,
        DriveUploadOrchestrator(
          uploadQueue,
          localStorage,
          conectividad,
          NotificationService(),
          null,
        ),
        DriveDownloadOrchestrator(localStorage, conectividad),
        cancelNotificationsOverride: (_) async {},
        notifyTaskCreatedOverride: (_) async {},
        recordCompletionOverride: (tarea, {completedAt}) async {
          completions.add(completedAt!);
        },
      );

      final tarea = buildTarea();
      await repository.marcarCompletada(tarea, true, false);

      expect(completions.length, 1);
      final persisted = await localStorage.getTareas();
      expect(persisted.single.completada, isTrue);
      expect(persisted.single.fechaCompletada.isAfter(DateTime(2020)), isTrue);
    },
  );
}
