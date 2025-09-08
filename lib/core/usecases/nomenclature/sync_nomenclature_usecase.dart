import 'package:dartz/dartz.dart';
import '../../entities/nomenclature_entity.dart';
import '../../errors/failures.dart';
import '../../repositories/nomenclature_repository.dart';
import '../usecase.dart';

/// Use case для синхронізації номенклатури з сервером
class SyncNomenclatureUseCase
    implements UseCase<List<NomenclatureEntity>, NoParams> {
  final NomenclatureRepository _repository;

  SyncNomenclatureUseCase(this._repository);

  @override
  Future<Either<Failure, List<NomenclatureEntity>>> call(
    NoParams params,
  ) async {
    return await _repository.syncNomenclature();
  }
}
