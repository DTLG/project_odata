import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_odata/core/config/supabase_config.dart';
import '../../models/kontragent_model.dart';
import '../kontragent_remote_data_source.dart';

/// Supabase implementation of remote data source for kontragent
class SupabaseKontragentDatasourceImpl implements KontragentRemoteDataSource {
  final SupabaseClient _supabaseClient;

  SupabaseKontragentDatasourceImpl(this._supabaseClient);

  @override
  Future<List<KontragentModel>> getAllKontragenty() async {
    try {
      print('🌐 Завантажуємо всіх контрагентів з Supabase...');

      final List<KontragentModel> allModels = [];
      const int batchSize = 1000;
      int lastId = 0; // курсор по колонці id
      int page = 1;

      while (true) {
        print('📦 Пакет $page (id > $lastId, limit: $batchSize)');

        final response = await _supabaseClient
            .schema(SupabaseConfig.schema)
            .from('kontragenty')
            .select('*')
            .gt('id', lastId)
            .order('id', ascending: true)
            .limit(batchSize);

        final rows = response as List;
        if (rows.isEmpty) break;

        for (final row in rows) {
          final map = row as Map<String, dynamic>;
          final idValue = map['id'];
          if (idValue is int) {
            lastId = idValue;
          } else if (idValue is num) {
            lastId = idValue.toInt();
          }
          allModels.add(KontragentModel.fromJson(map));
        }

        print('📊 Пакет $page: ${rows.length} записів (lastId=$lastId)');
        if (rows.length < batchSize) break; // останній неповний пакет
        page += 1;
      }

      print('✅ Завантажено ${allModels.length} контрагентів з Supabase');
      return allModels;
    } catch (e) {
      print('❌ Помилка завантаження з Supabase: $e');
      throw Exception('Failed to fetch kontragenty from Supabase: $e');
    }
  }
}
