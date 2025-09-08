import '../models/kontragent_model.dart';

/// Local data source interface for kontragent operations
abstract class KontragentLocalDataSource {
  /// Get all kontragenty from local storage
  Future<List<KontragentModel>> getAllKontragenty();

  /// Get kontragent by GUID
  Future<KontragentModel?> getKontragentByGuid(String guid);

  /// Search kontragenty by name
  Future<List<KontragentModel>> searchByName(String query);

  /// Search kontragenty by EDRPOU
  Future<List<KontragentModel>> searchByEdrpou(String query);

  /// Get root elements (folders and kontragenty with no parent)
  Future<List<KontragentModel>> getRootFolders();

  /// Get children by parent GUID
  Future<List<KontragentModel>> getChildren(String parentGuid);

  /// Insert kontragenty to local storage
  Future<void> insertKontragenty(List<KontragentModel> kontragenty);

  /// Clear all local data
  Future<void> clearAllData();

  /// Get kontragenty count
  Future<int> getKontragentyCount();

  /// Update kontragent
  Future<void> updateKontragent(KontragentModel kontragent);

  /// Delete kontragent
  Future<void> deleteKontragent(String guid);

  /// Debug database
  Future<Map<String, dynamic>> debugDatabase();

  /// Recreate database
  Future<void> recreateDatabase();
}
