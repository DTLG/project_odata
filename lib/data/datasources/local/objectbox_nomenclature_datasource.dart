import 'package:objectbox/objectbox.dart';
import 'package:project_odata/objectbox.dart';
import '../../../core/objectbox/objectbox_entities.dart';
import '../../models/nomenclature_model.dart';
import 'nomenclature_local_datasource.dart';
import 'package:project_odata/objectbox.g.dart';
import '../../../core/injection/injection_container.dart';

class ObjectboxNomenclatureDatasource implements NomenclatureLocalDatasource {
  late final Store _store;
  late final Box<NomenclatureObx> _box;
  late final Box<BarcodeObx> _barcodes;
  late final Box<PriceObx> _prices;
  bool _initialized = false;

  ObjectboxNomenclatureDatasource() {
    // lazy init in _ensure
  }

  Future<void> _ensure() async {
    if (_initialized) return;
    _store = sl<ObjectBox>().getStore();
    _box = _store.box<NomenclatureObx>();
    _barcodes = _store.box<BarcodeObx>();
    _prices = _store.box<PriceObx>();
    _initialized = true;
  }

  NomenclatureModel _fromObx(NomenclatureObx n) {
    return NomenclatureModel(
      objectBoxId: n.obxId,
      id: n.id,
      createdAt: DateTime.fromMillisecondsSinceEpoch(n.createdAtMs),
      name: n.name,
      nameLower: n.nameLower,
      price: n.price,
      guid: n.guid,
      parentGuid: n.parentGuid,
      isFolder: n.isFolder,
      description: n.description,
      article: n.article,
      unitName: n.unitName,
      unitGuid: n.unitGuid,
    );
  }

