import 'package:equatable/equatable.dart';

/// Entity representing an inventory item
class InventoryItem extends Equatable {
  final String id;
  final String documentId;
  final String nomenclatureId;
  final String name;
  final String article;
  final String unit;
  final double count;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const InventoryItem({
    required this.id,
    required this.documentId,
    required this.nomenclatureId,
    required this.name,
    required this.article,
    required this.unit,
    required this.count,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    documentId,
    nomenclatureId,
    name,
    article,
    unit,
    count,
    createdAt,
    updatedAt,
  ];
}
