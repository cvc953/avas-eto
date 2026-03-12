import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:avas_eto/services/local_storage_service.dart';
import 'package:avas_eto/controller/auth_controller.dart';

class TestLocalDb {
  final Database _db;
  TestLocalDb._(this._db);

  static Future<TestLocalDb> create() async {
    final db = await databaseFactoryMemory.openDatabase('auth_test.db');
    return TestLocalDb._(db);
  }

  Future<Database> get db async => _db;
}

void main() {
  test('signOut persists device owner id', () async {
    final testDb = await TestLocalDb.create();
    final localStorage = LocalStorageService(testDb as dynamic);

    final authController = AuthController(localStorage: localStorage);

    await authController.signOut(currentUidOverride: 'test-user-123');

    final persisted = await localStorage.getDeviceOwnerId();
    expect(persisted, 'test-user-123');
  });
}
