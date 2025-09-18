import 'package:equatable/equatable.dart';

/// Entity representing a counterparty (kontragent)
class KontragentEntity extends Equatable {
  final String guid;
  final String name;
  final String nameLower;
  final String edrpou;
  final bool isFolder;
  final String parentGuid;
  final String description;
  final DateTime createdAt;

  const KontragentEntity({
    required this.guid,
    required this.name,
    required this.nameLower,
    required this.edrpou,
    required this.isFolder,
    required this.parentGuid,
    required this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    guid,
    name,
    nameLower,
    edrpou,
    isFolder,
    parentGuid,
    description,
    createdAt,
  ];
}
