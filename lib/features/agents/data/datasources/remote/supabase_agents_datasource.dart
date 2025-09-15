import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/agent_model.dart';
import '../../../../../core/config/supabase_config.dart';

abstract class AgentsRemoteDataSource {
  Future<List<AgentModel>> fetchAll();
}

class SupabaseAgentsDatasourceImpl implements AgentsRemoteDataSource {
  final SupabaseClient client;
  SupabaseAgentsDatasourceImpl(this.client);

  @override
  Future<List<AgentModel>> fetchAll() async {
    List<AgentModel> all = [];
    int offset = 0;
    const int batchSize = 1000;
    while (true) {
      final resp = await client
          .schema(SupabaseConfig.schema)
          .from('agents')
          .select('*')
          .order('created_at', ascending: false)
          .range(offset, offset + batchSize - 1);
      final batch = (resp as List)
          .map((e) => AgentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      all.addAll(batch);
      if (batch.length < batchSize) break;
      offset += batchSize;
    }
    return all;
  }
}
