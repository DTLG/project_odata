import '../models/inventory_document_model.dart';
import '../models/inventory_item_model.dart';

/// Remote data source interface for inventory operations
abstract class InventoryRemoteDataSource {
  /// Get all inventory documents from remote API
  Future<List<InventoryDocumentModel>> getDocuments();

  /// Create a new inventory document
  Future<InventoryDocumentModel> createDocument();

  /// Get inventory items for a specific document
  Future<List<InventoryItemModel>> getDocumentItems(String documentId);

  /// Add or update an inventory item
  Future<InventoryItemModel> addOrUpdateItem({
    required String documentId,
    required String nomenclatureId,
    required double count,
  });

  /// Close an inventory document
  Future<bool> closeDocument(String documentId);

  /// Scan barcode and set SKU for document, returns updated/created item
  Future<InventoryItemModel> setSku({
    required String documentId,
    required String barcode,
  });
}
