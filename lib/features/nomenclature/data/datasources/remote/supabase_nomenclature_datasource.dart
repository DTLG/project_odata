import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nomenclature_model.dart';
import '../../../../../core/config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../local/objectbox_nomenclature_datasource.dart';

/// Абстрактний інтерфейс для віддаленого джерела даних номенклатури
abstract class SupabaseNomenclatureDatasource {
  Future<List<NomenclatureModel>> getAllNomenclature();
  Future<List<NomenclatureModel>> getAllNomenclatureWithProgress({
    Function(String message, int current, int total)? onProgress,
  });
  Future<List<NomenclatureModel>> getAllNomenclatureWithLimit(int limit);
  Future<NomenclatureModel?> getNomenclatureByGuid(String guid);
  Future<List<NomenclatureModel>> searchNomenclatureByName(String name);
  Future<Map<String, dynamic>> testConnection();
  Future<void> syncNomenclatureWithProgress({
    required ObjectboxNomenclatureDatasource local,
    Function(String message, int current, int total)? onProgress,
  });
}

/// Реалізація віддаленого джерела даних через Supabase
class SupabaseNomenclatureDatasourceImpl
    implements SupabaseNomenclatureDatasource {
  final SupabaseClient _supabaseClient;

  // Використовуємо клієнт, прив'язаний до потрібної схеми
  SupabaseQuerySchema get _schemaClient =>
      _supabaseClient.schema(SupabaseConfig.schema);

  // Звичайні назви таблиць (без префіксів); схема визначається клієнтом
  String get _tableName => 'nomenklatura';
  String get _barcodesTable => 'barcodes';
  String get _pricesTable => 'prices';

  SupabaseNomenclatureDatasourceImpl(this._supabaseClient);

  Future<Map<String, List<T>>> _fetchByGuids<T>({
    required String table,
    required List<String> guids,
    required T Function(Map<String, dynamic>) mapper,
  }) async {
    final map = <String, List<T>>{};
    if (guids.isEmpty) return map;

    const int chunkSize = 200;
    for (var i = 0; i < guids.length; i += chunkSize) {
      final chunk = guids.skip(i).take(chunkSize).toList();

      final rows = await _schemaClient
          .from(table)
          .select()
          .inFilter('nom_guid', chunk);

      for (final row in rows) {
        final guid = row['nom_guid']?.toString() ?? '';
        if (guid.isEmpty) continue;
        final item = mapper(row);
        (map[guid] ??= []).add(item);
      }
    }
    return map;
  }

  static const String _baseSelect =
      'created_at, name, guid, parent_guid, is_folder,article, unit_name, unit_guid, description';

  @override
  Future<List<NomenclatureModel>> getAllNomenclature() async {
    try {
      final allRecords = <Map<String, dynamic>>[];
      const int pageSize = 1000;
      int lastId = 0;
      int page = 1;

      while (true) {
        final response = await _schemaClient
            .from(_tableName)
            .select(_baseSelect)
            .gt('id', lastId)
            .order('id', ascending: true)
            .limit(pageSize);

        if (response.isEmpty) break;

        for (final row in response) {
          final idValue = row['id'];
          if (idValue is int) {
            lastId = idValue;
          } else if (idValue is num) {
            lastId = idValue.toInt();
          }
          allRecords.add(row);
        }

        if (response.length < pageSize) break; // останній пакет
        page += 1;
        if (page % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      if (allRecords.isEmpty) {
        return [];
      }

      final guids = allRecords
          .map((e) => e['guid']?.toString() ?? '')
          .where((g) => g.isNotEmpty)
          .toList();
      final barcodesMap = await _fetchByGuids<BarcodeModel>(
        table: _barcodesTable,
        guids: guids,
        mapper: (row) =>
            BarcodeModel(nomGuid: row['nom_guid']!, barcode: row['barcode']!),
      );

      final pricesMap = await _fetchByGuids<PriceModel>(
        table: _pricesTable,
        guids: guids,
        mapper: (row) => PriceModel(
          nomGuid: row['nom_guid']!,
          price: (row['price'] as num).toDouble(),
        ),
      );

      final models = allRecords.map<NomenclatureModel>((json) {
        final model = NomenclatureModel.fromJson(json);
        model.barcodes = barcodesMap[model.guid] ?? const <BarcodeModel>[];
        model.prices = pricesMap[model.guid] ?? const <PriceModel>[];
        return model;
      }).toList();

      return models;
    } catch (e) {
      throw Exception('Помилка при отриманні номенклатури з Supabase: $e');
    }
  }

  @override
  Future<void> syncNomenclatureWithProgress({
    required ObjectboxNomenclatureDatasource local,
    Function(String message, int current, int total)? onProgress,
  }) async {
    try {
      // Отримуємо загальну кількість записів

      final response = await _schemaClient
          .from(_tableName) // Replace with your table name
          .select(
            '*', // Select all columns (or specific columns if desired)
          )
          .count(CountOption.exact);
      // .select('*',  head: true, count: CountOption.exact);

      final totalCount = response.count; // тут буде кількість рядків

      const int pageSize = 1000;
      int lastId = 0;
      int page = 1;
      int totalLoaded = 0;

      onProgress?.call('Початок завантаження...', 0, totalCount);

      // Буферизація моделей для зменшення кількості записів у БД
      const int bufferTargetSize = 5000; // 5k-10k оптимально; почнемо з 5k
      final List<NomenclatureModel> buffer = <NomenclatureModel>[];

      Future<void> flushBuffer() async {
        if (buffer.isEmpty) return;
        await local.insertNomenclature(List<NomenclatureModel>.from(buffer));

        buffer.clear();
      }

      while (true) {
        // onProgress?.call(
        //   'Завантаження пакету $page (id > $lastId)...',
        //   totalLoaded,
        //   totalCount,
        // );

        final response = await _schemaClient
            .from('nomenklatura_with_data')
            .select()
            .gt('id', lastId)
            .order('id', ascending: true)
            .limit(pageSize);

        if (response.isEmpty) {
          break;
        }

        for (final row in response) {
          final idValue = row['id'];
          if (idValue is int) {
            lastId = idValue;
          } else if (idValue is num) {
            lastId = idValue.toInt();
          }
        }

        final models = response
            .map((json) => NomenclatureModel.fromJson(json))
            .toList();

        buffer.addAll(models);
        if (buffer.length >= bufferTargetSize) {
          await flushBuffer();
        }

        totalLoaded += models.length;

        onProgress?.call(
          'Завантажено $totalLoaded товарів...',
          totalLoaded,
          totalCount,
        );

        if (response.length < pageSize) {
          break; // останній пакет
        }
        page++;
      }

      // фінальний флеш
      await flushBuffer();

      onProgress?.call('Завершено!', totalLoaded, totalLoaded);
    } catch (e) {
      throw Exception('Помилка при синхронізації номенклатури: $e');
    }
  }

  @override
  Future<List<NomenclatureModel>> getAllNomenclatureWithProgress({
    Function(String message, int current, int total)? onProgress,
  }) async {
    try {
      final allRecords = <Map<String, dynamic>>[];
      const int pageSize = 1000;
      int lastId = 0; // курсор по колонці id
      int page = 1;
      int totalCount = 46000; // Очікуване значення

      onProgress?.call('Початок завантаження...', 0, totalCount);

      while (true) {
        onProgress?.call(
          'Завантаження пакету $page (id > $lastId)...',
          allRecords.length,
          totalCount,
        );

        final response = await _schemaClient
            .from(_tableName)
            .select('*')
            .gt('id', lastId)
            .order('id', ascending: true)
            .limit(pageSize);

        if (response.isEmpty) break;
        allRecords.addAll(response);

        for (final row in response) {
          final idValue = row['id'];
          if (idValue is int) {
            lastId = idValue;
          } else if (idValue is num) {
            lastId = idValue.toInt();
          }
          allRecords.add(row);
        }

        if (response.length == pageSize &&
            totalCount < allRecords.length + 1000) {
          totalCount = allRecords.length + 5000;
        }

        onProgress?.call(
          'Завантажено ${allRecords.length} записів (lastId=$lastId)...',
          allRecords.length,
          totalCount,
        );

        if (response.length < pageSize) break; // останній пакет
        page += 1;
        print(
          'Nomenclature: page: $page lastId: $lastId response.length: ${response.length}',
        );

        if (page % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      onProgress?.call(
        'Конвертація даних...',
        allRecords.length,
        allRecords.length,
      );

      final guids = allRecords
          .map((e) => e['guid']?.toString() ?? '')
          .where((g) => g.isNotEmpty)
          .toList();
      final barcodesMap = await _fetchByGuids<BarcodeModel>(
        table: _barcodesTable,
        guids: guids,
        mapper: (row) =>
            BarcodeModel(nomGuid: row['nom_guid']!, barcode: row['barcode']!),
      );
      final pricesMap = await _fetchByGuids<PriceModel>(
        table: _pricesTable,
        guids: guids,
        mapper: (row) => PriceModel(
          nomGuid: row['nom_guid']!,
          price: (row['price'] as num).toDouble(),
        ),
      );

      // Запускаємо конвертацію в фоновому режимі
      //todo протестувати
      final models = await _convertInBackground(
        allRecords,
        barcodesMap,
        pricesMap,
      );

      // final models = allRecords.map<NomenclatureModel>((json) {
      //   final model = NomenclatureModel.fromJson(json);
      //   model.barcodes = barcodesMap[model.guid] ?? const <BarcodeModel>[];
      //   model.prices = pricesMap[model.guid] ?? const <PriceModel>[];
      //   return model;
      // }).toList();

      onProgress?.call('Завершено!', models.length, models.length);

      return models;
    } catch (e) {
      throw Exception('Помилка при отриманні номенклатури з прогресом: $e');
    }
  }

  Future<List<NomenclatureModel>> _convertInBackground(
    List<Map<String, dynamic>> allRecords,
    Map<String, List<BarcodeModel>> barcodesMap,
    Map<String, List<PriceModel>> pricesMap,
  ) async {
    return compute((params) {
      final records = params[0] as List<Map<String, dynamic>>;
      final barcodes = params[1] as Map<String, List<BarcodeModel>>;
      final prices = params[2] as Map<String, List<PriceModel>>;

      return records.map<NomenclatureModel>((json) {
        final model = NomenclatureModel.fromJson(json);
        model.barcodes = barcodes[model.guid] ?? const <BarcodeModel>[];
        model.prices = prices[model.guid] ?? const <PriceModel>[];
        return model;
      }).toList();
    }, [allRecords, barcodesMap, pricesMap]);
  }

  @override
  Future<List<NomenclatureModel>> getAllNomenclatureWithLimit(int limit) async {
    try {
      final response = await _schemaClient
          .from(_tableName)
          .select(_baseSelect)
          .order('name')
          .limit(limit);

      if (response.isEmpty) {
        return [];
      }

      final guids = response
          .map((e) => e['guid']?.toString() ?? '')
          .where((g) => g.isNotEmpty)
          .toList();
      final barcodesMap = await _fetchByGuids<BarcodeModel>(
        table: _barcodesTable,
        guids: guids,
        mapper: (row) =>
            BarcodeModel(nomGuid: row['nom_guid']!, barcode: row['barcode']!),
      );
      final pricesMap = await _fetchByGuids<PriceModel>(
        table: _pricesTable,
        guids: guids,
        mapper: (row) => PriceModel(
          nomGuid: row['nom_guid']!,
          price: (row['price'] as num).toDouble(),
        ),
      );

      final models = <NomenclatureModel>[];
      for (int i = 0; i < response.length; i++) {
        try {
          final json = response[i];
          final model = NomenclatureModel.fromJson(json);
          model.barcodes = barcodesMap[model.guid] ?? const <BarcodeModel>[];
          model.prices = pricesMap[model.guid] ?? const <PriceModel>[];
          models.add(model);
        } catch (e) {
          // continue
        }
      }

      return models;
    } catch (e) {
      throw Exception('Помилка при отриманні номенклатури з лімітом: $e');
    }
  }

  @override
  Future<NomenclatureModel?> getNomenclatureByGuid(String guid) async {
    try {
      final response = await _schemaClient
          .from(_tableName)
          .select(_baseSelect)
          .eq('guid', guid)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return NomenclatureModel.fromJson(response);
    } catch (e) {
      throw Exception('Помилка при пошуку номенклатури за GUID: $e');
    }
  }

  @override
  Future<List<NomenclatureModel>> searchNomenclatureByName(String name) async {
    try {
      final response = await _schemaClient
          .from(_tableName)
          .select(_baseSelect)
          .ilike('name', '%$name%')
          .order('name')
          .limit(50);

      if (response.isEmpty) {
        return [];
      }

      final guids = response
          .map((e) => e['guid']?.toString() ?? '')
          .where((g) => g.isNotEmpty)
          .toList();
      final barcodesMap = await _fetchByGuids<BarcodeModel>(
        table: _barcodesTable,
        guids: guids,
        mapper: (row) =>
            BarcodeModel(nomGuid: row['nom_guid']!, barcode: row['barcode']!),
      );
      final pricesMap = await _fetchByGuids<PriceModel>(
        table: _pricesTable,
        guids: guids,
        mapper: (row) => PriceModel(
          nomGuid: row['nom_guid']!,
          price: (row['price'] as num).toDouble(),
        ),
      );

      return response.map<NomenclatureModel>((json) {
        final model = NomenclatureModel.fromJson(json);
        model.barcodes = barcodesMap[model.guid] ?? const <BarcodeModel>[];
        model.prices = pricesMap[model.guid] ?? const <PriceModel>[];
        return model;
      }).toList();
    } catch (e) {
      throw Exception('Помилка при пошуку номенклатури за назвою: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> testConnection() async {
    try {
      // Отримаємо кілька записів для тесту
      final testRecords = await _schemaClient
          .from(_tableName)
          .select(_baseSelect)
          .limit(5);

      final result = {
        'status': 'success',
        'table_exists': true,
        'table_name': _tableName,
        'test_records_count': testRecords.length,
        'sample_record': testRecords.isNotEmpty ? testRecords.first : null,
        'all_fields': testRecords.isNotEmpty
            ? testRecords.first.keys.toList()
            : [],
        'connection_time': DateTime.now().toIso8601String(),
      };

      return result;
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'table_name': _tableName,
        'connection_time': DateTime.now().toIso8601String(),
      };
    }
  }
}
