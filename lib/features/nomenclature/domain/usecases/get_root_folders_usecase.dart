import 'package:dartz/dartz.dart';
import '../entities/nomenclature_entity.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/nomenclature_repository.dart';
import '../../../../core/usecases/usecase.dart';

/// Use case для отримання корневих папок номенклатури
class GetRootFoldersUseCase
    implements UseCase<List<NomenclatureEntity>, NoParams> {
  final NomenclatureRepository _repository;

  GetRootFoldersUseCase(this._repository);

  @override
  Future<Either<Failure, List<NomenclatureEntity>>> call(
    NoParams params,
  ) async {
    return await _repository.getRootFolders();
  }
}
