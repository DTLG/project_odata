import 'package:dartz/dartz.dart';
import '../../entities/nomenclature_entity.dart';
import '../../errors/failures.dart';
import '../../repositories/nomenclature_repository.dart';
import '../usecase.dart';

/// Параметри для пошуку номенклатури за артикулом
class SearchNomenclatureByArticleParams {
  final String article;

  SearchNomenclatureByArticleParams(this.article);
}

/// Use case для пошуку номенклатури за артикулом
class SearchNomenclatureByArticleUseCase
    implements UseCase<NomenclatureEntity?, SearchNomenclatureByArticleParams> {
  final NomenclatureRepository _repository;

  SearchNomenclatureByArticleUseCase(this._repository);

  @override
  Future<Either<Failure, NomenclatureEntity?>> call(
    SearchNomenclatureByArticleParams params,
  ) async {
    return await _repository.searchNomenclatureByArticle(params.article);
  }
}
