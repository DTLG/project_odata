import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/kontragent_model.dart';
import '../../../../../core/database/sqlite_helper.dart';
import '../../../../../core/config/supabase_config.dart';
import '../kontragent_local_data_source.dart';

/// Абстрактний інтерфейс для локального джерела даних контрагентів через SQLite
abstract class SqliteKontragentDatasource {
  Future<List<KontragentModel>> getAllKontragenty();
  Future<KontragentModel?> getKontragentByGuid(String guid);
  Future<List<KontragentModel>> searchKontragentyByName(String name);
  Future<List<KontragentModel>> searchKontragentyByEdrpou(String edrpou);
  Future<List<KontragentModel>>
  getRootFolders(); // Returns both folders and kontragenty with no parent
  Future<List<KontragentModel>> getChildren(String parentGuid);
  Future<void> insertKontragenty(List<KontragentModel> kontragenty);
  Future<void> clearAllKontragenty();
  Future<int> getKontragentyCount();
  Future<void> updateKontragent(KontragentModel kontragent);
  Future<void> deleteKontragent(String guid);
  Future<Map<String, dynamic>> debugDatabase();
  Future<void> recreateDatabase();
}

/// Реалізація локального джерела даних через SQLite
class SqliteKontragentDatasourceImpl
    implements SqliteKontragentDatasource, KontragentLocalDataSource {
  static Database? _database;

  String get _tableName {
    final tableName = SupabaseConfig.schema + '_kontragenty';
    print('🏷️ Назва таблиці: $tableName');
    return tableName;
  }

  Future<void> _ensureSchemaLoaded() async {
    await SupabaseConfig.loadFromPrefs();
    print('📋 Схема завантажена: ${SupabaseConfig.schema}');
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
      final path = join(dbPath, 'kontragenty.db');
      print('🗄️ Шлях до бази даних: $path');

      return await openDatabase(
        path,
        version: 3,
        onCreate: (db, version) async {
          print('🆕 Створюємо нову базу даних kontragenty версії $version');
          await _createTables(db, version);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          print(
            '🔄 Оновлюємо базу даних kontragenty з $oldVersion до $newVersion',
          );
          // v2: migrate to schema-prefixed tables; v3: force recreate
          if (oldVersion < 2) {
            await _migrateToSchemaPrefixedTables(db);
          }
          if (oldVersion < 3) {
            await _recreateAllTables(db);
          }
        },
        onOpen: (db) async {
          print('🔓 Відкриваємо базу даних kontragenty');
          // Оновлюємо схему на випадок зміни між відкриттями
          await _ensureSchemaLoaded();
          // Гарантуємо наявність основної таблиці
          await _ensureMainTable(db);
        },
      );
    } catch (e) {
      throw Exception('Помилка ініціалізації SQLite бази даних: $e');
    }
  }

  Future<void> _ensureMainTable(Database db) async {
    print('🔧 Створюємо таблицю: $_tableName');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${_tableName} (
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
    print('✅ Таблиця $_tableName створена/перевірена');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_guid ON ${_tableName}(guid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_name ON ${_tableName}(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_edrpou ON ${_tableName}(edrpou)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_parentGuid ON ${_tableName}(parent_guid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${SupabaseConfig.schema}_isFolder ON ${_tableName}(is_folder)',
    );
  }

  Future<void> _migrateToSchemaPrefixedTables(Database db) async {
    // Create new prefixed tables if not exist and copy data from old tables
    await _createTables(db, 2);
    // Copy main table
    final oldExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='kontragenty'",
    );
    if (oldExists.isNotEmpty) {
      await db.execute('''
        INSERT OR IGNORE INTO ${_tableName} (objectBoxId,guid,name,edrpou,is_folder,parent_guid,description,created_at)
        SELECT objectBoxId,guid,name,edrpou,is_folder,parent_guid,description,created_at FROM kontragenty
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
    await _createTables(db, 3);
  }

  Future<void> _createTables(Database db, int version) async {
    await _ensureMainTable(db);
  }

  Future<bool> _checkTableExists(Database db) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [_tableName],
      );
      final exists = result.isNotEmpty;
      print('🔍 Таблиця $_tableName існує: $exists');
      return exists;
    } catch (e) {
      print('❌ Помилка перевірки існування таблиці: $e');
      return false;
    }
  }

  @override
  Future<List<KontragentModel>> getAllKontragenty() async {
    try {
      await _ensureSchemaLoaded();
      print('🔍 Отримуємо всіх контрагентів з SQLite...');

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

      final models = maps.map((map) => _mapToModel(map)).toList();

      print('✅ Конвертовано ${models.length} записів з SQLite');

      return models;
    } catch (e) {
      print('❌ Помилка отримання з SQLite: $e');
      throw Exception('Помилка при отриманні контрагентів з локальної БД: $e');
    }
  }

  @override
  Future<KontragentModel?> getKontragentByGuid(String guid) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'guid = ?',
        whereArgs: [guid],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _mapToModel(maps.first);
    } catch (e) {
      throw Exception(
        'Помилка при пошуку контрагента за GUID в локальній БД: $e',
      );
    }
  }

  @override
  Future<List<KontragentModel>> searchKontragentyByName(String name) async {
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

      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      throw Exception(
        'Помилка при пошуку контрагентів за назвою в локальній БД: $e',
      );
    }
  }

  @override
  Future<List<KontragentModel>> searchKontragentyByEdrpou(String edrpou) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'edrpou LIKE ?',
        whereArgs: ['%$edrpou%'],
        orderBy: 'name',
        limit: 100,
      );

      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      throw Exception(
        'Помилка при пошуку контрагентів за ЄДРПОУ в локальній БД: $e',
      );
    }
  }

  @override
  Future<List<KontragentModel>> getRootFolders() async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;

      // Отримуємо папки верхнього рівня (is_folder = 1 AND parent_guid = '00000000-0000-0000-0000-000000000000')
      final List<Map<String, dynamic>> folderMaps = await db.query(
        _tableName,
        where: 'is_folder = ? AND parent_guid = ?',
        whereArgs: [1, '00000000-0000-0000-0000-000000000000'],
        orderBy: 'name',
      );

      // Отримуємо контрагентів верхнього рівня (is_folder = 0 AND parent_guid = '00000000-0000-0000-0000-000000000000')
      final List<Map<String, dynamic>> kontragentMaps = await db.query(
        _tableName,
        where: 'is_folder = ? AND parent_guid = ?',

        whereArgs: [0, ''],
        orderBy: 'name',
      );

      // Об'єднуємо результати: спочатку папки, потім контрагенти
      final List<Map<String, dynamic>> allMaps = [
        ...folderMaps,
        ...kontragentMaps,
      ];

      print('📁 Знайдено ${folderMaps.length} папок верхнього рівня');
      print(
        '👥 Знайдено ${kontragentMaps.length} контрагентів верхнього рівня',
      );
      print('📊 Всього елементів верхнього рівня: ${allMaps.length}');

      final models = allMaps.map((map) => _mapToModel(map)).toList();

      // Виводимо перші три елементи для діагностики
      print('🔍 Перші три елементи верхнього рівня:');
      for (int i = 0; i < models.length && i < 3; i++) {
        final model = models[i];
        print('  [${i + 1}] ${model.isFolder ? "📁" : "👤"} ${model.name}');
        print('      - GUID: ${model.guid}');
        print('      - isFolder: ${model.isFolder}');
        print('      - parentGuid: ${model.parentGuid}');
        if (!model.isFolder) {
          print('      - EDRPOU: ${model.edrpou}');
          print('      - Description: ${model.description}');
        }
      }

      return models;
    } catch (e) {
      throw Exception(
        'Помилка при отриманні кореневих елементів в локальній БД: $e',
      );
    }
  }

  @override
  Future<List<KontragentModel>> getChildren(String parentGuid) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'parent_guid = ?',
        whereArgs: [parentGuid],
        orderBy: 'name',
      );

      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      throw Exception(
        'Помилка при отриманні дочірніх елементів в локальній БД: $e',
      );
    }
  }

  @override
  Future<void> insertKontragenty(List<KontragentModel> kontragenty) async {
    try {
      await _ensureSchemaLoaded();
      print(
        '💾 Починаємо збереження ${kontragenty.length} записів в SQLite...',
      );

      final db = await database;

      // Ensure table exists before inserting
      await _ensureMainTable(db);

      // Verify table exists
      final tableExists = await _checkTableExists(db);
      if (!tableExists) {
        throw Exception('Таблиця $_tableName не існує після створення');
      }

      final batch = db.batch();

      for (int i = 0; i < kontragenty.length; i++) {
        final kontragent = kontragenty[i];
        final map = _modelToMap(kontragent);

        if (i < 3) {
          print('📝 Запис ${i + 1}: ${kontragent.name} (${kontragent.guid})');
        }

        batch.insert(
          _tableName,
          map,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      print('🚀 Виконуємо batch commit для ${kontragenty.length} записів...');
      await batch.commit(noResult: true);

      // Перевіряємо що записалося
      final count = await getKontragentyCount();
      print('✅ Збереження завершено. Записів: $count');
    } catch (e) {
      print('❌ Помилка збереження в SQLite: $e');
      throw Exception('Помилка при збереженні контрагентів в локальну БД: $e');
    }
  }

  @override
  Future<void> clearAllKontragenty() async {
    try {
      await _ensureSchemaLoaded();
      print('🗑️ Очищуємо всіх контрагентів з SQLite...');

      final db = await database;

      // Перевіряємо чи існує таблиця
      final tableExists = await _checkTableExists(db);
      if (!tableExists) {
        print('⚠️ Таблиця $_tableName не існує, немає що очищати');
        return;
      }

      // Отримуємо кількість записів до видалення
      final countBefore = await getKontragentyCount();
      print('📊 Записів до очищення: $countBefore');

      final deleted = await db.delete(_tableName);

      print('✅ Очищення завершено. Видалено записів: $deleted');

      // Перевіряємо кількість після видалення
      final countAfter = await getKontragentyCount();
      print('📊 Записів після очищення: $countAfter');
    } catch (e) {
      print('❌ Помилка очищення SQLite: $e');
      throw Exception('Помилка при очищенні контрагентів в локальній БД: $e');
    }
  }

  @override
  Future<void> clearAllData() async {
    return clearAllKontragenty();
  }

  @override
  Future<List<KontragentModel>> searchByName(String query) async {
    return searchKontragentyByName(query);
  }

  @override
  Future<List<KontragentModel>> searchByEdrpou(String query) async {
    return searchKontragentyByEdrpou(query);
  }

  @override
  Future<int> getKontragentyCount() async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;

      // Ensure table exists before counting
      await _ensureMainTable(db);

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${_tableName}',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Помилка при підрахунку контрагентів в локальній БД: $e');
    }
  }

  @override
  Future<void> updateKontragent(KontragentModel kontragent) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      await db.update(
        _tableName,
        _modelToMap(kontragent),
        where: 'guid = ?',
        whereArgs: [kontragent.guid],
      );
    } catch (e) {
      throw Exception('Помилка при оновленні контрагента в локальній БД: $e');
    }
  }

  @override
  Future<void> deleteKontragent(String guid) async {
    try {
      await _ensureSchemaLoaded();
      final db = await database;
      await db.delete(_tableName, where: 'guid = ?', whereArgs: [guid]);
    } catch (e) {
      throw Exception('Помилка при видаленні контрагента з локальної БД: $e');
    }
  }

  /// Конвертація Map в KontragentModel
  KontragentModel _mapToModel(Map<String, dynamic> map) {
    return KontragentModel(
      guid: map['guid'] ?? '',
      name: map['name'] ?? '',
      edrpou: map['edrpou'] ?? '',
      isFolder: (map['is_folder'] ?? 0) == 1,
      parentGuid: map['parent_guid'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Конвертація KontragentModel в Map
  Map<String, dynamic> _modelToMap(KontragentModel model) {
    return {
      'guid': model.guid,
      'name': model.name,
      'edrpou': model.edrpou,
      'is_folder': model.isFolder ? 1 : 0,
      'parent_guid': model.parentGuid,
      'description': model.description,
      'created_at': model.createdAt.toIso8601String(),
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
      final path = join(dbPath, 'kontragenty.db');
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
