import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../agents/data/models/agent_model.dart';
import '../../../agents/data/repositories/agents_repository_impl.dart';

part 'agents_state.dart';

class AgentsCubit extends Cubit<AgentsState> {
  final AgentsRepository repository;
  AgentsCubit(this.repository) : super(const AgentsState());

  Future<void> loadRoot() async {
    emit(state.copyWith(status: AgentsStatus.loading));
    try {
      final list = await repository.getRoot();
      emit(state.copyWith(status: AgentsStatus.success, items: list));
    } catch (e) {
      emit(state.copyWith(status: AgentsStatus.failure, error: e.toString()));
    }
  }

  Future<void> openFolder(String parentGuid) async {
    emit(state.copyWith(status: AgentsStatus.loading));
    try {
      final list = await repository.getChildren(parentGuid);
      emit(state.copyWith(status: AgentsStatus.success, items: list));
    } catch (e) {
      emit(state.copyWith(status: AgentsStatus.failure, error: e.toString()));
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) return loadRoot();
    try {
      final list = await repository.searchByName(query);
      emit(
        state.copyWith(
          status: AgentsStatus.success,
          items: list,
          search: query,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: AgentsStatus.failure, error: e.toString()));
    }
  }

  Future<void> setSelectedAgentGuid(String guid) async {
    final prefs = await SharedPreferences.getInstance();
    final agent = state.items.firstWhere((a) => a.guid == guid);
    await prefs.setString('selectedAgentGuid', guid);
    await prefs.setString('selectedAgentName', agent.name);
  }
}
