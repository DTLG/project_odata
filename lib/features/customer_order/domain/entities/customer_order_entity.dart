import 'package:equatable/equatable.dart';
import '../../../kontragenty/domain/entities/kontragent_entity.dart';
import '../../../../core/entities/nomenclature_entity.dart';

/// Entity representing a customer order
class CustomerOrderEntity extends Equatable {
  final String id;
  final String number;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final KontragentEntity customer;
  final List<OrderItemEntity> items;
  final double totalAmount;
  final OrderStatus status;
  final String? notes;

  const CustomerOrderEntity({
    required this.id,
    required this.number,
    required this.createdAt,
    this.updatedAt,
    required this.customer,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    number,
    createdAt,
    updatedAt,
    customer,
    items,
    totalAmount,
    status,
    notes,
  ];
}

/// Entity representing an item in the order
class OrderItemEntity extends Equatable {
  final String id;
  final NomenclatureEntity nomenclature;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  const OrderItemEntity({
    required this.id,
    required this.nomenclature,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    nomenclature,
    quantity,
    unitPrice,
    totalPrice,
    notes,
  ];
}

/// Enum representing order status
enum OrderStatus { draft, confirmed, processing, shipped, delivered, cancelled }

/// Extension for OrderStatus to get display names
extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.draft:
        return 'Чернетка';
      case OrderStatus.confirmed:
        return 'Підтверджено';
      case OrderStatus.processing:
        return 'В обробці';
      case OrderStatus.shipped:
        return 'Відправлено';
      case OrderStatus.delivered:
        return 'Доставлено';
      case OrderStatus.cancelled:
        return 'Скасовано';
    }
  }
}
