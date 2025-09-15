import '../../domain/entities/kontragent_entity.dart';

/// Data model for kontragent
class KontragentModel extends KontragentEntity {
  const KontragentModel({
    required super.guid,
    required super.name,
    required super.edrpou,
    required super.isFolder,
    required super.parentGuid,
    required super.description,
    required super.createdAt,
  });

  /// Create model from JSON
  factory KontragentModel.fromJson(Map<String, dynamic> json) {
    return KontragentModel(
      guid: json['guid'] ?? '',
      name: json['name'] ?? '',
      edrpou: json['edrpou'] ?? '',
      isFolder: json['is_folder'] ?? false,
      parentGuid: json['parent_guid'] ?? '',
      description: json['description'] ?? '',
      createdAt: () {
        final value = json['created_at'];
        if (value is String) {
          return DateTime.tryParse(value) ?? DateTime.now();
        }
        return DateTime.now();
      }(),
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'name': name,
      'edrpou': edrpou,
      'is_folder': isFolder,
      'parent_guid': parentGuid,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create model from entity
  factory KontragentModel.fromEntity(KontragentEntity entity) {
    return KontragentModel(
      guid: entity.guid,
      name: entity.name,
      edrpou: entity.edrpou,
      isFolder: entity.isFolder,
      parentGuid: entity.parentGuid,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }
}
