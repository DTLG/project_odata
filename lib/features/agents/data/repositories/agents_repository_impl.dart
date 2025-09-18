import '../models/agent_model.dart';
import '../datasources/local/sqlite_agents_datasource.dart';
import '../datasources/local/objectbox_agents_datasource.dart';
import '../datasources/remote/supabase_agents_datasource.dart';

abstract class AgentsRepository {
  Future<int> syncAgents();
  Future<List<AgentModel>> getRoot();
  Future<List<AgentModel>> getChildren(String parentGuid);
  Future<List<AgentModel>> searchByName(String query);
}

class AgentsRepositoryImpl implements AgentsRepository {
  final AgentsLocalDataSource local;
  final AgentsRemoteDataSource remote;

  AgentsRepositoryImpl({required this.local, required this.remote});

  @override
  Future<int> syncAgents() async {
    final all = await remote.fetchAll();
    await local.clearAllAgents();
    await local.insertAgents(all);
    return await local.getAgentsCount();
  }

  @override
  Future<List<AgentModel>> getRoot() => local.getRoot();

  @override
  Future<List<AgentModel>> getChildren(String parentGuid) =>
      local.getChildren(parentGuid);

  @override
  Future<List<AgentModel>> searchByName(String query) =>
      local.searchByName(query);
}
