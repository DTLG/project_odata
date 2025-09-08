import '../models/kontragent_model.dart';

/// Remote data source interface for kontragent operations
abstract class KontragentRemoteDataSource {
  /// Get all kontragenty from remote API
  Future<List<KontragentModel>> getAllKontragenty();
}
