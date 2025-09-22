import '../../models/nomenclature_model.dart';

/// Абстрактний інтерфейс для локального джерела даних номенклатури
abstract class NomenclatureLocalDatasource {
  Future<List<NomenclatureModel>> getAllNomenclature();
  Future<List<NomenclatureModel>> getRootFolders();
  Future<NomenclatureModel?> getNomenclatureByGuid(String guid);
  Future<List<NomenclatureModel>?> getNomenclatureByArticle(String article);
  Future<NomenclatureModel?> getNomenclatureByBarcode(String barcode);
  Future<List<NomenclatureModel>> searchNomenclatureByName(String name);
  Future<void> insertNomenclature(List<NomenclatureModel> nomenclatures);
  Future<void> clearAllNomenclature();
  Future<int> getNomenclatureCount();
  Future<void> updateNomenclature(NomenclatureModel nomenclature);
  Future<void> deleteNomenclature(String guid);
  Future<Map<String, dynamic>> debugDatabase();
  Future<void> recreateDatabase();
}
