import '../../models/kontragent_model.dart';
import '../kontragent_local_data_source.dart';
import 'package:project_odata/objectbox.dart';
import '../../../../../core/objectbox/objectbox_entities.dart';
import 'package:project_odata/objectbox.g.dart';
import '../../../../../core/injection/injection_container.dart';

abstract class ObjectBoxKontragentDatasource {
  Future<List<KontragentModel>> getAllKontragenty();
  Future<KontragentModel?> getKontragentByGuid(String guid);
  Future<List<KontragentModel>> searchKontragentyByName(String name);
  Future<List<KontragentModel>> searchKontragentyByEdrpou(String edrpou);
  Future<List<KontragentModel>>
  getRootFolders(); // Returns both folders and kontragenty with no parent
  Future<List<KontragentModel>> getChildren(String parentGuid);
  Future<void> insertKontragenty(List<KontragentModel> kontragenty);
  Future<void> clearAllKontragenty();
  Future<int> getKontragentyCount();
  Future<void> updateKontragent(KontragentModel kontragent);
  Future<void> deleteKontragent(String guid);
  Future<Map<String, dynamic>> debugDatabase();
  Future<void> recreateDatabase();
}

class ObjectBoxKontragentDatasourceImpl
    implements ObjectBoxKontragentDatasource, KontragentLocalDataSource {
  ObjectBoxKontragentDatasourceImpl();

  ObjectBox get _obx => sl<ObjectBox>();

  // ---------- Mappers ----------
  KontragentModel _toModel(KontragentObx e) {
    return KontragentModel(
      guid: e.guid,
      name: e.name,
      edrpou: e.edrpou ?? '',
      isFolder: e.isFolder,
      parentGuid: e.parentGuid,
      description: '',
      createdAt: DateTime.now(),
    );
  }

  KontragentObx _toObx(KontragentModel m) {
    return KontragentObx(
      guid: m.guid,
      name: m.name,
      edrpou: m.edrpou.isEmpty ? null : m.edrpou,
      isFolder: m.isFolder,
      parentGuid: m.parentGuid,
    );
  }

  // ---------- ObjectBoxKontragentDatasource ----------
  @override
  Future<List<KontragentModel>> getAllKontragenty() async {
    final q = _obx.kontragentBox.query()
      ..order(KontragentObx_.isFolder, flags: Order.descending)
      ..order(KontragentObx_.name);

    final query = q.build();
    try {
      final list = query.find();
      return list.map(_toModel).toList();
    } finally {
      query.close();
    }
  }

  @override
  Future<KontragentModel?> getKontragentByGuid(String guid) async {
    final q = _obx.kontragentBox
        .query(KontragentObx_.guid.equals(guid))
        .build();
    try {
      final e = q.findFirst();
      return e == null ? null : _toModel(e);
    } finally {
      q.close();
    }
  }

  @override
  Future<List<KontragentModel>> searchKontragentyByName(String name) async {
    final list = _obx.searchKontragentyByName(name);
    return list.map(_toModel).toList();
  }

  @override
  Future<List<KontragentModel>> searchKontragentyByEdrpou(String edrpou) async {
    final q = _obx.kontragentBox
        .query(KontragentObx_.edrpou.contains(edrpou, caseSensitive: false))
        .build();
    try {
      final list = q.find();
      return list.map(_toModel).toList();
    } finally {
      q.close();
    }
  }

  @override
  Future<List<KontragentModel>> getRootFolders() async {
    final list = _obx.getRootKontragenty();
    return list.map(_toModel).toList();
  }

  @override
  Future<List<KontragentModel>> getChildren(String parentGuid) async {
    final list = _obx.getChildrenKontragenty(parentGuid);
    return list.map(_toModel).toList();
  }

  @override
  Future<void> insertKontragenty(List<KontragentModel> kontragenty) async {
    if (kontragenty.isEmpty) return;
    // Deduplicate by guid to avoid duplicates in Box
    final Map<String, KontragentModel> byGuid = {
      for (final k in kontragenty) k.guid: k,
    };
    final list = byGuid.values.map(_toObx).toList();
    _obx.upsertKontragenty(list);
  }

  @override
  Future<void> clearAllKontragenty() async {
    _obx.clearKontragenty();
  }

  @override
  Future<int> getKontragentyCount() async {
    return _obx.countKontragenty();
  }

  @override
  Future<void> updateKontragent(KontragentModel kontragent) async {
    _obx.kontragentBox.put(_toObx(kontragent), mode: PutMode.put);
  }

  @override
  Future<void> deleteKontragent(String guid) async {
    final q = _obx.kontragentBox
        .query(KontragentObx_.guid.equals(guid))
        .build();
    try {
      final ids = q.findIds();
      if (ids.isNotEmpty) {
        _obx.kontragentBox.removeMany(ids);
      }
    } finally {
      q.close();
    }
  }

  @override
  Future<Map<String, dynamic>> debugDatabase() async {
    final count = _obx.kontragentBox.count();
    return {
      'engine': 'objectbox',
      'boxes': ['KontragentObx'],
      'count': count,
    };
  }

  @override
  Future<void> recreateDatabase() async {
    _obx.clearKontragenty();
  }

  // ---------- KontragentLocalDataSource (alias methods) ----------
  @override
  Future<List<KontragentModel>> searchByName(String query) {
    return searchKontragentyByName(query);
  }

  @override
  Future<List<KontragentModel>> searchByEdrpou(String query) {
    return searchKontragentyByEdrpou(query);
  }

  @override
  Future<void> clearAllData() {
    return clearAllKontragenty();
  }
}
