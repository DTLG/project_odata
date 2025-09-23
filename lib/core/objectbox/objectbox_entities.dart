import 'package:objectbox/objectbox.dart';
import 'package:project_odata/objectbox.g.dart';

@Entity()
class NomenclatureObx {
  @Id()
  int obxId;

  @Index()
  @Unique()
  String guid;

  @Index()
  String name;

  @Index()
  String nameLower;

  @Index()
  String article;

  @Index()
  String parentGuid;

  bool isFolder;

  String id; // Supabase id as string

  double price;

  String unitName;
  String unitGuid;
  String description;

  int createdAtMs;

  String barcodes;
  String prices;

  NomenclatureObx({
    this.obxId = 0,
    required this.guid, // робимо обов’язковим
    this.name = '',
    this.nameLower = '',
    this.article = '',
    this.parentGuid = '',
    this.isFolder = false,
    this.id = '',
    this.price = 0.0,
    this.unitName = '',
    this.unitGuid = '',
    this.description = '',
    this.createdAtMs = 0,
    this.barcodes = '',
    this.prices = '',
  });
}

@Entity()
class BarcodeObx {
  @Id()
  int obxId;

  @Index()
  String nomGuid;

  @Index()
  String barcode;

  BarcodeObx({this.obxId = 0, this.nomGuid = '', this.barcode = ''});
}

@Entity()
class PriceObx {
  @Id()
  int obxId;

  @Index()
  String nomGuid;

  double price;

  int? createdAtMs;

  PriceObx({
    this.obxId = 0,
    this.nomGuid = '',
    this.price = 0.0,
    this.createdAtMs,
  });
}

@Entity()
class KontragentObx {
  @Id()
  int obxId;

  @Index()
  String guid;

  @Index()
  String name;

  @Index()
  String nameLower;

  @Index()
  String parentGuid;

  bool isFolder;

  String? edrpou;

  KontragentObx({
    this.obxId = 0,
    this.guid = '',
    this.name = '',
    this.nameLower = '',
    this.parentGuid = '',
    this.isFolder = false,
    this.edrpou,
  });
}

@Entity()
class AgentObx {
  @Id()
  int obxId;

  @Index()
  String guid;

  @Index()
  String name;

  @Index()
  String nameLower;

  @Index()
  String parentGuid;

  bool isFolder;

  int? password; // optional pin/password

  AgentObx({
    this.obxId = 0,
    this.guid = '',
    this.name = '',
    this.nameLower = '',
    this.parentGuid = '',
    this.isFolder = false,
    this.password,
  });
}

@Entity()
class TypeOfRepairObx {
  @Id()
  int obxId;

  @Index()
  String guid;

  @Index()
  String name;

  int? createdAtMs;

  TypeOfRepairObx({
    this.obxId = 0,
    this.guid = '',
    this.name = '',
    this.createdAtMs,
  });
}
