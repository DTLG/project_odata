import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/entities/nomenclature_entity.dart';
import '../repositories/customer_order_repository.dart';

/// Use case for searching nomenclature by barcode
class SearchNomenclatureByBarcodeUseCase
    implements UseCase<NomenclatureEntity?, String> {
  final CustomerOrderRepository repository;

  SearchNomenclatureByBarcodeUseCase(this.repository);

  @override
  Future<Either<Failure, NomenclatureEntity?>> call(String barcode) async {
    return await repository.searchNomenclatureByBarcode(barcode);
  }
}
