import '../../core/entities/nomenclature_entity.dart';

/// Модель для номенклатури
/// Використовується для локального зберігання даних (SQLite)
class NomenclatureModel {
  int objectBoxId =
      0; // Залишаємо для сумісності, буде використовуватися як SQLite ID

  /// ID з Supabase
  late String id;

  /// Дата створення
  late DateTime createdAt;

  /// Назва номенклатури
  late String name;

  /// Ціна
  late double price;

  /// GUID з 1С
  late String guid;

  /// GUID батьківського елемента (дерево)
  late String parentGuid;

  /// Папка чи товар
  late bool isFolder;

  /// Опис/примітка
  late String description;

  /// Артикул
  late String article;

  /// Назва одиниці вимірювання
  late String unitName;

  /// GUID одиниці вимірювання
  late String unitGuid;

  /// Список штрихкодів
  late List<BarcodeModel> barcodes;

  /// Список цін
  late List<PriceModel> prices;

  NomenclatureModel({
    this.objectBoxId = 0,
    required this.id,
    required this.createdAt,
    required this.name,
    this.price = 0.0,
    required this.guid,
    this.parentGuid = '',
    this.isFolder = false,
    this.description = '',
    required this.article,
    required this.unitName,
    required this.unitGuid,
    List<BarcodeModel>? barcodes,
    List<PriceModel>? prices,
  }) : barcodes = barcodes ?? const <BarcodeModel>[],
       prices = prices ?? const <PriceModel>[];

  /// Створити модель з entity
  factory NomenclatureModel.fromEntity(NomenclatureEntity entity) {
    return NomenclatureModel(
      id: entity.id,
      createdAt: entity.createdAt,
      name: entity.name,
      price: entity.price,
      guid: entity.guid,
      parentGuid: entity.parentGuid,
      isFolder: entity.isFolder,
      description: entity.description,
      article: entity.article,
      unitName: entity.unitName,
      unitGuid: entity.unitGuid,
      barcodes: entity.barcodes
          .map((e) => BarcodeModel(nomGuid: e.nomGuid, barcode: e.barcode))
          .toList(),
      prices: entity.prices
          .map(
            (e) => PriceModel(
              nomGuid: e.nomGuid,
              price: e.price,
              createdAt: e.createdAt,
            ),
          )
          .toList(),
    );
  }

  /// Створити модель з JSON (Supabase response)
  factory NomenclatureModel.fromJson(Map<String, dynamic> json) {
    return NomenclatureModel(
      id: (json['id'] ?? '').toString(),
      createdAt: () {
        final value = json['created_at'];
        if (value is String) {
          return DateTime.tryParse(value) ?? DateTime.now();
        }
        return DateTime.now();
      }(),
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      guid: json['guid']?.toString() ?? '',
      parentGuid: json['parent_guid']?.toString() ?? '',
      isFolder: (json['is_folder'] as bool?) ?? false,
      description: json['description']?.toString() ?? '',
      article: json['article']?.toString() ?? '',
      unitName: json['unit_name']?.toString() ?? '',
      unitGuid: json['unit_guid']?.toString() ?? '',
      barcodes:
          (json['barcodes'] as List?)
              ?.map(
                (e) => e is Map<String, dynamic>
                    ? BarcodeModel(
                        nomGuid: json['guid']?.toString() ?? '',
                        barcode: (e['barcode']?.toString() ?? ''),
                      )
                    : null,
              )
              .whereType<BarcodeModel>()
              .toList() ??
          const <BarcodeModel>[],
      prices:
          (json['prices'] as List?)
              ?.map(
                (e) => e is Map<String, dynamic>
                    ? PriceModel(
                        nomGuid: json['guid']?.toString() ?? '',
                        price: ((e['price'] as num?)?.toDouble() ?? 0.0),
                        createdAt: null,
                      )
                    : null,
              )
              .whereType<PriceModel>()
              .toList() ??
          const <PriceModel>[],
    );
  }

  /// Конвертувати в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'price': price,
      'guid': guid,
      'parent_guid': parentGuid,
      'is_folder': isFolder,
      'description': description,
      'article': article,
      'unit_name': unitName,
      'unit_guid': unitGuid,
      'barcodes': barcodes.map((e) => e.barcode).toList(),
      'prices': prices.map((e) => e.price).toList(),
    };
  }

  /// Convert to domain entity
  NomenclatureEntity toEntity() {
    return NomenclatureEntity(
      id: id,
      createdAt: createdAt,
      name: name,
      price: price,
      guid: guid,
      parentGuid: parentGuid,
      isFolder: isFolder,
      description: description,
      article: article,
      unitName: unitName,
      unitGuid: unitGuid,
      barcodes: barcodes
          .map(
            (barcode) => BarcodeEntity(
              nomGuid: barcode.nomGuid,
              barcode: barcode.barcode,
            ),
          )
          .toList(),
      prices: prices
          .map(
            (price) => PriceEntity(
              nomGuid: price.nomGuid,
              price: price.price,
              createdAt: price.createdAt,
            ),
          )
          .toList(),
    );
  }
}

class BarcodeModel {
  String nomGuid;
  String barcode;

  BarcodeModel({required this.nomGuid, required this.barcode});
}

class PriceModel {
  String nomGuid;
  double price;
  DateTime? createdAt;

  PriceModel({required this.nomGuid, required this.price, this.createdAt});
}
