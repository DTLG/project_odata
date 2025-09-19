import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../nomenclature/domain/entities/nomenclature_entity.dart';
import '../repositories/customer_order_repository.dart';

/// Use case for getting available nomenclature
class GetAvailableNomenclatureUseCase
    implements UseCase<List<NomenclatureEntity>, NoParams> {
  final CustomerOrderRepository repository;

  GetAvailableNomenclatureUseCase(this.repository);

  @override
  Future<Either<Failure, List<NomenclatureEntity>>> call(
    NoParams params,
  ) async {
    return await repository.getAvailableNomenclature();
  }
}
