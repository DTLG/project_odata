import 'package:equatable/equatable.dart';

/// Entity representing an inventory document
class InventoryDocument extends Equatable {
  final String id;
  final String number;
  final String date;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const InventoryDocument({
    required this.id,
    required this.number,
    required this.date,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, number, date, status, createdAt, updatedAt];
}
