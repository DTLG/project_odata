import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/inventory_document.dart';
import '../repositories/inventory_repository.dart';

/// Use case for creating a new inventory document
class CreateInventoryDocument implements UseCase<InventoryDocument, NoParams> {
  final InventoryRepository repository;

  CreateInventoryDocument(this.repository);

  @override
  Future<Either<Failure, InventoryDocument>> call(NoParams params) async {
    return await repository.createDocument();
  }
}
