import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:objectbox/objectbox.dart';

import 'core/objectbox/objectbox_entities.dart';
import 'objectbox.g.dart'; // created by `dart run build_runner build`

/// High-level ObjectBox facade used across the app.
/// Provides initialization and CRUD helpers for core entities.
class ObjectBox {
  late final Store store;

  // Boxes
  late final Box<NomenclatureObx> nomenclatureBox;
  late final Box<BarcodeObx> barcodeBox;
  late final Box<PriceObx> priceBox;
  late final Box<KontragentObx> kontragentBox;
  late final Box<AgentObx> agentBox;
  late final Box<TypeOfRepairObx> typeOfRepairBox;

  ObjectBox._create(this.store) {
    nomenclatureBox = Box<NomenclatureObx>(store);
    barcodeBox = Box<BarcodeObx>(store);
    priceBox = Box<PriceObx>(store);
    kontragentBox = Box<KontragentObx>(store);
    agentBox = Box<AgentObx>(store);
    typeOfRepairBox = Box<TypeOfRepairObx>(store);
  }

  getStore() => store;

  /// Create and open the Store at an app-documents subdirectory.
  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(
      directory: p.join(docsDir.path, 'objectbox'),
      macosApplicationGroup: 'project_odata.objectbox',
    );
    return ObjectBox._create(store);
  }

  /// Attach to an already opened Store (preferred to avoid multiple Stores).
  static ObjectBox fromStore(Store store) => ObjectBox._create(store);

  // --------------------- Nomenclature CRUD ---------------------

  int upsertNomenclature(NomenclatureObx e) => nomenclatureBox.put(e);

  List<NomenclatureObx> getRootNomenclature() {
    final q = nomenclatureBox
        .query(
          NomenclatureObx_.parentGuid.oneOf([
            '',
            '00000000-0000-0000-0000-000000000000',
          ]),
        )
        .order(NomenclatureObx_.isFolder, flags: Order.descending)
        .order(NomenclatureObx_.name)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  void upsertNomenclatureMany(List<NomenclatureObx> list) =>
      nomenclatureBox.putMany(list, mode: PutMode.put);

  NomenclatureObx? getNomenclatureByGuid(String guid) {
    final q = nomenclatureBox.query(NomenclatureObx_.guid.equals(guid)).build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  List<NomenclatureObx> getAllNomenclature() => nomenclatureBox.getAll();

  int countNomenclature() => nomenclatureBox.count();

  bool removeNomenclatureByGuid(String guid) {
    final q = nomenclatureBox.query(NomenclatureObx_.guid.equals(guid)).build();
    try {
      final ids = q.findIds();
      if (ids.isEmpty) return false;
      final removed = nomenclatureBox.removeMany(ids);
      // Cascade delete barcodes and prices
      final qb = barcodeBox.query(BarcodeObx_.nomGuid.equals(guid)).build();
      barcodeBox.removeMany(qb.findIds());
      qb.close();
      final qp = priceBox.query(PriceObx_.nomGuid.equals(guid)).build();
      priceBox.removeMany(qp.findIds());
      qp.close();
      return removed > 0;
    } finally {
      q.close();
    }
  }

  List<NomenclatureObx> getChildrenNomenclature(String parentGuid) {
    final q = nomenclatureBox
        .query(NomenclatureObx_.parentGuid.equals(parentGuid))
        .order(NomenclatureObx_.isFolder, flags: Order.descending)
        .order(NomenclatureObx_.name)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  List<NomenclatureObx> searchNomenclatureByName(String name) {
    final q = nomenclatureBox
        .query(NomenclatureObx_.name.contains(name, caseSensitive: false))
        .order(NomenclatureObx_.name)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  List<NomenclatureObx> searchNomenclatureByArticle(String article) {
    final q = nomenclatureBox
        .query(NomenclatureObx_.article.contains(article, caseSensitive: false))
        .order(NomenclatureObx_.name)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  NomenclatureObx? getNomenclatureByBarcode(String barcode) {
    final qb = barcodeBox.query(BarcodeObx_.barcode.equals(barcode)).build();
    try {
      final b = qb.findFirst();
      if (b == null) return null;
      return getNomenclatureByGuid(b.nomGuid);
    } finally {
      qb.close();
    }
  }

  // Barcodes/Prices helpers for a given nomenclature
  void replaceBarcodesForNom(String nomGuid, List<String> barcodes) {
    final qb = barcodeBox.query(BarcodeObx_.nomGuid.equals(nomGuid)).build();
    barcodeBox.removeMany(qb.findIds());
    qb.close();
    if (barcodes.isEmpty) return;
    barcodeBox.putMany(
      barcodes.map((b) => BarcodeObx(nomGuid: nomGuid, barcode: b)).toList(),
    );
  }

  void replacePricesForNom(String nomGuid, List<PriceObx> prices) {
    final qp = priceBox.query(PriceObx_.nomGuid.equals(nomGuid)).build();
    priceBox.removeMany(qp.findIds());
    qp.close();
    if (prices.isEmpty) return;
    priceBox.putMany(prices);
  }

  // --------------------- Kontragent CRUD ---------------------

  void upsertKontragenty(List<KontragentObx> list) =>
      kontragentBox.putMany(list, mode: PutMode.put);

  List<KontragentObx> getRootKontragenty() {
    final q = kontragentBox
        .query(
          KontragentObx_.parentGuid.oneOf([
            '',
            '00000000-0000-0000-0000-000000000000',
          ]),
        )
        .order(KontragentObx_.isFolder, flags: Order.descending)
        .order(KontragentObx_.name)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  List<KontragentObx> getChildrenKontragenty(String parentGuid) {
    final q = kontragentBox
        .query(KontragentObx_.parentGuid.equals(parentGuid))
        .order(KontragentObx_.isFolder, flags: Order.descending)
        .order(KontragentObx_.name)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  List<KontragentObx> searchKontragentyByName(String name) {
    final q = kontragentBox
        .query(KontragentObx_.name.contains(name, caseSensitive: false))
        .order(KontragentObx_.name)
        .build();
    try {
      return q.find().take(100).toList();
    } finally {
      q.close();
    }
  }

  int countKontragenty() => kontragentBox.count();

  void clearKontragenty() => kontragentBox.removeAll();

  // --------------------- Agents CRUD ---------------------

  void upsertAgents(List<AgentObx> list) =>
      agentBox.putMany(list, mode: PutMode.put);

  List<AgentObx> getRootAgents() {
    final q = agentBox
        .query(
          AgentObx_.parentGuid.oneOf([
            '',
            '00000000-0000-0000-0000-000000000000',
          ]),
        )
        .order(AgentObx_.isFolder, flags: Order.descending)
        .order(AgentObx_.name)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  List<AgentObx> getAgentChildren(String parentGuid) {
    final q = agentBox
        .query(AgentObx_.parentGuid.equals(parentGuid))
        .order(AgentObx_.isFolder, flags: Order.descending)
        .order(AgentObx_.name)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  List<AgentObx> searchAgentsByName(String name) {
    final q = agentBox
        .query(AgentObx_.name.contains(name, caseSensitive: false))
        .order(AgentObx_.name)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  int countAgents() => agentBox.count();

  void clearAgents() => agentBox.removeAll();

  // --------------------- Types of Repair CRUD ---------------------

  void upsertTypesOfRepair(List<TypeOfRepairObx> list) =>
      typeOfRepairBox.putMany(list, mode: PutMode.put);

  List<TypeOfRepairObx> getAllTypesOfRepair() => typeOfRepairBox.getAll();

  int countTypesOfRepair() => typeOfRepairBox.count();

  void clearTypesOfRepair() => typeOfRepairBox.removeAll();
}
