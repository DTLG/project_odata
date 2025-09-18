import 'package:equatable/equatable.dart';

/// Domain entity для номенклатури
/// Представляє бізнес-модель номенклатури незалежно від джерела даних
class NomenclatureEntity extends Equatable {
  final String id;
  final DateTime createdAt;
  final String name;
  final String nameLower;
  final double price;
  final String guid;
  final String parentGuid;
  final bool isFolder;
  final String description;
  final String article;
  final String unitName;
  final String unitGuid;
  final List<BarcodeEntity> barcodes;
  final List<PriceEntity> prices;

  const NomenclatureEntity({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.nameLower,
    required this.price,
    required this.guid,
    required this.parentGuid,
    required this.isFolder,
    required this.description,
    required this.article,
    required this.unitName,
    required this.unitGuid,
    this.barcodes = const [],
    this.prices = const [],
  });

  fromJson(Map<String, dynamic> json) {
    final String rawName = json['name']?.toString() ?? '';
    return NomenclatureEntity(
      id: json['id'],
      createdAt: json['created_at'],
      name: rawName,
      nameLower: rawName.toLowerCase(),
      price: json['price'],
      guid: json['guid'],
      parentGuid: json['parent_guid'],
      isFolder: json['is_folder'],
      description: json['description'],
      article: json['article'],
      unitName: json['unit_name'],
      unitGuid: json['unit_guid'],
      barcodes: json['barcodes'],
      prices: json['prices'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    name,
    nameLower,
    price,
    guid,
    parentGuid,
    isFolder,
    description,
    article,
    unitName,
    unitGuid,
    barcodes,
    prices,
  ];
}

class BarcodeEntity extends Equatable {
  final String nomGuid;
  final String barcode;

  const BarcodeEntity({required this.nomGuid, required this.barcode});

  @override
  List<Object?> get props => [nomGuid, barcode];
}

class PriceEntity extends Equatable {
  final String nomGuid;
  final double price;
  final DateTime? createdAt;

  const PriceEntity({
    required this.nomGuid,
    required this.price,
    this.createdAt,
  });

  @override
  List<Object?> get props => [nomGuid, price, createdAt];
}
