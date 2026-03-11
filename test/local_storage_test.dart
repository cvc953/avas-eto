import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:avas_eto/services/local_storage_service.dart';
import 'package:avas_eto/models/tarea.dart';
import 'package:flutter/material.dart';

class TestLocalDb {
  final Database _db;
  TestLocalDb._(this._db);

  static Future<TestLocalDb> create() async {
    final db = await databaseFactoryMemory.openDatabase('test.db');
    return TestLocalDb._(db);
  }

  Future<Database> get db async => _db;
}

Future<Tarea> buildTarea(
  String id,
  DateTime fechaVencimiento, {
  String prioridad = 'Media',
}) async {
  return Tarea(
    id: id,
    title: 'Tarea $id',
    prioridad: prioridad,
    color: Colors.blue,
    fechaCreacion: DateTime.now(),
    fechaVencimiento: fechaVencimiento,
    fechaCompletada: DateTime.now(),
  );
}

void main() {
  test('device owner persistence and task visibility', () async {
    final testDb = await TestLocalDb.create();
    final localStorage = LocalStorageService(testDb as dynamic);

    // Persist device owner A
    await localStorage.setDeviceOwnerId('userA');

    final tarea1 = await buildTarea(
      '1',
      DateTime.now().add(const Duration(days: 1)),
      prioridad: 'Alta',
    );
    await localStorage.saveTarea(tarea1);

    final tareasForA = await localStorage.getTareas();
    expect(tareasForA.length, 1);

    // Change device owner to B
    await localStorage.setDeviceOwnerId('userB');
    final tareasForB = await localStorage.getTareas();
    expect(tareasForB.length, 0);

    // getTareaById should respect owner
    final tareaFetched = await localStorage.getTareaById('1');
    expect(tareaFetched, isNull);

    // restore device owner A and fetch by id
    await localStorage.setDeviceOwnerId('userA');
    final tareaFetched2 = await localStorage.getTareaById('1');
    expect(tareaFetched2, isNotNull);
  });
}
