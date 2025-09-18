import '../../models/repair_request_model.dart';

abstract class RepairLocalDataSource {
  Future<void> save(RepairRequestModel model);
  Future<List<RepairRequestModel>> getAll();
  Future<void> delete(String id);
}
