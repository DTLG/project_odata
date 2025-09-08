import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/inventory_repository.dart';

/// Use case for closing an inventory document
class CloseDocument implements UseCase<bool, String> {
  final InventoryRepository repository;

  CloseDocument(this.repository);

  @override
  Future<Either<Failure, bool>> call(String documentId) async {
    return await repository.closeDocument(documentId);
  }
}
