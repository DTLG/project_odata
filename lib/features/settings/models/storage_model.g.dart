// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Storages _$StoragesFromJson(Map<String, dynamic> json) => Storages(
      storages: (json['value'] as List<dynamic>)
          .map((e) => Storage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );


Storage _$StorageFromJson(Map<String, dynamic> json) => Storage(
      storageId: json['Ref_Key'] as String?,
      name: json['Description'] as String?,
    );

