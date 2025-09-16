import 'package:dartz/dartz.dart';
import '../entities/nomenclature_entity.dart';
import '../errors/failures.dart';

/// Абстрактний репозиторій для номенклатури
abstract class NomenclatureRepository {
  /// Отримати всю номенклатуру з віддаленого сервера та синхронізувати з локальною базою
  Future<Either<Failure, List<NomenclatureEntity>>> syncNomenclature();

  /// Отримати номенклатуру з локальної бази даних
  Future<Either<Failure, List<NomenclatureEntity>>> getLocalNomenclature();

  /// Пошук номенклатури за назвою в локальній базі
  Future<Either<Failure, List<NomenclatureEntity>>> searchNomenclatureByName(
    String name,
  );

  /// Пошук номенклатури за артикулом в локальній базі (повертає кілька записів)
  Future<Either<Failure, List<NomenclatureEntity>>> searchNomenclatureByArticle(
    String article,
  );

  /// Пошук номенклатури за штрихкодом в локальній базі
  Future<Either<Failure, NomenclatureEntity?>> searchNomenclatureByBarcode(
    String barcode,
  );

  /// Отримати номенклатуру за GUID
  Future<Either<Failure, NomenclatureEntity?>> getNomenclatureByGuid(
    String guid,
  );

  /// Очистити локальну базу номенклатури
  Future<Either<Failure, void>> clearLocalNomenclature();

  /// Отримати кількість записів в локальній базі
  Future<Either<Failure, int>> getLocalNomenclatureCount();

  /// Зберегти номенклатуру в локальну базу
  Future<Either<Failure, void>> saveLocalNomenclature(
    List<NomenclatureEntity> entities,
  );
}
