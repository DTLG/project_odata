import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/inventory_document.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/usecases/get_inventory_documents.dart';
import '../../domain/usecases/create_inventory_document.dart';
import '../../domain/usecases/get_document_items.dart';
import '../../domain/usecases/add_or_update_item.dart';
import '../../domain/usecases/close_document.dart';
import '../../domain/usecases/set_sku.dart';
import 'package:project_odata/core/usecases/usecase.dart';

part 'inventory_state.dart';

/// Cubit for managing inventory state
class InventoryCubit extends Cubit<InventoryState> {
  final GetInventoryDocuments getInventoryDocuments;
  final CreateInventoryDocument createInventoryDocument;
  final GetDocumentItems getDocumentItems;
  final AddOrUpdateItem addOrUpdateItem;
  final CloseDocument closeDocument;
  final SetSku setSku;

  InventoryCubit({
    required this.getInventoryDocuments,
    required this.createInventoryDocument,
    required this.getDocumentItems,
    required this.addOrUpdateItem,
    required this.closeDocument,
    required this.setSku,
  }) : super(InventoryInitial());

  /// Load all inventory documents
  Future<void> loadDocuments() async {
    emit(InventoryLoading());

    final result = await getInventoryDocuments(NoParams());

    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (documents) => emit(InventoryDocumentsLoaded(documents)),
    );
  }

  /// Scan barcode and add/update item
  Future<void> scanBarcode({
    required String documentId,
    required String barcode,
  }) async {
    final result = await setSku(
      SetSkuParams(documentId: documentId, barcode: barcode),
    );
    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (_) => loadDocumentItems(documentId),
    );
  }

  /// Create a new inventory document
  Future<void> createDocument() async {
    emit(InventoryLoading());

    final result = await createInventoryDocument(NoParams());

    result.fold((failure) => emit(InventoryError(failure.message)), (document) {
      // Reload documents to include the new one
      loadDocuments();
    });
  }

  /// Load items for a specific document
  Future<void> loadDocumentItems(String documentId) async {
    emit(InventoryLoading());

    final result = await getDocumentItems(documentId);

    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (items) => emit(InventoryItemsLoaded(items)),
    );
  }

  /// Add or update an inventory item
  Future<void> addOrUpdateInventoryItem({
    required String documentId,
    required String nomenclatureId,
    required double count,
  }) async {
    final result = await addOrUpdateItem(
      AddOrUpdateItemParams(
        documentId: documentId,
        nomenclatureId: nomenclatureId,
        count: count,
      ),
    );

    result.fold((failure) => emit(InventoryError(failure.message)), (item) {
      // Reload items to reflect the change
      loadDocumentItems(documentId);
    });
  }

  /// Close an inventory document
  Future<void> closeInventoryDocument(String documentId) async {
    final result = await closeDocument(documentId);

    result.fold((failure) => emit(InventoryError(failure.message)), (success) {
      if (success) {
        // Reload documents to reflect the change
        loadDocuments();
      }
    });
  }
}
