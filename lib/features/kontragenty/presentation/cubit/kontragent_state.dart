part of 'kontragent_cubit.dart';

/// Base state for kontragent operations
abstract class KontragentState extends Equatable {
  const KontragentState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class KontragentInitial extends KontragentState {}

/// Loading state
class KontragentLoading extends KontragentState {}

/// State when kontragenty are loaded
class KontragentLoaded extends KontragentState {
  final List<KontragentEntity> kontragenty;

  const KontragentLoaded(this.kontragenty);

  @override
  List<Object?> get props => [kontragenty];
}

/// State when kontragenty tree is loaded (for hierarchical view)
class KontragentTreeLoaded extends KontragentState {
  final List<KontragentEntity> rootFolders;

  const KontragentTreeLoaded(this.rootFolders);

  @override
  List<Object?> get props => [rootFolders];
}

/// Error state
class KontragentError extends KontragentState {
  final String message;

  const KontragentError(this.message);

  @override
  List<Object?> get props => [message];
}
