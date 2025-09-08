import 'package:dartz/dartz.dart';
import '../../errors/failures.dart';
import '../../repositories/nomenclature_repository.dart';
import '../usecase.dart';
import '../../entities/nomenclature_entity.dart';

class SearchNomenclatureByBarcodeParams {
  final String barcode;
  const SearchNomenclatureByBarcodeParams(this.barcode);
}

class SearchNomenclatureByBarcodeUseCase
    implements UseCase<NomenclatureEntity?, SearchNomenclatureByBarcodeParams> {
  final NomenclatureRepository repository;
  SearchNomenclatureByBarcodeUseCase(this.repository);

  @override
  Future<Either<Failure, NomenclatureEntity?>> call(
    SearchNomenclatureByBarcodeParams params,
  ) {
    return repository.searchNomenclatureByBarcode(params.barcode);
  }
}
