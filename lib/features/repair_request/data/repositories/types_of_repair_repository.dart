import '../datasources/local/sqlite_types_of_repair_datasource.dart';
import '../datasources/remote/supabase_types_of_repair_datasource.dart';

class TypesOfRepairRepository {
  final SqliteTypesOfRepairDatasource local;
  final SupabaseTypesOfRepairDatasource remote;
  TypesOfRepairRepository({required this.local, required this.remote});

  Future<int> sync() async {
    final all = await remote.fetchAll();
    await local.clearAll();
    await local.insertAll(all);
    return local.getCount();
  }

  Future<int> count() => local.getCount();
}
