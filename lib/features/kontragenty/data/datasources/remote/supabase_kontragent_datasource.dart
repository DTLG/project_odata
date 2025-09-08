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

      List<KontragentModel> allModels = [];
      int offset = 0;
      const int batchSize = 1000; // Розмір пакету для завантаження

      while (true) {
        print(
          '📦 Завантажуємо пакет ${(offset ~/ batchSize) + 1} (offset: $offset)...',
        );

        final response = await _supabaseClient
            .schema(SupabaseConfig.schema)
            .from('kontragenty')
            .select('*')
            .order('created_at', ascending: false)
            .range(offset, offset + batchSize - 1);

        final batchModels = (response as List)
            .map(
              (json) => KontragentModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        allModels.addAll(batchModels);

        print(
          '📊 Пакет ${(offset ~/ batchSize) + 1}: ${batchModels.length} записів',
        );

        // Якщо отримали менше записів ніж розмір пакету, це останній пакет
        if (batchModels.length < batchSize) {
          break;
        }

        offset += batchSize;
      }

      print('✅ Завантажено ${allModels.length} контрагентів з Supabase');
      return allModels;
    } catch (e) {
      print('❌ Помилка завантаження з Supabase: $e');
      throw Exception('Failed to fetch kontragenty from Supabase: $e');
    }
  }
}
