import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../constants/app_constants.dart';

/// Desktop/mobile SQLite-backed activity store.
abstract class AppDatabase {
  Future<void> logActivity(String kind, String message);
  Future<void> recordLabAttempt(String labId, int score, int durationSec);
}

class _SqliteAppDatabase implements AppDatabase {
  _SqliteAppDatabase(this._db);
  final Database _db;

  @override
  Future<void> logActivity(String kind, String message) async {
    await _db.insert('activity_log', {
      'kind': kind,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> recordLabAttempt(String labId, int score, int durationSec) async {
    await _db.insert('lab_attempts', {
      'lab_id': labId,
      'score': score,
      'duration_sec': durationSec,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }
}

Future<AppDatabase> openAppDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final dir = await getApplicationDocumentsDirectory();
  final db = await databaseFactory.openDatabase(
    '${dir.path}/${AppConstants.dbName}',
    options: OpenDatabaseOptions(
      version: AppConstants.dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE lab_attempts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lab_id TEXT NOT NULL,
            score INTEGER NOT NULL,
            duration_sec INTEGER NOT NULL,
            completed_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE exam_attempts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            exam_id TEXT NOT NULL,
            score INTEGER NOT NULL,
            passed INTEGER NOT NULL,
            completed_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE activity_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT NOT NULL,
            message TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    ),
  );
  return _SqliteAppDatabase(db);
}
