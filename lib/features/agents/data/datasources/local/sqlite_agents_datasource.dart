import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../models/agent_model.dart';
import '../../../../../core/database/sqlite_helper.dart';
import '../../../../../core/config/supabase_config.dart';

abstract class AgentsLocalDataSource {
  Future<void> insertAgents(List<AgentModel> agents);
  Future<void> clearAllAgents();
  Future<int> getAgentsCount();
  Future<List<AgentModel>> getRoot();
  Future<List<AgentModel>> getChildren(String parentGuid);
  Future<List<AgentModel>> searchByName(String query);
}

class SqliteAgentsDatasourceImpl implements AgentsLocalDataSource {
  static Database? _database;

  String get _tableName => SupabaseConfig.schema + '_agents';

  Future<void> _ensureSchemaLoaded() async {
    await SupabaseConfig.loadFromPrefs();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _ensureSchemaLoaded();
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    if (!SqliteHelper.isInitialized) {
      await SqliteHelper.initialize();
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'agents.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _ensureTable(db);
      },
      onOpen: (db) async {
        await _ensureSchemaLoaded();
        await _ensureTable(db);
      },
    );
  }

  Future<void> _ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${_tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        guid TEXT NOT NULL,
        name TEXT NOT NULL,
        is_folder INTEGER NOT NULL DEFAULT 0,
        parent_guid TEXT NOT NULL DEFAULT '',
        created_at TEXT,
        password INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_tableName}_guid ON ${_tableName}(guid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_tableName}_parent ON ${_tableName}(parent_guid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_tableName}_name ON ${_tableName}(name)',
    );
  }

  @override
  Future<void> insertAgents(List<AgentModel> agents) async {
    final db = await database;
    await _ensureTable(db);
    final batch = db.batch();
    for (final a in agents) {
      batch.insert(
        _tableName,
        a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> clearAllAgents() async {
    final db = await database;
    await db.delete(_tableName);
  }

  @override
  Future<int> getAgentsCount() async {
    final db = await database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${_tableName}'),
    );
    return result ?? 0;
  }

  @override
  Future<List<AgentModel>> getRoot() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where:
          '(is_folder = 1 AND (parent_guid = ? OR parent_guid = ?)) OR (is_folder = 0 AND (parent_guid = ? OR parent_guid = ?))',
      whereArgs: [
        '00000000-0000-0000-0000-000000000000',
        '',
        '00000000-0000-0000-0000-000000000000',
        '',
      ],
      orderBy: 'is_folder DESC, name ASC',
    );
    return rows.map((e) => AgentModel.fromJson(e)).toList();
  }

  @override
  Future<List<AgentModel>> getChildren(String parentGuid) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'parent_guid = ?',
      whereArgs: [parentGuid],
      orderBy: 'is_folder DESC, name ASC',
    );
    return rows.map((e) => AgentModel.fromJson(e)).toList();
  }

  @override
  Future<List<AgentModel>> searchByName(String query) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'LOWER(name) LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%'],
      orderBy: 'name ASC',
      limit: 100,
    );
    return rows.map((e) => AgentModel.fromJson(e)).toList();
  }
}
