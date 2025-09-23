import 'package:project_odata/core/objectbox/objectbox_entities.dart';
import 'package:project_odata/features/nomenclature/domain/entities/nomenclature_entity.dart';

/// DTO for transferring lightweight data across isolates
class NomenclatureDto {
  final String guid;
  final String name;
  final String nameLower;
  final bool isFolder;
  final String parentGuid;
  final int createdAtMs;
  final double price;
  final String article;
  final String barcodes; // comma-separated
  final String prices; // comma-separated numeric values
  final String unitName;
  final String unitGuid;
  final String id; // keep as String to match ObjectBox model

  NomenclatureDto({
    required this.guid,
    required this.name,
    required this.nameLower,
    required this.isFolder,
    required this.parentGuid,
    required this.createdAtMs,
    required this.price,
    required this.article,
    required this.barcodes,
    required this.prices,
    required this.unitName,
    required this.unitGuid,
    required this.id,
  });

  factory NomenclatureDto.fromObx(NomenclatureObx k) => NomenclatureDto(
    guid: k.guid,
    name: k.name,
    nameLower: k.nameLower,
    isFolder: k.isFolder,
    parentGuid: k.parentGuid,
    createdAtMs: k.createdAtMs,
    price: k.price,
    article: k.article,
    barcodes: k.barcodes,
    prices: k.prices,
    unitName: k.unitName,
    unitGuid: k.unitGuid,
    id: k.id,
  );
}

/// Top-level mapper for use with `compute` (must be a top-level function)
List<NomenclatureEntity> mapNomenclatureDtosToEntities(
  List<NomenclatureDto> list,
) {
  return list
      .map(
        (k) => NomenclatureEntity(
          guid: k.guid,
          name: k.name,
          nameLower: k.nameLower,
          isFolder: k.isFolder,
          parentGuid: k.parentGuid,
          description: '',
          createdAt: k.createdAtMs > 0
              ? DateTime.fromMillisecondsSinceEpoch(k.createdAtMs)
              : DateTime.now(),
          price: k.price,
          article: k.article,
          barcodes: k.barcodes.isNotEmpty
              ? k.barcodes
                    .split(',')
                    .where((s) => s.trim().isNotEmpty)
                    .map((s) => BarcodeEntity(nomGuid: k.guid, barcode: s))
                    .toList()
              : const <BarcodeEntity>[],
          prices: k.prices.isNotEmpty
              ? k.prices
                    .split(',')
                    .where((s) => s.trim().isNotEmpty)
                    .map(
                      (s) => PriceEntity(
                        nomGuid: k.guid,
                        price: double.tryParse(s) ?? 0.0,
                        createdAt: null,
                      ),
                    )
                    .toList()
              : const <PriceEntity>[],
          unitName: k.unitName,
          unitGuid: k.unitGuid,
          id: k.id,
        ),
      )
      .toList();
}
