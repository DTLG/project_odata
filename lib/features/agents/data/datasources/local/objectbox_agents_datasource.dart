import 'package:objectbox/objectbox.dart';
import '../../models/agent_model.dart';
import 'package:project_odata/objectbox.dart';
import '../../../../../core/objectbox/objectbox_entities.dart';
import 'sqlite_agents_datasource.dart';
import 'package:project_odata/objectbox.g.dart';
import '../../../../../../core/injection/injection_container.dart';

class ObjectBoxAgentsDatasourceImpl implements AgentsLocalDataSource {
  late final Store _store;
  late final Box<AgentObx> _box;
  bool _initialized = false;

  Future<void> _ensure() async {
    if (_initialized) return;
    _store = sl<ObjectBox>().getStore();
    _box = _store.box<AgentObx>();
    _initialized = true;
  }

  AgentObx _toObx(AgentModel m) => AgentObx(
    guid: m.guid,
    name: m.name,
    isFolder: m.isFolder,
    parentGuid: m.parentGuid,
    password: int.tryParse(m.password ?? ''),
  );

  AgentModel _fromObx(AgentObx e) => AgentModel(
    guid: e.guid,
    name: e.name,
    isFolder: e.isFolder,
    parentGuid: e.parentGuid,
    createdAt: null,
    password: e.password?.toString(),
  );

  @override
  Future<void> clearAllAgents() async {
    await _ensure();
    _box.removeAll();
  }

  @override
  Future<int> getAgentsCount() async {
    await _ensure();
    return _box.count();
  }

  @override
  Future<List<AgentModel>> getChildren(String parentGuid) async {
    await _ensure();
    final q = _box
        .query(AgentObx_.parentGuid.equals(parentGuid))
        .order(AgentObx_.isFolder, flags: Order.descending)
        .order(AgentObx_.name)
        .build();
    final res = q.find();
    q.close();
    return res.map(_fromObx).toList();
  }

  @override
  Future<List<AgentModel>> getRoot() async {
    await _ensure();
    final rootGuid = '00000000-0000-0000-0000-000000000000';
    final q = _box
        .query(AgentObx_.parentGuid.oneOf([rootGuid, '']))
        .order(AgentObx_.isFolder, flags: Order.descending)
        .order(AgentObx_.name)
        .build();
    final res = q.find();
    q.close();
    return res.map(_fromObx).toList();
  }

  @override
  Future<void> insertAgents(List<AgentModel> agents) async {
    await _ensure();
    _box.putMany(agents.map(_toObx).toList(), mode: PutMode.put);
  }

  @override
  Future<List<AgentModel>> searchByName(String query) async {
    await _ensure();
    final q = _box
        .query(AgentObx_.name.contains(query, caseSensitive: false))
        .order(AgentObx_.name)
        .build();
    final res = q.find();
    q.close();
    return res.map(_fromObx).toList();
  }
}
