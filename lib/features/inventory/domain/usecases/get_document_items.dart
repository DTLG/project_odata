import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

/// Use case for getting items of a specific document
class GetDocumentItems implements UseCase<List<InventoryItem>, String> {
  final InventoryRepository repository;

  GetDocumentItems(this.repository);

  @override
  Future<Either<Failure, List<InventoryItem>>> call(String documentId) async {
    return await repository.getDocumentItems(documentId);
  }
}
