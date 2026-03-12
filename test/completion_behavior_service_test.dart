import 'package:avas_eto/models/tarea.dart';
import 'package:avas_eto/services/completion_behavior_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

class TestLocalDb {
  final Database _db;
  TestLocalDb._(this._db);

  static Future<TestLocalDb> create() async {
    final db = await databaseFactoryMemory.openDatabase(
      'completion-behavior-test.db',
    );
    return TestLocalDb._(db);
  }

  Future<Database> get db async => _db;
}

Tarea buildTarea({String id = 'task-1', DateTime? dueAt}) {
  final now = DateTime(2026, 3, 12, 9, 0);
  return Tarea(
    id: id,
    title: 'Tarea $id',
    prioridad: 'Alta',
    color: Colors.blue,
    fechaCreacion: now,
    fechaInicio: now.add(const Duration(hours: 1)),
    fechaVencimiento: dueAt ?? now.add(const Duration(hours: 5)),
    fechaCompletada: DateTime(0),
    adjuntos: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'recordCompletion stores hour, weekday and hours from deadline',
    () async {
      final testDb = await TestLocalDb.create();
      final service = CompletionBehaviorService(
        localDatabase: testDb as dynamic,
      );
      final dueAt = DateTime(2026, 3, 12, 14, 0);
      final completedAt = DateTime(2026, 3, 12, 9, 30);

      await service.recordCompletion(
        buildTarea(dueAt: dueAt),
        completedAt: completedAt,
      );

      final events = await service.getRecentEvents(referenceNow: completedAt);
      expect(events.length, 1);
      expect(events.single.hourOfDay, 9);
      expect(events.single.dayOfWeek, DateTime.thursday);
      expect(events.single.hoursFromDeadline, 4);
    },
  );

  test('getRecentEvents purges local records older than 30 days', () async {
    final testDb = await TestLocalDb.create();
    final service = CompletionBehaviorService(localDatabase: testDb as dynamic);
    final now = DateTime(2026, 3, 12, 9, 0);

    await service.recordCompletion(
      buildTarea(id: 'old', dueAt: now.subtract(const Duration(days: 34))),
      completedAt: now.subtract(const Duration(days: 31)),
    );
    await service.recordCompletion(
      buildTarea(id: 'new', dueAt: now.add(const Duration(hours: 6))),
      completedAt: now.subtract(const Duration(days: 2)),
    );

    final events = await service.getRecentEvents(referenceNow: now);
    expect(events.length, 1);
    expect(events.single.taskId, 'new');
  });
}
