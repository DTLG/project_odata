import 'package:objectbox/objectbox.dart';
import 'repair_local_data_source.dart';
import '../../models/repair_request_model.dart';
import 'package:project_odata/objectbox.dart';
import '../../../../../core/injection/injection_container.dart';

@Entity()
class RepairRequestObx {
  @Id()
  int obxId;
  @Index()
  String id; // stable id (server id | doc_guid | number | local_id)
  String data; // json payload

  RepairRequestObx({this.obxId = 0, this.id = '', this.data = ''});
}

class ObjectBoxRepairLocalDataSource implements RepairLocalDataSource {
  late final Box<RepairRequestObx> _box;

  ObjectBoxRepairLocalDataSource() {
    final store = sl<ObjectBox>().getStore();
    _box = Box<RepairRequestObx>(store);
  }

  @override
  Future<void> save(RepairRequestModel model) async {
    final map = model.toJson();
    String? localId;
    if (map['id'] != null && map['id'].toString().isNotEmpty) {
      localId = map['id'].toString();
    } else if (map['doc_guid'] != null &&
        (map['doc_guid'] as String).isNotEmpty) {
      localId = map['doc_guid'] as String;
    } else if (map['number'] != null && (map['number'] as String).isNotEmpty) {
      localId = map['number'] as String;
    } else if (map['local_id'] != null &&
        (map['local_id'] as String).isNotEmpty) {
      localId = map['local_id'] as String;
    } else {
      localId = 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';
    }
    map['local_id'] = localId;
    final json = RepairRequestModel.fromJson(map).toJsonString();
    _box.put(RepairRequestObx(id: localId, data: json));
  }

  @override
  Future<List<RepairRequestModel>> getAll() async {
    final all = _box.getAll();
    return all.map((e) => RepairRequestModel.fromJsonString(e.data)).toList();
  }

  @override
  Future<void> delete(String id) async {
    // Fallback without codegen query props: find by scanning ids
    final all = _box.getAll();
    final toRemove = all.where((e) => e.id == id).map((e) => e.obxId).toList();
    if (toRemove.isNotEmpty) {
      _box.removeMany(toRemove);
    }
  }
}
