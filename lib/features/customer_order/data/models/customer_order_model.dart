import 'dart:convert';
import '../../domain/entities/customer_order_entity.dart';
// import removed: no longer needed here
import '../../../../data/models/nomenclature_model.dart';
import '../../../../core/entities/nomenclature_entity.dart';

/// Data model for CustomerOrderEntity
class CustomerOrderModel extends CustomerOrderEntity {
  const CustomerOrderModel({
    required super.id,
    required super.number,
    required super.createdAt,
    super.updatedAt,
    required super.customerGuid,
    required super.items,
    required super.totalAmount,
    required super.status,
    super.notes,
    super.isSent,
  });

  /// Create from JSON
  factory CustomerOrderModel.fromJson(Map<String, dynamic> json) {
    return CustomerOrderModel(
      id: json['id'] as String,
      number: json['number'] as String,
      createdAt: () {
        final value = json['created_at'];
        if (value is String && value != 'null') {
          return DateTime.tryParse(value) ?? DateTime.now();
        }
        return DateTime.now();
      }(),
      updatedAt: () {
        final value = json['updated_at'];
        if (value is String && value != 'null') {
          return DateTime.tryParse(value);
        }
        return null;
      }(),
      customerGuid: () {
        final customerValue = json['customer'];
        if (customerValue is String && customerValue.isNotEmpty) {
          return customerValue;
        }
        if (customerValue is Map) {
          final map = (customerValue as Map).cast<String, dynamic>();
          final guid =
              map['guid']?.toString() ?? map['customer_guid']?.toString();
          if (guid != null && guid.isNotEmpty) return guid;
        }
        // Legacy string like: {guid: 123, name: ...}
        if (customerValue is String) {
          final parsed = _SimpleJson.parseMap(customerValue);
          final guid = parsed['guid']?.toString();
          if (guid != null && guid.isNotEmpty) return guid;
        }
        return '';
      }(),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == json['status'] as String,
      ),
      notes: json['notes'] as String?,
      isSent: (json['is_sent'] as bool?) ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final customerJson = {'guid': customerGuid};

    final itemsJson = items
        .map(
          (item) => item is OrderItemModel
              ? item.toJson()
              : OrderItemModel.fromEntity(item).toJson(),
        )
        .toList();

    return {
      'id': id,
      'number': number,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'customer': customerJson,
      'items': itemsJson,
      'total_amount': totalAmount,
      'status': status.name,
      'notes': notes,
      'is_sent': isSent,
    };
  }

  String toJsonString() => jsonEncode(toJson());
  static CustomerOrderModel fromJsonString(String data) {
    final trimmed = data.trim();
    final looksLikeJson = trimmed.startsWith('{') && trimmed.contains('":');
    if (looksLikeJson) {
      try {
        final map = jsonDecode(trimmed) as Map<String, dynamic>;
        return CustomerOrderModel.fromJson(map);
      } catch (_) {
        // fall through
      }
    }
    // Fallback for legacy non-JSON entries
    final map = _SimpleJson.parseMap(trimmed);
    final created = map['created_at'];
    if (created is! String || created.isEmpty || created == 'null') {
      map['created_at'] = DateTime.now().toIso8601String();
    }
    if (!map.containsKey('number')) {
      map['number'] =
          map['id']?.toString() ??
          'LOCAL-${DateTime.now().millisecondsSinceEpoch}';
    }
    return CustomerOrderModel.fromJson(map);
  }

  /// Create from entity
  factory CustomerOrderModel.fromEntity(CustomerOrderEntity entity) {
    return CustomerOrderModel(
      id: entity.id,
      number: entity.number,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      customerGuid: entity.customerGuid,
      items: entity.items,
      totalAmount: entity.totalAmount,
      status: entity.status,
      notes: entity.notes,
      isSent: entity.isSent,
    );
  }
  CustomerOrderEntity toEntity() {
    return CustomerOrderEntity(
      id: id,
      number: number,
      createdAt: createdAt,
      updatedAt: updatedAt,
      customerGuid: customerGuid,
      items: items,
      totalAmount: totalAmount,
      status: status,
      notes: notes,
      isSent: isSent,
    );
  }
}

// Minimal parser for simple map string; for production, use dart:convert json
class _SimpleJson {
  static Map<String, dynamic> parseMap(String src) {
    // This is a placeholder; in real code use jsonDecode
    // To avoid breaking, return empty map if cannot parse
    try {
      // ignore: unnecessary_string_escapes
      src = src.trim().replaceAll(RegExp(r'^\{|\}'), '');
      final parts = src.split(', ');
      final map = <String, dynamic>{};
      for (final p in parts) {
        final i = p.indexOf(':');
        if (i <= 0) continue;
        final k = p
            .substring(0, i)
            .trim()
            .replaceAll("'", '')
            .replaceAll('"', '');
        final v = p.substring(i + 1).trim();
        map[k] = v;
      }
      return map;
    } catch (_) {
      return {};
    }
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
    NomenclatureEntity parsedNom;
    final nomValue = json['nomenclature'] ?? json['nomenclature_guid'];
    if (nomValue is Map<String, dynamic>) {
      parsedNom = NomenclatureModel.fromJson(nomValue).toEntity();
    } else if (nomValue is String && nomValue.isNotEmpty) {
      parsedNom = NomenclatureEntity(
        id: nomValue,
        createdAt: DateTime.now(),
        name: '',
        nameLower: '',
        price: 0.0,
        guid: nomValue,
        parentGuid: '',
        isFolder: false,
        description: '',
        article: '',
        unitName: '',
        unitGuid: '',
      );
    } else {
      parsedNom = NomenclatureEntity(
        id: '',
        createdAt: DateTime.now(),
        name: '',
        nameLower: '',
        price: 0.0,
        guid: '',
        parentGuid: '',
        isFolder: false,
        description: '',
        article: '',
        unitName: '',
        unitGuid: '',
      );
    }

    return OrderItemModel(
      id: json['id'] as String,
      nomenclature: parsedNom,
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
      // Store only GUID for local storage size and robustness
      'nomenclature_guid': nomenclature.guid,
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
