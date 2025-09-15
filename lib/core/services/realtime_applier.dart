import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../database/sqlite_helper.dart';

class RealtimeApplier {
  static Future<void> apply(PostgresChangePayload payload) async {
    try {
      final table = payload.table ?? '';
      if (table.isEmpty) return;

      switch (table) {
        case 'nomenklatura':
          await _applyNomenclature(payload);
          break;
        case 'barcodes':
          await _applyBarcodes(payload);
          break;
        case 'prices':
          await _applyPrices(payload);
          break;
        case 'kontragenty':
          await _applyKontragenty(payload);
          break;
        default:
          // ignore: avoid_print
          print('ℹ️ RealtimeApplier: table ${payload.table} ignored');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ RealtimeApplier error: $e');
    }
  }

  // region DB helpers
  static Future<Database> _openNomenclatureDb() async {
    if (!SqliteHelper.isInitialized) {
      await SqliteHelper.initialize();
    }
    final dbPath = await getDatabasesPath();
    return openDatabase(join(dbPath, 'nomenclature.db'));
  }

  static Future<Database> _openKontragentyDb() async {
    if (!SqliteHelper.isInitialized) {
      await SqliteHelper.initialize();
    }
    final dbPath = await getDatabasesPath();
    return openDatabase(join(dbPath, 'kontragenty.db'));
  }

  static String get _schema =>
      SupabaseConfig.schema.isNotEmpty ? SupabaseConfig.schema : 'public';
  // endregion

  // region Nomenclature
  static Future<void> _applyNomenclature(PostgresChangePayload p) async {
    final db = await _openNomenclatureDb();
    final table = '${_schema}_nomenclature';
    await _ensureNomenclatureTables(db);

    if (p.eventType == PostgresChangeEvent.delete) {
      final guid = p.oldRecord['guid'] as String?;
      if (guid == null) return;
      await db.delete(table, where: 'guid = ?', whereArgs: [guid]);
      return;
    }

    final newRec = p.newRecord;
    if (newRec.isEmpty) return;

    final guid = (newRec['guid'] ?? '') as String;
    final data = <String, Object?>{
      'id': newRec['id']?.toString() ?? '',
      'createdAt':
          DateTime.tryParse(
            newRec['created_at']?.toString() ?? '',
          )?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'name': (newRec['name'] ?? '').toString(),
      'price': (newRec['price'] as num?)?.toDouble() ?? 0.0,
      'guid': guid,
      'parentGuid': (newRec['parent_guid'] ?? '') as String,
      'isFolder':
          ((newRec['is_folder'] ?? 0) == 1 ||
              (newRec['is_folder'] ?? false) == true)
          ? 1
          : 0,
      'description': (newRec['description'] ?? '').toString(),
      'article': (newRec['article'] ?? '').toString(),
      'unitName': (newRec['unit_name'] ?? '').toString(),
      'unitGuid': (newRec['unit_guid'] ?? '').toString(),
    };

    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> _applyBarcodes(PostgresChangePayload p) async {
    final db = await _openNomenclatureDb();
    final table = '${_schema}_barcodes';
    await _ensureNomenclatureTables(db);

    if (p.eventType == PostgresChangeEvent.delete) {
      final nomGuid = p.oldRecord['nom_guid']?.toString();
      final barcode = p.oldRecord['barcode']?.toString();
      if (nomGuid == null || barcode == null) return;
      await db.delete(
        table,
        where: 'nom_guid = ? AND barcode = ?',
        whereArgs: [nomGuid, barcode],
      );
      return;
    }

    final nomGuid = p.newRecord['nom_guid']?.toString() ?? '';
    final barcode = p.newRecord['barcode']?.toString() ?? '';
    if (nomGuid.isEmpty || barcode.isEmpty) return;
    await db.insert(table, {
      'nom_guid': nomGuid,
      'barcode': barcode,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> _applyPrices(PostgresChangePayload p) async {
    final db = await _openNomenclatureDb();
    final table = '${_schema}_prices';
    await _ensureNomenclatureTables(db);

    if (p.eventType == PostgresChangeEvent.delete) {
      final nomGuid = p.oldRecord['nom_guid']?.toString();
      if (nomGuid == null) return;
      await db.delete(table, where: 'nom_guid = ?', whereArgs: [nomGuid]);
      return;
    }

    final nomGuid = p.newRecord['nom_guid']?.toString() ?? '';
    if (nomGuid.isEmpty) return;
    final price = (p.newRecord['price'] as num?)?.toDouble() ?? 0.0;
    final createdAt =
        DateTime.tryParse(
          p.newRecord['created_at']?.toString() ?? '',
        )?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    await db.insert(table, {
      'nom_guid': nomGuid,
      'price': price,
      'createdAt': createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> _applyKontragenty(PostgresChangePayload p) async {
    final db = await _openKontragentyDb();
    final table = '${_schema}_kontragenty';
    await _ensureKontragentyTable(db);

    if (p.eventType == PostgresChangeEvent.delete) {
      final guid = p.oldRecord['guid']?.toString();
      if (guid == null) return;
      await db.delete(table, where: 'guid = ?', whereArgs: [guid]);
      return;
    }

    final r = p.newRecord;
    if (r.isEmpty) return;
    final data = <String, Object?>{
      'guid': r['guid']?.toString() ?? '',
      'name': r['name']?.toString() ?? '',
      'edrpou': r['edrpou']?.toString() ?? '',
      'is_folder':
          ((r['is_folder'] ?? 0) == 1 || (r['is_folder'] ?? false) == true)
          ? 1
          : 0,
      'parent_guid': r['parent_guid']?.toString() ?? '',
      'description': r['description']?.toString() ?? '',
      'created_at':
          r['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    };
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // region ensure tables
  static Future<void> _ensureNomenclatureTables(Database db) async {
    final nomenTable = '${_schema}_nomenclature';
    final barcodesTable = '${_schema}_barcodes';
    final pricesTable = '${_schema}_prices';
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $nomenTable (
        objectBoxId INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        guid TEXT NOT NULL,
        parentGuid TEXT NOT NULL DEFAULT '',
        isFolder INTEGER NOT NULL DEFAULT 0,
        description TEXT NOT NULL DEFAULT '',
        article TEXT NOT NULL,
        unitName TEXT NOT NULL,
        unitGuid TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $barcodesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_guid TEXT NOT NULL,
        barcode TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $pricesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_guid TEXT NOT NULL,
        price REAL NOT NULL,
        createdAt INTEGER
      )
    ''');
  }

  static Future<void> _ensureKontragentyTable(Database db) async {
    final table = '${_schema}_kontragenty';
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $table (
        objectBoxId INTEGER PRIMARY KEY AUTOINCREMENT,
        guid TEXT NOT NULL,
        name TEXT NOT NULL,
        edrpou TEXT,
        is_folder INTEGER NOT NULL DEFAULT 0,
        parent_guid TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
  }

  // endregion
}
