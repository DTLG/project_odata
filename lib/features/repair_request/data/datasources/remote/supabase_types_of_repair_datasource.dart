import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/config/supabase_config.dart';
import '../local/sqlite_types_of_repair_datasource.dart';

abstract class TypesOfRepairRemoteDataSource {
  Future<List<RepairTypeModel>> fetchAll();
}

class SupabaseTypesOfRepairDatasource implements TypesOfRepairRemoteDataSource {
  final SupabaseClient client;
  SupabaseTypesOfRepairDatasource(this.client);

  @override
  Future<List<RepairTypeModel>> fetchAll() async {
    try {
      final schema = SupabaseConfig.schema;
      // ignore: avoid_print
      print('🔎 Fetching types_of_repair from schema="$schema"');
      final resp = await client
          .schema(schema)
          .from('types_of_repair')
          .select('*');
      final list = (resp as List)
          .map((e) => RepairTypeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      // ignore: avoid_print
      print('✅ types_of_repair loaded: ${list.length} rows');
      return list;
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print(
        '❌ Supabase error fetching types_of_repair: ${e.code} ${e.message}',
      );
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Unexpected error fetching types_of_repair: $e');
      rethrow;
    }
  }
}
