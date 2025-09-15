import 'dart:convert';
import '../../domain/entities/repair_request_entity.dart';

class RepairRequestModel extends RepairRequestEntity {
  const RepairRequestModel({
    super.id,
    super.createdAt,
    required super.customerGuid,
    required super.status,
    super.docGuid,
    super.zapchastyny,
    super.diagnostyka,
    super.roboty,
    super.number,
    super.nomGuid,
    super.nomName,
    super.downloaded,
    super.description,
    super.agentGuid,
    super.typeOfRepairGuid,
    super.date,
  });

  factory RepairRequestModel.fromJson(Map<String, dynamic> json) {
    return RepairRequestModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      customerGuid: (json['kontragent'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      docGuid: (json['doc_guid'] ?? '').toString(),
      zapchastyny: (json['zapchastyny'] as List?)?.toList() ?? const [],
      diagnostyka: (json['diagnostyka'] as List?)?.toList() ?? const [],
      roboty: (json['roboty'] as List?)?.toList() ?? const [],
      number: (json['number'] ?? '').toString(),
      nomGuid: (json['nom_guid'] ?? '').toString(),
      nomName: (json['nom_name'] ?? '').toString(),
      downloaded: (json['downloaded'] as bool?) ?? false,
      description: (json['description'] ?? '').toString(),
      agentGuid: (json['agent'] ?? '').toString(),
      typeOfRepairGuid: (json['type_of_rapair_guid'] ?? '').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'created_at': createdAt?.toIso8601String(),
    'kontragent': customerGuid,
    'status': status,
    'doc_guid': docGuid,
    'zapchastyny': zapchastyny,
    'diagnostyka': diagnostyka,
    'roboty': roboty,
    'number': number,
    'nom_guid': nomGuid,
    'nom_name': nomName,
    'downloaded': downloaded,
    'description': description,
    'agent': agentGuid,
    'type_of_rapair_guid': typeOfRepairGuid,
    'date': date?.toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());
  static RepairRequestModel fromJsonString(String data) =>
      RepairRequestModel.fromJson(jsonDecode(data) as Map<String, dynamic>);

  factory RepairRequestModel.fromEntity(RepairRequestEntity e) =>
      RepairRequestModel(
        id: e.id,
        createdAt: e.createdAt,
        customerGuid: e.customerGuid,
        status: e.status,
        docGuid: e.docGuid,
        zapchastyny: e.zapchastyny,
        diagnostyka: e.diagnostyka,
        roboty: e.roboty,
        number: e.number,
        nomGuid: e.nomGuid,
        nomName: e.nomName,
        downloaded: e.downloaded,
        description: e.description,
        agentGuid: e.agentGuid,
        typeOfRepairGuid: e.typeOfRepairGuid,
        date: e.date,
      );

  RepairRequestEntity toEntity() => RepairRequestEntity(
    id: id,
    createdAt: createdAt,
    customerGuid: customerGuid,
    status: status,
    docGuid: docGuid,
    zapchastyny: zapchastyny,
    diagnostyka: diagnostyka,
    roboty: roboty,
    number: number,
    nomGuid: nomGuid,
    nomName: nomName,
    downloaded: downloaded,
    description: description,
    agentGuid: agentGuid,
    typeOfRepairGuid: typeOfRepairGuid,
    date: date,
  );
}
