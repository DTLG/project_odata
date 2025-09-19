import 'package:dartz/dartz.dart';
import '../entities/nomenclature_entity.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/nomenclature_repository.dart';
import '../../../../core/usecases/usecase.dart';

/// Параметри для пошуку номенклатури за артикулом
class SearchNomenclatureByArticleParams {
  final String article;

  SearchNomenclatureByArticleParams(this.article);
}

/// Use case для пошуку номенклатури за артикулом
class SearchNomenclatureByArticleUseCase
    implements
        UseCase<List<NomenclatureEntity>, SearchNomenclatureByArticleParams> {
  final NomenclatureRepository _repository;

  SearchNomenclatureByArticleUseCase(this._repository);

  @override
  Future<Either<Failure, List<NomenclatureEntity>>> call(
    SearchNomenclatureByArticleParams params,
  ) async {
    return await _repository.searchNomenclatureByArticle(params.article);
  }
}
