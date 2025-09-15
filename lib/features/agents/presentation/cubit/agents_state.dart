part of 'agents_cubit.dart';

enum AgentsStatus { initial, loading, success, failure }

class AgentsState extends Equatable {
  final AgentsStatus status;
  final List<AgentModel> items;
  final String search;
  final String? error;

  const AgentsState({
    this.status = AgentsStatus.initial,
    this.items = const [],
    this.search = '',
    this.error,
  });

  AgentsState copyWith({
    AgentsStatus? status,
    List<AgentModel>? items,
    String? search,
    String? error,
  }) {
    return AgentsState(
      status: status ?? this.status,
      items: items ?? this.items,
      search: search ?? this.search,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, items, search, error];
}
