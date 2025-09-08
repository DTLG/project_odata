import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/inventory_document.dart';
import '../repositories/inventory_repository.dart';

/// Use case for getting all inventory documents
class GetInventoryDocuments
    implements UseCase<List<InventoryDocument>, NoParams> {
  final InventoryRepository repository;

  GetInventoryDocuments(this.repository);

  @override
  Future<Either<Failure, List<InventoryDocument>>> call(NoParams params) async {
    return await repository.getDocuments();
  }
}
