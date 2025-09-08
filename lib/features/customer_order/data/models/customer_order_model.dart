import '../../domain/entities/customer_order_entity.dart';
import '../../../kontragenty/data/models/kontragent_model.dart';
import '../../../../data/models/nomenclature_model.dart';

/// Data model for CustomerOrderEntity
class CustomerOrderModel extends CustomerOrderEntity {
  const CustomerOrderModel({
    required super.id,
    required super.number,
    required super.createdAt,
    super.updatedAt,
    required super.customer,
    required super.items,
    required super.totalAmount,
    required super.status,
    super.notes,
  });

  /// Create from JSON
  factory CustomerOrderModel.fromJson(Map<String, dynamic> json) {
    return CustomerOrderModel(
      id: json['id'] as String,
      number: json['number'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      customer: KontragentModel.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == json['status'] as String,
      ),
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'customer': (customer as KontragentModel).toJson(),
      'items': items.map((item) => (item as OrderItemModel).toJson()).toList(),
      'total_amount': totalAmount,
      'status': status.name,
      'notes': notes,
    };
  }

  /// Create from entity
  factory CustomerOrderModel.fromEntity(CustomerOrderEntity entity) {
    return CustomerOrderModel(
      id: entity.id,
      number: entity.number,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      customer: entity.customer,
      items: entity.items,
      totalAmount: entity.totalAmount,
      status: entity.status,
      notes: entity.notes,
    );
  }
}

/// Data model for OrderItemEntity
class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.id,
    required super.nomenclature,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
    super.notes,
  });

  /// Create from JSON
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      nomenclature: NomenclatureModel.fromJson(
        json['nomenclature'] as Map<String, dynamic>,
      ).toEntity(),
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomenclature': (nomenclature as NomenclatureModel).toJson(),
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
    };
  }

  /// Create from entity
  factory OrderItemModel.fromEntity(OrderItemEntity entity) {
    return OrderItemModel(
      id: entity.id,
      nomenclature: entity.nomenclature,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      totalPrice: entity.totalPrice,
      notes: entity.notes,
    );
  }
}
