import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class SetSkuParams {
  final String documentId;
  final String barcode;

  SetSkuParams({required this.documentId, required this.barcode});
}

class SetSku implements UseCase<InventoryItem, SetSkuParams> {
  final InventoryRepository repository;

  SetSku(this.repository);

  @override
  Future<Either<Failure, InventoryItem>> call(SetSkuParams params) async {
    return repository.setSku(
      documentId: params.documentId,
      barcode: params.barcode,
    );
  }
}
