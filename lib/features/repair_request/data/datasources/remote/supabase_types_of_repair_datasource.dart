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
    final resp = await client
        .schema(SupabaseConfig.schema)
        .from('types_of_repair')
        .select('*')
        .order('created_at', ascending: false);
    return (resp as List)
        .map((e) => RepairTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
