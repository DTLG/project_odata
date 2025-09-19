import 'package:dartz/dartz.dart';
import '../entities/nomenclature_entity.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/nomenclature_repository.dart';
import '../../../../core/usecases/usecase.dart';

/// Use case для отримання номенклатури з локальної бази
class GetLocalNomenclatureUseCase
    implements UseCase<List<NomenclatureEntity>, NoParams> {
  final NomenclatureRepository _repository;

  GetLocalNomenclatureUseCase(this._repository);

  @override
  Future<Either<Failure, List<NomenclatureEntity>>> call(
    NoParams params,
  ) async {
    return await _repository.getLocalNomenclature();
  }
}
