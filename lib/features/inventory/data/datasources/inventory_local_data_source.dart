import '../models/inventory_document_model.dart';
import '../models/inventory_item_model.dart';

/// Local data source interface for inventory operations
abstract class InventoryLocalDataSource {
  /// Cache inventory documents locally
  Future<void> cacheDocuments(List<InventoryDocumentModel> documents);

  /// Get cached inventory documents
  Future<List<InventoryDocumentModel>> getCachedDocuments();

  /// Cache inventory items for a document
  Future<void> cacheDocumentItems(
    String documentId,
    List<InventoryItemModel> items,
  );

  /// Get cached inventory items for a document
  Future<List<InventoryItemModel>> getCachedDocumentItems(String documentId);

  /// Clear all cached data
  Future<void> clearCache();
}
