import '../../data/repositories/agents_repository_impl.dart';

class SyncAgentsUseCase {
  final AgentsRepository repository;
  SyncAgentsUseCase(this.repository);

  Future<int> call() => repository.syncAgents();
}
