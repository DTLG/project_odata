import '../../domain/entities/inventory_document.dart';

/// Data model for inventory document (only exposes id, number, date)
class InventoryDocumentModel extends InventoryDocument {
  InventoryDocumentModel({
    required String id,
    required String number,
    required String date,
  }) : super(
         id: id,
         number: number,
         date: date,
         // Provide internal defaults to satisfy the domain entity
         status: '',
         createdAt: DateTime.fromMillisecondsSinceEpoch(0),
         updatedAt: null,
       );

  /// Create model from JSON
  factory InventoryDocumentModel.fromJson(Map<String, dynamic> json) {
    return InventoryDocumentModel(
      id: json['doc_guid'] ?? '',
      number: json['doc_number'] ?? '',
      date: json['doc_date'] ?? '',
    );
  }

  /// Convert model to JSON (only these three fields)
  Map<String, dynamic> toJson() {
    return {'id': id, 'number': number, 'date': date};
  }

  /// Create model from entity (uses only these three fields)
  factory InventoryDocumentModel.fromEntity(InventoryDocument entity) {
    return InventoryDocumentModel(
      id: entity.id,
      number: entity.number,
      date: entity.date,
    );
  }
}
