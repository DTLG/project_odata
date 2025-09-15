import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../../../core/database/sqlite_helper.dart';
import '../../../../../core/config/supabase_config.dart';

class RepairTypeModel {
  final String guid;
  final String name;
  final DateTime? createdAt;
  RepairTypeModel({required this.guid, required this.name, this.createdAt});

  factory RepairTypeModel.fromJson(Map<String, dynamic> json) =>
      RepairTypeModel(
        guid: (json['guid'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      );

  Map<String, dynamic> toMap() => {
    'guid': guid,
    'name': name,
    'created_at': createdAt?.toIso8601String() ?? '',
  };
}

abstract class TypesOfRepairLocalDataSource {
  Future<void> insertAll(List<RepairTypeModel> items);
  Future<void> clearAll();
  Future<int> getCount();
  Future<List<RepairTypeModel>> getAll();
}

class SqliteTypesOfRepairDatasource implements TypesOfRepairLocalDataSource {
  static Database? _db;

  String get _tableName => SupabaseConfig.schema + '_types_of_repair';

  Future<void> _ensureSchema() async => SupabaseConfig.loadFromPrefs();

  Future<Database> get database async {
    if (_db != null) return _db!;
    await _ensureSchema();
    if (!SqliteHelper.isInitialized) {
      await SqliteHelper.initialize();
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'repair_types.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async => _ensureTable(db),
      onOpen: (db) async => _ensureTable(db),
    );
    return _db!;
  }

  Future<void> _ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${_tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        guid TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_tableName}_guid ON ${_tableName}(guid)'
      '',
    );
  }

  @override
  Future<void> insertAll(List<RepairTypeModel> items) async {
    final db = await database;
    final batch = db.batch();
    for (final it in items) {
      batch.insert(
        _tableName,
        it.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }

  @override
  Future<int> getCount() async {
    final db = await database;
    final v = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${_tableName}'),
    );
    return v ?? 0;
  }

  @override
  Future<List<RepairTypeModel>> getAll() async {
    final db = await database;
    final rows = await db.query(_tableName, orderBy: 'name ASC');
    return rows.map((e) => RepairTypeModel.fromJson(e)).toList();
  }
}
