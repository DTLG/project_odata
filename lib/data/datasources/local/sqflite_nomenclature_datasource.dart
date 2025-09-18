import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/nomenclature_model.dart';
import '../../../core/database/sqlite_helper.dart';
import '../../../core/config/supabase_config.dart';
import 'nomenclature_local_datasource.dart';

class SqliteNomenclatureDatasourceImpl implements NomenclatureLocalDatasource {
  static Database? _database;

  String get _tableName => SupabaseConfig.schema + '_nomenclature';
  String get _barcodesTable => SupabaseConfig.schema + '_barcodes';
  String get _pricesTable => SupabaseConfig.schema + '_prices';

  Future<void> _ensureSchemaLoaded() async {
    await SupabaseConfig.loadFromPrefs();
  }

  /// Ініціалізація бази даних
  Future<Database> get database async {
    if (_database != null) return _database!;
    await _ensureSchemaLoaded();
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Переконуємося що SQLite ініціалізований
      if (!SqliteHelper.isInitialized) {
        await SqliteHelper.initialize();
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'nomenclature.db');

      return await openDatabase(
        path,
        version: 5,
        onCreate: _createTables,
        onUpgrade: (db, oldVersion, newVersion) async {
          // v2: add barcodes/prices; v3: migrate to schema-prefixed tables; v4: force recreate
          if (oldVersion < 2) {
            await _ensureAuxTables(db);
          }
          if (oldVersion < 3) {
            await _migrateToSchemaPrefixedTables(db);
          }
          if (oldVersion < 4) {
            await _recreateAllTables(db);
          }
          if (oldVersion < 5) {
            // Ensure new columns parentGuid, isFolder, description exist
            await _recreateAllTables(db);
          }
        },
        onOpen: (db) async {
          // Оновлюємо схему на випадок зміни між відкриттями
          await _ensureSchemaLoaded();
          // Гарантуємо наявність основної таблиці та допоміжних
          await _ensureMainTable(db);
          await _ensureAuxTables(db);
        },
      );
    } catch (e) {
      throw Exception('Помилка ініціалізації SQLite бази даних: $e');
    }
  }

  Future<void> _ensureMainTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${_tableName} (
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
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_guid ON ${_tableName}(guid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_article ON ${_tableName}(article)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_name ON ${_tableName}(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_parentGuid ON ${_tableName}(parentGuid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_isFolder ON ${_tableName}(isFolder)',
    );
  }

  Future<void> _migrateToSchemaPrefixedTables(Database db) async {
    // Create new prefixed tables if not exist and copy data from old tables
    await _createTables(db, 3);
    // Copy main table
    final oldExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='nomenclature'",
    );
    if (oldExists.isNotEmpty) {
      await db.execute('''
        INSERT OR IGNORE INTO ${_tableName} (objectBoxId,id,createdAt,name,price,guid,article,unitName,unitGuid)
        SELECT objectBoxId,id,createdAt,name,price,guid,article,unitName,unitGuid FROM nomenclature
      ''');
    }
    // Copy barcodes
    final oldBarExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='barcodes'",
    );
    if (oldBarExists.isNotEmpty) {
      await db.execute('''
        INSERT OR IGNORE INTO ${_barcodesTable} (id,nom_guid,barcode)
        SELECT id,nom_guid,barcode FROM barcodes
      ''');
    }
    // Copy prices
    final oldPriceExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='prices'",
    );
    if (oldPriceExists.isNotEmpty) {
      await db.execute('''
        INSERT OR IGNORE INTO ${_pricesTable} (id,nom_guid,price,createdAt)
        SELECT id,nom_guid,price,createdAt FROM prices
      ''');
    }
  }

  Future<void> _recreateAllTables(Database db) async {
    // Drop all old tables (both prefixed and non-prefixed)
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );

    for (final table in tables) {
      final tableName = table['name'] as String;
      await db.execute('DROP TABLE IF EXISTS $tableName');
    }

    // Recreate all tables with correct schema
    await _createTables(db, 4);
  }

  Future<void> _ensureAuxTables(Database db) async {
    // Створюємо, якщо відсутні, таблиці barcodes та prices і індекси
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${_barcodesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_guid TEXT NOT NULL,
        barcode TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_barcodes_nom_guid ON ${_barcodesTable}(nom_guid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_barcodes_barcode ON ${_barcodesTable}(barcode)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${_pricesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_guid TEXT NOT NULL,
        price REAL NOT NULL,
        createdAt INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_prices_nom_guid ON ${_pricesTable}(nom_guid)',
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await _ensureMainTable(db);

    // Таблиця штрихкодів
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${_barcodesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_guid TEXT NOT NULL,
        barcode TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_barcodes_nom_guid ON ${_barcodesTable}(nom_guid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_barcodes_barcode ON ${_barcodesTable}(barcode)',
    );

    // Таблиця цін
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${_pricesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_guid TEXT NOT NULL,
        price REAL NOT NULL,
        createdAt INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_prices_nom_guid ON ${_pricesTable}(nom_guid)',
    );
  }

  Future<List<NomenclatureModel>> _attachRelationsToModels(
    Database db,
    List<NomenclatureModel> models,
  ) async {
    if (models.isEmpty) return models;

    final guids = models.map((m) => m.guid).toSet().toList();

    // Завантажимо баркоди і ціни тільки для потрібних GUID-ів
    final barcodesRows = await db.query(
      _barcodesTable,
      where: 'nom_guid IN (${List.filled(guids.length, '?').join(',')})',
      whereArgs: guids,
    );
    final pricesRows = await db.query(
      _pricesTable,
      where: 'nom_guid IN (${List.filled(guids.length, '?').join(',')})',
      whereArgs: guids,
    );

    final Map<String, List<BarcodeModel>> guidToBarcodes = {};
    for (final row in barcodesRows) {
      final guid = row['nom_guid'] as String;
      final code = row['barcode'] as String;
      (guidToBarcodes[guid] ??= <BarcodeModel>[]).add(
        BarcodeModel(nomGuid: guid, barcode: code),
      );
    }

    final Map<String, List<PriceModel>> guidToPrices = {};
    for (final row in pricesRows) {
      final guid = row['nom_guid'] as String;
      final price = (row['price'] as num).toDouble();
      (guidToPrices[guid] ??= <PriceModel>[]).add(
        PriceModel(nomGuid: guid, price: price),
      );
    }

    for (final m in models) {
      m.barcodes = guidToBarcodes[m.guid] ?? <BarcodeModel>[];
      m.prices = guidToPrices[m.guid] ?? <PriceModel>[];
    }
    return models;
  }

  @override
  Future<List<NomenclatureModel>> getAllNomenclature() async {
    try {
      await _ensureSchemaLoaded();
      print('🔍 Отримуємо всю номенклатуру з SQLite...');

      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);

      print('📊 SQLite запит завершено:');
      print('   - Отримано записів: ${maps.length}');

      if (maps.isNotEmpty) {
        print(
          '   - Перший запис: ${maps.first['name']} (${maps.first['guid']})',
        );
        if (maps.length > 1) {
          print('   - Другий запис: ${maps[1]['name']} (${maps[1]['guid']})');
        }
        if (maps.length > 2) {
          print('   - Третій запис: ${maps[2]['name']} (${maps[2]['guid']})');
        }
      }

      // Переконуємося, що потрібні таблиці існують
      await _ensureAuxTables(db);

      // Підтягуємо штрихкоди і ціни одним проходом
      // Витягуємо всі рядки з barcodes/prices (без ліміту)
      final barcodesRows = await db.query(_barcodesTable);
      final pricesRows = await db.query(_pricesTable);

      // Діагностика вмісту допоміжних таблиць
      print('🔎 SQLite barcodes rows: ${barcodesRows.length}');
      if (barcodesRows.isNotEmpty) {
        print('   • Приклад barcodes[0]: ${barcodesRows.first}');
      }
      print('🔎 SQLite prices rows: ${pricesRows.length}');
      if (pricesRows.isNotEmpty) {
        print('   • Приклад prices[0]: ${pricesRows.first}');
      }

      final Map<String, List<BarcodeModel>> guidToBarcodes = {};
      for (final row in barcodesRows) {
        final guid = row['nom_guid'] as String;
        final code = row['barcode'] as String;
        (guidToBarcodes[guid] ??= <BarcodeModel>[]).add(
          BarcodeModel(nomGuid: guid, barcode: code),
        );
      }

      final Map<String, List<PriceModel>> guidToPrices = {};
      for (final row in pricesRows) {
        final guid = row['nom_guid'] as String;
        final price = (row['price'] as num).toDouble();
        (guidToPrices[guid] ??= <PriceModel>[]).add(
          PriceModel(nomGuid: guid, price: price),
        );
      }

      print(
        '🧩 Побудовано мап: barcodes для ${guidToBarcodes.length} GUIDів, prices для ${guidToPrices.length} GUIDів',
      );

      final models = maps.map((map) {
        final model = _mapToModel(map);
        model.barcodes = guidToBarcodes[model.guid] ?? <BarcodeModel>[];
        model.prices = guidToPrices[model.guid] ?? <PriceModel>[];
        return model;
      }).toList();

      // Друкуємо перші кілька елементів з їх ШК і цінами
      for (int i = 0; i < models.length && i < 3; i++) {
        final m = models[i];
        print('📦 [${i + 1}] ${m.name} (${m.guid})');
        print(
          '   - ШК (${m.barcodes.length}): ${m.barcodes.map((e) => e.barcode).join(', ')}',
        );
        print(
          '   - Ціни (${m.prices.length}): ${m.prices.map((e) => e.price).join(', ')}',
        );
      }
      print('✅ Конвертовано ${models.length} записів з SQLite');

      return models;
    } catch (e) {
      print('❌ Помилка отримання з SQLite: $e');
      throw Exception('Помилка при отриманні номенклатури з локальної БД: $e');
    }
  }

  @override
  Future<NomenclatureModel?> getNomenclatureByGuid(String guid) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'guid = ?',
        whereArgs: [guid],
      );

      if (maps.isEmpty) return null;
      final model = _mapToModel(maps.first);
      final hydrated = await _attachRelationsToModels(db, [model]);
      return hydrated.first;
    } catch (e) {
      throw Exception(
        'Помилка при пошуку номенклатури за GUID в локальній БД: $e',
      );
    }
  }

  @override
  Future<List<NomenclatureModel>> getNomenclatureByArticle(
    String article,
  ) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'article LIKE ?',
        whereArgs: ['$article%'],
      );

      if (maps.isEmpty) return [];

      final models = maps.map(_mapToModel).toList();
      final hydrated = await _attachRelationsToModels(db, models);
      return hydrated;
    } catch (e) {
      throw Exception(
        'Помилка при пошуку номенклатури за артикулом в локальній БД: $e',
      );
    }
  }

  Future<List<NomenclatureModel>> searchNomenclatureByArticleLike(
    String article, {
    int limit = 100,
  }) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'article LIKE ?',
        whereArgs: ['%$article%'],
        orderBy: 'name ASC',
        limit: limit,
      );
      if (maps.isEmpty) return const [];
      final models = maps.map((e) => _mapToModel(e)).toList();
      final hydrated = await _attachRelationsToModels(db, models);
      return hydrated;
    } catch (e) {
      throw Exception(
        'Помилка при пошуку номенклатури за артикулом (LIKE) в локальній БД: $e',
      );
    }
  }

  @override
  Future<NomenclatureModel?> getNomenclatureByBarcode(String barcode) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      // Знайдемо GUID по штрихкоду
      final rows = await db.query(
        _barcodesTable,
        columns: ['nom_guid'],
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
      if (rows.isEmpty) return null;
      final guid = rows.first['nom_guid'] as String;
      // Повертаємо відповідну номенклатуру
      return await getNomenclatureByGuid(guid);
    } catch (e) {
      throw Exception(
        'Помилка при пошуку номенклатури за штрихкодом в локальній БД: $e',
      );
    }
  }

  @override
  Future<List<NomenclatureModel>> searchNomenclatureByName(String name) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'name LIKE ?',
        whereArgs: ['%$name%'],
        orderBy: 'name',
        limit: 100,
      );

      final models = maps.map((map) => _mapToModel(map)).toList();
      await _attachRelationsToModels(db, models);
      return models;
    } catch (e) {
      throw Exception(
        'Помилка при пошуку номенклатури за назвою в локальній БД: $e',
      );
    }
  }

  @override
  Future<void> insertNomenclature(List<NomenclatureModel> nomenclatures) async {
    try {
      await _ensureSchemaLoaded();
      print(
        '💾 Починаємо збереження ${nomenclatures.length} записів в SQLite...',
      );

      final db = await database;
      final batch = db.batch();

      // Переконуємося, що допоміжні таблиці існують (на випадок міграції)
      await _ensureAuxTables(db);

      for (int i = 0; i < nomenclatures.length; i++) {
        final nomenclature = nomenclatures[i];
        final map = _modelToMap(nomenclature);

        if (i < 3) {
          print(
            '📝 Запис ${i + 1}: ${nomenclature.name} (${nomenclature.guid})',
          );
        }

        batch.insert(
          _tableName,
          map,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        // Вставляємо штрихкоди
        for (final code in nomenclature.barcodes) {
          batch.insert(_barcodesTable, {
            'nom_guid': nomenclature.guid,
            'barcode': code.barcode,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        // Вставляємо ціни
        for (final price in nomenclature.prices) {
          batch.insert(_pricesTable, {
            'nom_guid': nomenclature.guid,
            'price': price.price,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      print('🚀 Виконуємо batch commit для ${nomenclatures.length} записів...');
      await batch.commit(noResult: true);

      // Перевіряємо що записалося
      final count = await getNomenclatureCount();
      final barcodesCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) as c FROM ${_barcodesTable}'),
          ) ??
          0;
      final pricesCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) as c FROM ${_pricesTable}'),
          ) ??
          0;
      print(
        '✅ Збереження завершено. Записів: nomenclature=$count, barcodes=$barcodesCount, prices=$pricesCount',
      );
    } catch (e) {
      print('❌ Помилка збереження в SQLite: $e');
      throw Exception('Помилка при збереженні номенклатури в локальну БД: $e');
    }
  }

  @override
  Future<void> clearAllNomenclature() async {
    try {
      await _ensureSchemaLoaded();
      print('🗑️ Очищуємо всю номенклатуру з SQLite...');

      final db = await database;
      final deletedMain = await db.delete(_tableName);
      // Переконуємося, що допоміжні таблиці існують перед очисткою
      await _ensureAuxTables(db);
      final deletedBarcodes = await db.delete(_barcodesTable);
      final deletedPrices = await db.delete(_pricesTable);

      print(
        '✅ Очищення завершено. Видалено записів: main=$deletedMain, barcodes=$deletedBarcodes, prices=$deletedPrices',
      );
    } catch (e) {
      print('❌ Помилка очищення SQLite: $e');
      throw Exception('Помилка при очищенні номенклатури в локальній БД: $e');
    }
  }

  @override
  Future<int> getNomenclatureCount() async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${_tableName}',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Помилка при підрахунку номенклатури в локальній БД: $e');
    }
  }

  @override
  Future<void> updateNomenclature(NomenclatureModel nomenclature) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      await db.update(
        _tableName,
        _modelToMap(nomenclature),
        where: 'guid = ?',
        whereArgs: [nomenclature.guid],
      );
    } catch (e) {
      throw Exception('Помилка при оновленні номенклатури в локальній БД: $e');
    }
  }

  @override
  Future<void> deleteNomenclature(String guid) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      await db.delete(_tableName, where: 'guid = ?', whereArgs: [guid]);
    } catch (e) {
      throw Exception('Помилка при видаленні номенклатури з локальної БД: $e');
    }
  }

  /// Конвертація Map в NomenclatureModel
  NomenclatureModel _mapToModel(Map<String, dynamic> map) {
    return NomenclatureModel(
      objectBoxId: map['objectBoxId'] ?? 0,
      id: map['id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      name: map['name'],
      nameLower: map['name'].toString().toLowerCase(),
      price: map['price'],
      guid: map['guid'],
      parentGuid: map['parentGuid'] ?? '',
      isFolder: (map['isFolder'] ?? 0) == 1,
      description: map['description'] ?? '',
      article: map['article'],
      unitName: map['unitName'],
      unitGuid: map['unitGuid'],
    );
  }

  /// Конвертація NomenclatureModel в Map
  Map<String, dynamic> _modelToMap(NomenclatureModel model) {
    return {
      'id': model.id,
      'createdAt': model.createdAt.millisecondsSinceEpoch,
      'name': model.name,
      'nameLower': model.nameLower,
      'price': model.price,
      'guid': model.guid,
      'parentGuid': model.parentGuid,
      'isFolder': model.isFolder ? 1 : 0,
      'description': model.description,
      'article': model.article,
      'unitName': model.unitName,
      'unitGuid': model.unitGuid,
    };
  }

  @override
  Future<Map<String, dynamic>> debugDatabase() async {
    try {
      print('🔍 Діагностика SQLite бази даних...');

      final db = await database;

      // Отримуємо загальну кількість
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${_tableName}',
      );
      final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

      // Отримуємо перші 5 записів (raw SQL)
      final rawRecords = await db.rawQuery(
        'SELECT * FROM ${_tableName} LIMIT 5',
      );

      // Перевіряємо структуру таблиці
      final tableInfo = await db.rawQuery('PRAGMA table_info(${_tableName})');

      final result = {
        'total_count': totalCount,
        'table_structure': tableInfo,
        'sample_records_raw': rawRecords,
        'table_name': _tableName,
        'debug_time': DateTime.now().toIso8601String(),
      };

      print('📊 Діагностика SQLite:');
      print('   - Всього записів: $totalCount');
      print(
        '   - Структура таблиці: ${tableInfo.map((col) => col['name']).toList()}',
      );
      print('   - Перші записи: ${rawRecords.take(2).toList()}');

      return result;
    } catch (e) {
      print('❌ Помилка діагностики SQLite: $e');
      return {
        'error': e.toString(),
        'debug_time': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Future<void> recreateDatabase() async {
    try {
      print('🔄 Перестворюємо SQLite базу даних...');

      // Закриваємо поточну базу
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Видаляємо файл бази
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'nomenclature.db');
      await deleteDatabase(path);

      print('✅ Стара база видалена. Створюємо нову...');

      // Створюємо нову базу (це автоматично викличе _createTables)
      _database = await _initDatabase();

      print('✅ Нова база створена успішно');
    } catch (e) {
      print('❌ Помилка перестворення бази: $e');
      throw Exception('Помилка перестворення SQLite бази: $e');
    }
  }
}
