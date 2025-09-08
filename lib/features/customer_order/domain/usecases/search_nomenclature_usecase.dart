import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/entities/nomenclature_entity.dart';
import '../repositories/customer_order_repository.dart';

/// Use case for searching nomenclature by name
class SearchNomenclatureUseCase
    implements UseCase<List<NomenclatureEntity>, String> {
  final CustomerOrderRepository repository;

  SearchNomenclatureUseCase(this.repository);

  @override
  Future<Either<Failure, List<NomenclatureEntity>>> call(String query) async {
    return await repository.searchNomenclatureByName(query);
  }
}
