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
          allRecords.add(row as Map<String, dynamic>);
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
      print('Starting nomenclature sync...');
      const int pageSize = 1000;
      int lastId = 0;
      int page = 1;
      int totalLoaded = 0;
      int estimatedTotal = 46000;

      print(
        'Initial parameters: pageSize=$pageSize, lastId=$lastId, page=$page',
      );
      onProgress?.call('Початок завантаження...', 0, estimatedTotal);

      while (true) {
        print('Starting page $page (lastId > $lastId)');
        onProgress?.call(
          'Завантаження пакету $page (id > $lastId)...',
          totalLoaded,
          estimatedTotal,
        );

        print('Fetching data from Supabase...');
        final response = await _schemaClient
            .from(_tableName)
            .select(_baseSelect)
            .gt('id', lastId)
            .order('id', ascending: true)
            .limit(pageSize);

        if (response.isEmpty) {
          print('No more records found, breaking loop');
          break;
        }

        print('Processing ${response.length} records from response');
        // оновлюємо lastId
        for (final row in response) {
          final idValue = row['id'];
          if (idValue is int) {
            lastId = idValue;
          } else if (idValue is num) {
            lastId = idValue.toInt();
          }
        }
        print('Updated lastId to $lastId');

        // збираємо guids для цього пакету
        final guids = response
            .map((e) => e['guid']?.toString() ?? '')
            .where((g) => g.isNotEmpty)
            .toList();
        print('Collected ${guids.length} GUIDs for processing');

        // вантажимо штрихкоди + ціни тільки для цього пакету
        print('Fetching barcodes and prices...');
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
        print(
          'Fetched ${barcodesMap.length} barcodes and ${pricesMap.length} prices',
        );

        // конвертація в ізоляті
        print('Starting compute isolation for model conversion...');
        final models = await compute((params) {
          final data = params[0] as List<Map<String, dynamic>>;
          final barcodes = params[1] as Map<String, List<BarcodeModel>>;
          final prices = params[2] as Map<String, List<PriceModel>>;

          return data.map<NomenclatureModel>((json) {
            final model = NomenclatureModel.fromJson(json);
            model.barcodes = barcodes[model.guid] ?? const <BarcodeModel>[];
            model.prices = prices[model.guid] ?? const <PriceModel>[];
            return model;
          }).toList();
        }, [response.cast<Map<String, dynamic>>(), barcodesMap, pricesMap]);
        print('Converted ${models.length} models in compute isolation');

        // збереження у ObjectBox (через local datasource)
        print('Saving models to ObjectBox...');
        await local.insertNomenclature(models);
        print('Saved ${models.length} models to ObjectBox');

        totalLoaded += models.length;

        onProgress?.call(
          'Завантажено $totalLoaded записів...',
          totalLoaded,
          estimatedTotal,
        );

        if (response.length < pageSize) {
          print('Received less than pageSize records, breaking loop');
          break; // останній пакет
        }
        page++;

        if (page % 10 == 0) {
          print('Reached page multiple of 10, adding delay');
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      print('Sync completed successfully. Total records: $totalLoaded');
      onProgress?.call('Завершено!', totalLoaded, totalLoaded);
    } catch (e) {
      print('Error during sync: $e');
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
      int estimatedTotal = 46000; // Очікуване значення

      onProgress?.call('Початок завантаження...', 0, estimatedTotal);

      while (true) {
        onProgress?.call(
          'Завантаження пакету $page (id > $lastId)...',
          allRecords.length,
          estimatedTotal,
        );

        final response = await _schemaClient
            .from(_tableName)
            .select('*')
            .gt('id', lastId)
            .order('id', ascending: true)
            .limit(pageSize);

        if (response.isEmpty) break;
        allRecords.addAll(response.cast<Map<String, dynamic>>());

        for (final row in response) {
          final idValue = row['id'];
          if (idValue is int) {
            lastId = idValue;
          } else if (idValue is num) {
            lastId = idValue.toInt();
          }
          allRecords.add(row as Map<String, dynamic>);
        }

        if (response.length == pageSize &&
            estimatedTotal < allRecords.length + 1000) {
          estimatedTotal = allRecords.length + 5000;
        }

        onProgress?.call(
          'Завантажено ${allRecords.length} записів (lastId=$lastId)...',
          allRecords.length,
          estimatedTotal,
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
