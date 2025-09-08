import 'package:json_annotation/json_annotation.dart';

part 'storage_model.g.dart';

@JsonSerializable()
class Storages {
  @JsonKey(name: 'value')
  final List<Storage> storages;

  factory Storages.fromJson(Map<String, dynamic> json) =>
      _$StoragesFromJson(json);

  Storages({required this.storages});

  static final empty = Storages(storages: []);
}

@JsonSerializable()
class Storage {
  @JsonKey(name: 'Ref_Key')
  final String? storageId;
  @JsonKey(name: 'Description')
  final String? name;

  Storage({required this.storageId, required this.name});

  factory Storage.fromJson(Map<String, dynamic> json) =>
      _$StorageFromJson(json);
}
