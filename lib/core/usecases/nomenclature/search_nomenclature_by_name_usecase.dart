import 'package:dartz/dartz.dart';
import '../../entities/nomenclature_entity.dart';
import '../../errors/failures.dart';
import '../../repositories/nomenclature_repository.dart';
import '../usecase.dart';

/// Параметри для пошуку номенклатури за назвою
class SearchNomenclatureByNameParams {
  final String name;

  SearchNomenclatureByNameParams(this.name);
}

/// Use case для пошуку номенклатури за назвою
class SearchNomenclatureByNameUseCase
    implements
        UseCase<List<NomenclatureEntity>, SearchNomenclatureByNameParams> {
  final NomenclatureRepository _repository;

  SearchNomenclatureByNameUseCase(this._repository);

  @override
  Future<Either<Failure, List<NomenclatureEntity>>> call(
    SearchNomenclatureByNameParams params,
  ) async {
    return await _repository.searchNomenclatureByName(params.name);
  }
}
