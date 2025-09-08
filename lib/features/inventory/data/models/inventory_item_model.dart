import '../../domain/entities/inventory_item.dart';

/// Data model for inventory item (only exposes id, name, article, count, unit)
class InventoryItemModel extends InventoryItem {
  InventoryItemModel({
    required String id,
    required String name,
    required String article,
    required double count,
    required String unit,
  }) : super(
         id: id,
         documentId: '',
         nomenclatureId: '',
         name: name,
         article: article,
         unit: unit,
         count: count,
         createdAt: DateTime.fromMillisecondsSinceEpoch(0),
         updatedAt: null,
       );

  /// Create model from JSON
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['nom_guid'] ?? '',
      name: json['nom_name'] ?? '',
      article: json['nom_article'] ?? '',
      count: (json['nom_scaned_count'] is num)
          ? (json['nom_scaned_count'] as num).toDouble()
          : 0.0,
      unit: json['nom_unit'] ?? '--',
    );
  }

  /// Convert model to JSON (only these five fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'article': article,
      'count': count,
      'unit': unit,
    };
  }

  /// Create model from entity (uses only these five fields)
  factory InventoryItemModel.fromEntity(InventoryItem entity) {
    return InventoryItemModel(
      id: entity.id,
      name: entity.name,
      article: entity.article,
      count: entity.count,
      unit: entity.unit,
    );
  }
}
