import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/inventory_document.dart';
import '../entities/inventory_item.dart';

/// Repository interface for inventory operations
abstract class InventoryRepository {
  /// Get all inventory documents
  Future<Either<Failure, List<InventoryDocument>>> getDocuments();

  /// Create a new inventory document
  Future<Either<Failure, InventoryDocument>> createDocument();

  /// Get inventory items for a specific document
  Future<Either<Failure, List<InventoryItem>>> getDocumentItems(
    String documentId,
  );

  /// Add or update an inventory item
  Future<Either<Failure, InventoryItem>> addOrUpdateItem({
    required String documentId,
    required String nomenclatureId,
    required double count,
  });

  /// Close an inventory document
  Future<Either<Failure, bool>> closeDocument(String documentId);

  /// Scan barcode and set SKU for document, returns updated/created item
  Future<Either<Failure, InventoryItem>> setSku({
    required String documentId,
    required String barcode,
  });
}
