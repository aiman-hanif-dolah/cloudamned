import 'package:hive_flutter/hive_flutter.dart';

/// Web persistence via Hive (no sqflite_ffi on browser).
abstract class AppDatabase {
  Future<void> logActivity(String kind, String message);
  Future<void> recordLabAttempt(String labId, int score, int durationSec);
}

class _HiveAppDatabase implements AppDatabase {
  _HiveAppDatabase(this._box);
  final Box _box;

  @override
  Future<void> logActivity(String kind, String message) async {
    final list = List<Map>.from(_box.get('activity_log', defaultValue: <Map>[]) as List? ?? []);
    list.insert(0, {
      'kind': kind,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
    if (list.length > 500) list.removeRange(500, list.length);
    await _box.put('activity_log', list);
  }

  @override
  Future<void> recordLabAttempt(String labId, int score, int durationSec) async {
    final list = List<Map>.from(_box.get('lab_attempts', defaultValue: <Map>[]) as List? ?? []);
    list.insert(0, {
      'lab_id': labId,
      'score': score,
      'duration_sec': durationSec,
      'completed_at': DateTime.now().toIso8601String(),
    });
    await _box.put('lab_attempts', list);
  }
}

Future<AppDatabase> openAppDatabase() async {
  final box = await Hive.openBox('cloudamned_db_web');
  return _HiveAppDatabase(box);
}
