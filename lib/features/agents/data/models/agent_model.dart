class AgentModel {
  final String guid;
  final String name;
  final bool isFolder;
  final String parentGuid;
  final DateTime? createdAt;
  final String? password; // new optional field from supabase

  AgentModel({
    required this.guid,
    required this.name,
    required this.isFolder,
    required this.parentGuid,
    required this.createdAt,
    this.password,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    String? parsePassword(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      final s = v.toString();
      return s;
    }

    return AgentModel(
      guid: (json['guid'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      isFolder: (json['is_folder'] ?? 0) == 1 || json['is_folder'] == true,
      parentGuid: (json['parent_guid'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      password: parsePassword(json['password']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guid': guid,
      'name': name,
      'is_folder': isFolder ? 1 : 0,
      'parent_guid': parentGuid,
      'created_at': createdAt?.toIso8601String() ?? '',
      'password': password,
    };
  }
}
