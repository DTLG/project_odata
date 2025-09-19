import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/nomenclature_repository.dart';
import '../../../../core/usecases/usecase.dart';

/// Use case для отримання кількості номенклатури в локальній базі
class GetNomenclatureCountUseCase implements UseCase<int, NoParams> {
  final NomenclatureRepository _repository;

  GetNomenclatureCountUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await _repository.getLocalNomenclatureCount();
  }
}
