import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/repair_request_model.dart';

abstract class RepairLocalDataSource {
  Future<void> save(RepairRequestModel model);
  Future<List<RepairRequestModel>> getAll();
  Future<void> delete(String id);
}

class RepairLocalDataSourceImpl implements RepairLocalDataSource {
  static Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'repair_requests.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS repairs (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  @override
  Future<void> save(RepairRequestModel model) async {
    final db = await _database;
    // Build stable local id to avoid duplicates
    final map = model.toJson();
    String? localId;
    // Prefer server identity if present
    if (map['id'] != null && map['id'].toString().isNotEmpty) {
      localId = map['id'].toString();
    } else if (map['doc_guid'] != null &&
        (map['doc_guid'] as String).isNotEmpty) {
      localId = map['doc_guid'] as String;
    } else if (map['number'] != null && (map['number'] as String).isNotEmpty) {
      localId = map['number'] as String;
    } else if (map['local_id'] != null &&
        (map['local_id'] as String).isNotEmpty) {
      localId = map['local_id'] as String;
    } else {
      localId = 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';
    }
    // Persist local_id inside payload for future saves
    map['local_id'] = localId;
    await db.insert('repairs', {
      'id': localId,
      'data': RepairRequestModel.fromJson(map).toJsonString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<RepairRequestModel>> getAll() async {
    final db = await _database;
    final rows = await db.query('repairs', orderBy: 'id DESC');
    return rows
        .map((r) => RepairRequestModel.fromJsonString(r['data'] as String))
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('repairs', where: 'id = ?', whereArgs: [id]);
  }
}
