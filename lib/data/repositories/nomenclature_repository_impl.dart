import 'package:dartz/dartz.dart';
import '../../core/entities/nomenclature_entity.dart';
import '../../core/errors/failures.dart';
import '../../core/repositories/nomenclature_repository.dart';
import '../datasources/local/sqflite_nomenclature_datasource.dart';
import '../datasources/remote/supabase_nomenclature_datasource.dart';
import '../models/nomenclature_model.dart';

/// Конкретна реалізація репозиторію номенклатури
/// Дотримується принципу Single Responsibility та Dependency Inversion (SOLID)
class NomenclatureRepositoryImpl implements NomenclatureRepository {
  final SupabaseNomenclatureDatasource _remoteDatasource;
  final SqliteNomenclatureDatasource _localDatasource;

  NomenclatureRepositoryImpl({
    required SupabaseNomenclatureDatasource remoteDatasource,
    required SqliteNomenclatureDatasource localDatasource,
  }) : _remoteDatasource = remoteDatasource,
       _localDatasource = localDatasource;

  @override
  Future<Either<Failure, List<NomenclatureEntity>>> syncNomenclature() async {
    try {
      // Отримуємо дані з віддаленого сервера
      final remoteNomenclatures = await _remoteDatasource.getAllNomenclature();

      // Очищуємо локальну базу
      await _localDatasource.clearAllNomenclature();

      // Зберігаємо нові дані локально
      await _localDatasource.insertNomenclature(remoteNomenclatures);

      // Повертаємо конвертовані entity
      final entities = remoteNomenclatures
          .map((model) => model.toEntity())
          .toList();

      return Right(entities);
    } catch (e) {
      if (e.toString().contains('Supabase') ||
          e.toString().contains('віддален')) {
        return Left(ServerFailure('Помилка синхронізації з сервером: $e'));
      } else {
        return Left(CacheFailure('Помилка збереження в локальну базу: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<NomenclatureEntity>>>
  getLocalNomenclature() async {
    try {
      final localNomenclatures = await _localDatasource.getAllNomenclature();
      final entities = localNomenclatures
          .map((model) => model.toEntity())
          .toList();

      return Right(entities);
    } catch (e) {
      return Left(
        CacheFailure('Помилка отримання номенклатури з локальної бази: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<NomenclatureEntity>>> searchNomenclatureByName(
    String name,
  ) async {
    try {
      if (name.trim().isEmpty) {
        return const Right([]);
      }

      final localNomenclatures = await _localDatasource
          .searchNomenclatureByName(name);
      final entities = localNomenclatures
          .map((model) => model.toEntity())
          .toList();

      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Помилка пошуку номенклатури за назвою: $e'));
    }
  }

  @override
  Future<Either<Failure, NomenclatureEntity?>> searchNomenclatureByArticle(
    String article,
  ) async {
    try {
      if (article.trim().isEmpty) {
        return const Right(null);
      }

      final localNomenclature = await _localDatasource.getNomenclatureByArticle(
        article,
      );
      final entity = localNomenclature?.toEntity();

      return Right(entity);
    } catch (e) {
      return Left(CacheFailure('Помилка пошуку номенклатури за артикулом: $e'));
    }
  }

  @override
  Future<Either<Failure, NomenclatureEntity?>> searchNomenclatureByBarcode(
    String barcode,
  ) async {
    try {
      if (barcode.trim().isEmpty) {
        return const Right(null);
      }

      final localNomenclature = await _localDatasource.getNomenclatureByBarcode(
        barcode,
      );
      final entity = localNomenclature?.toEntity();

      return Right(entity);
    } catch (e) {
      return Left(
        CacheFailure('Помилка пошуку номенклатури за штрихкодом: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, NomenclatureEntity?>> getNomenclatureByGuid(
    String guid,
  ) async {
    try {
      if (guid.trim().isEmpty) {
        return const Right(null);
      }

      final localNomenclature = await _localDatasource.getNomenclatureByGuid(
        guid,
      );
      final entity = localNomenclature?.toEntity();

      return Right(entity);
    } catch (e) {
      return Left(CacheFailure('Помилка отримання номенклатури за GUID: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearLocalNomenclature() async {
    try {
      await _localDatasource.clearAllNomenclature();
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Помилка очищення локальної бази номенклатури: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getLocalNomenclatureCount() async {
    try {
      final count = await _localDatasource.getNomenclatureCount();
      return Right(count);
    } catch (e) {
      return Left(
        CacheFailure('Помилка підрахунку номенклатури в локальній базі: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveLocalNomenclature(
    List<NomenclatureEntity> entities,
  ) async {
    try {
      final models = entities
          .map((entity) => NomenclatureModel.fromEntity(entity))
          .toList();
      await _localDatasource.insertNomenclature(models);
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Помилка збереження номенклатури в локальну базу: $e'),
      );
    }
  }
}
