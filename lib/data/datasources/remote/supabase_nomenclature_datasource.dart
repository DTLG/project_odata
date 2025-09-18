import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nomenclature_model.dart';
import '../../../core/config/supabase_config.dart';

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

  Future<Map<String, List<BarcodeModel>>> _fetchBarcodesByGuids(
    List<String> guids,
  ) async {
    final Map<String, List<BarcodeModel>> map = {};
    final Set<String> guidsSet = guids.toSet();
    const int pageSize = 1000; // Supabase default max rows per request
    int offset = 0;
    while (true) {
      final rows = await _schemaClient
          .from(_barcodesTable)
          .select('nom_guid, barcode')
          .order('nom_guid')
          .range(offset, offset + pageSize - 1);
      if (rows.isEmpty) break;
      for (final row in rows) {
        final guid = row['nom_guid']?.toString() ?? '';
        final code = row['barcode']?.toString() ?? '';
        if (guid.isEmpty || code.isEmpty) continue;
        if (!guidsSet.contains(guid)) continue;
        (map[guid] ??= <BarcodeModel>[]).add(
          BarcodeModel(nomGuid: guid, barcode: code),
        );
      }
      if (rows.length < pageSize) break;
      offset += pageSize;
    }
    return map;
  }

  Future<Map<String, List<PriceModel>>> _fetchPricesByGuids(
    List<String> guids,
  ) async {
    final Map<String, List<PriceModel>> map = {};
    final Set<String> guidsSet = guids.toSet();
    const int pageSize = 1000; // Supabase default max rows per request
    int offset = 0;
    while (true) {
      final rows = await _schemaClient
          .from(_pricesTable)
          .select('nom_guid, price')
          .order('nom_guid')
          .range(offset, offset + pageSize - 1);
      if (rows.isEmpty) break;
      for (final row in rows) {
        final guid = row['nom_guid']?.toString() ?? '';
        final price = (row['price'] as num?)?.toDouble();
        if (guid.isEmpty || price == null) continue;
        if (!guidsSet.contains(guid)) continue;
        (map[guid] ??= <PriceModel>[]).add(
          PriceModel(nomGuid: guid, price: price),
        );
      }
      if (rows.length < pageSize) break;
      offset += pageSize;
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
      final barcodesMap = await _fetchBarcodesByGuids(guids);
      final pricesMap = await _fetchPricesByGuids(guids);

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
      final barcodesMap = await _fetchBarcodesByGuids(guids);
      final pricesMap = await _fetchPricesByGuids(guids);

      final models = allRecords.map<NomenclatureModel>((json) {
        final model = NomenclatureModel.fromJson(json);
        model.barcodes = barcodesMap[model.guid] ?? const <BarcodeModel>[];
        model.prices = pricesMap[model.guid] ?? const <PriceModel>[];
        return model;
      }).toList();

      onProgress?.call('Завершено!', models.length, models.length);

      return models;
    } catch (e) {
      throw Exception('Помилка при отриманні номенклатури з прогресом: $e');
    }
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
      final barcodesMap = await _fetchBarcodesByGuids(guids);
      final pricesMap = await _fetchPricesByGuids(guids);

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
      final barcodesMap = await _fetchBarcodesByGuids(guids);
      final pricesMap = await _fetchPricesByGuids(guids);

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
