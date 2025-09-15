import 'package:equatable/equatable.dart';

class RepairRequestEntity extends Equatable {
  final int? id; // bigint identity in DB
  final DateTime? createdAt;
  final String customerGuid; // kontragent
  final String status;
  final String? docGuid;
  final List<dynamic> zapchastyny; // json
  final List<dynamic> diagnostyka; // json
  final List<dynamic> roboty; // json
  final String number;
  final String nomGuid;
  final String nomName;
  final bool downloaded;
  final String description;
  final String agentGuid; // agent
  final String typeOfRepairGuid; // type_of_rapair_guid
  final DateTime? date;

  const RepairRequestEntity({
    this.id,
    this.createdAt,
    required this.customerGuid,
    required this.status,
    this.docGuid,
    this.zapchastyny = const [],
    this.diagnostyka = const [],
    this.roboty = const [],
    this.number = '',
    this.nomGuid = '',
    this.nomName = '',
    this.downloaded = false,
    this.description = '',
    this.agentGuid = '',
    this.typeOfRepairGuid = '',
    this.date,
  });

  @override
  List<Object?> get props => [
    id,
    createdAt,
    customerGuid,
    status,
    docGuid,
    zapchastyny,
    diagnostyka,
    roboty,
    number,
    nomGuid,
    nomName,
    downloaded,
    description,
    agentGuid,
    typeOfRepairGuid,
    date,
  ];
}
