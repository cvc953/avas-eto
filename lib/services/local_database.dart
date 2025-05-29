import 'dart:async';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class LocalDatabase {
  Database? _db;
  final Completer<Database> _dbCompleter = Completer<Database>();

  LocalDatabase() {
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, 'tareas.db');

      // Abre la base de datos
      final database = await databaseFactoryIo.openDatabase(dbPath);

      // Completa el future con la base de datos inicializada
      if (!_dbCompleter.isCompleted) {
        _db = database;
        _dbCompleter.complete(database);
      }
    } catch (e) {
      if (!_dbCompleter.isCompleted) {
        _dbCompleter.completeError(e);
      }
      rethrow;
    }
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    return _dbCompleter.future;
  }
}