  NomenclatureObx _toObx(NomenclatureModel m) {
    return NomenclatureObx(
      obxId: m.objectBoxId,
      guid: m.guid,
      name: m.name,
      nameLower: (m.nameLower.isNotEmpty ? m.nameLower : m.name.toLowerCase()),
      article: m.article,
      parentGuid: m.parentGuid,
      isFolder: m.isFolder,
      id: m.id,
      price: m.price,
      unitName: m.unitName,
      unitGuid: m.unitGuid,
      description: m.description,
      createdAtMs: m.createdAt.millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> clearAllNomenclature() async {
    await _ensure();
    _box.removeAll();
    _barcodes.removeAll();
    _prices.removeAll();
  }

  @override
  Future<void> deleteNomenclature(String guid) async {
    await _ensure();
    final q = _box.query(NomenclatureObx_.guid.equals(guid)).build();
    final ids = q.findIds();
    q.close();
    if (ids.isNotEmpty) {
      _box.removeMany(ids);
      final bc = _barcodes.query(BarcodeObx_.nomGuid.equals(guid)).build();
      _barcodes.removeMany(bc.findIds());
      bc.close();
      final pr = _prices.query(PriceObx_.nomGuid.equals(guid)).build();
      _prices.removeMany(pr.findIds());
      pr.close();
    }
  }

  @override
  Future<Map<String, dynamic>> debugDatabase() async {
    await _ensure();
    return {
      'nomenclature_count': _box.count(),
      'barcodes_count': _barcodes.count(),
      'prices_count': _prices.count(),
    };
  }

  @override
  Future<List<NomenclatureModel>> getAllNomenclature() async {
    await _ensure();
    final all = _box.getAll();
    final models = all.map(_fromObx).toList();
    // attach relations
    // keep for potential future relation joins
    for (final m in models) {
      m.barcodes = _barcodes
          .query(BarcodeObx_.nomGuid.equals(m.guid))
          .build()
          .find()
          .map((e) => BarcodeModel(nomGuid: e.nomGuid, barcode: e.barcode))
          .toList();
      m.prices = _prices
          .query(PriceObx_.nomGuid.equals(m.guid))
          .build()
          .find()
          .map(
            (e) => PriceModel(
              nomGuid: e.nomGuid,
              price: e.price,
              createdAt: e.createdAtMs == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(e.createdAtMs!),
            ),
          )
          .toList();
    }
    return models;
  }

  @override
  Future<NomenclatureModel?> getNomenclatureByBarcode(String barcode) async {
    await _ensure();
    final q = _barcodes.query(BarcodeObx_.barcode.equals(barcode)).build();
    final res = q.findFirst();
    q.close();
    if (res == null) return null;
    return getNomenclatureByGuid(res.nomGuid);
  }

  @override
  Future<List<NomenclatureModel>> getNomenclatureByArticle(
    String article,
  ) async {
    await _ensure();
    final q = _box
        .query(NomenclatureObx_.article.contains(article, caseSensitive: false))
        .order(NomenclatureObx_.name)
        .build();
    final res = q.find();
    q.close();
    return res.map(_fromObx).toList();
  }

  @override
  Future<NomenclatureModel?> getNomenclatureByGuid(String guid) async {
    await _ensure();
    final q = _box.query(NomenclatureObx_.guid.equals(guid)).build();
    final res = q.findFirst();
    q.close();
    if (res == null) return null;
    final model = _fromObx(res);
    model.barcodes = _barcodes
        .query(BarcodeObx_.nomGuid.equals(guid))
        .build()
        .find()
        .map((e) => BarcodeModel(nomGuid: e.nomGuid, barcode: e.barcode))
        .toList();
    model.prices = _prices
        .query(PriceObx_.nomGuid.equals(guid))
        .build()
        .find()
        .map(
          (e) => PriceModel(
            nomGuid: e.nomGuid,
            price: e.price,
            createdAt: e.createdAtMs == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(e.createdAtMs!),
          ),
        )
        .toList();
    return model;
  }

  @override
  Future<int> getNomenclatureCount() async {
    await _ensure();
    return _box.count();
  }

  @override
  Future<void> insertNomenclature(List<NomenclatureModel> nomenclatures) async {
    await _ensure();
    final obxList = nomenclatures.map(_toObx).toList();
    _box.putMany(
      obxList,
      mode: PutMode.insert,

      // conflictResolution: ConflictResolution.replace,
    );
    for (final n in nomenclatures) {
      // barcodes
      final existingB = _barcodes
          .query(BarcodeObx_.nomGuid.equals(n.guid))
          .build();
      _barcodes.removeMany(existingB.findIds());
      existingB.close();
      if (n.barcodes.isNotEmpty) {
        _barcodes.putMany(
          n.barcodes
              .map((b) => BarcodeObx(nomGuid: n.guid, barcode: b.barcode))
              .toList(),
        );
      }
      // prices
      final existingP = _prices.query(PriceObx_.nomGuid.equals(n.guid)).build();
      _prices.removeMany(existingP.findIds());
      existingP.close();
      if (n.prices.isNotEmpty) {
        _prices.putMany(
          n.prices
              .map(
                (p) => PriceObx(
                  nomGuid: n.guid,
                  price: p.price,
                  createdAtMs:
                      (p.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
                ),
              )
              .toList(),
        );
      }
    }
  }

  @override
  Future<void> recreateDatabase() async {
    await _ensure();
    clearAllNomenclature();
  }

  @override
  Future<List<NomenclatureModel>> searchNomenclatureByName(String name) async {
    await _ensure();
    final q = _box
        .query(
          NomenclatureObx_.nameLower.contains(
            name.toLowerCase(),
            caseSensitive: false,
          ),
        )
        .order(NomenclatureObx_.name)
        .build();
    final res = q.find();
    q.close();
    if (res.isNotEmpty) return res.map(_fromObx).toList();
    // Fallback for legacy records missing nameLower
    final qb2 = _box
        .query(NomenclatureObx_.name.contains(name, caseSensitive: false))
        .order(NomenclatureObx_.name)
        .build();
    final res2 = qb2.find();
    qb2.close();
    return res2.map(_fromObx).toList();
  }

  @override
  Future<void> updateNomenclature(NomenclatureModel nomenclature) async {
    await _ensure();
    // ensure nameLower is set
    if (nomenclature.nameLower.isEmpty) {
      nomenclature.nameLower = nomenclature.name.toLowerCase();
    }
    _box.put(_toObx(nomenclature));
  }
}
