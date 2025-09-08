import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

/// Parameters for adding or updating an inventory item
class AddOrUpdateItemParams {
  final String documentId;
  final String nomenclatureId;
  final double count;

  AddOrUpdateItemParams({
    required this.documentId,
    required this.nomenclatureId,
    required this.count,
  });
}

/// Use case for adding or updating an inventory item
class AddOrUpdateItem implements UseCase<InventoryItem, AddOrUpdateItemParams> {
  final InventoryRepository repository;

  AddOrUpdateItem(this.repository);

  @override
  Future<Either<Failure, InventoryItem>> call(
    AddOrUpdateItemParams params,
  ) async {
    return await repository.addOrUpdateItem(
      documentId: params.documentId,
      nomenclatureId: params.nomenclatureId,
      count: params.count,
    );
  }
}
