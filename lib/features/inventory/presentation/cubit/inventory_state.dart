part of 'inventory_cubit.dart';

/// Base state for inventory operations
abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class InventoryInitial extends InventoryState {}

/// Loading state
class InventoryLoading extends InventoryState {}

/// State when documents are loaded
class InventoryDocumentsLoaded extends InventoryState {
  final List<InventoryDocument> documents;

  const InventoryDocumentsLoaded(this.documents);

  @override
  List<Object?> get props => [documents];
}

/// State when document items are loaded
class InventoryItemsLoaded extends InventoryState {
  final List<InventoryItem> items;

  const InventoryItemsLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

/// Error state
class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}
