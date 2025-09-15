import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/order_creation_service.dart';
import '../entities/customer_order_entity.dart';

/// Use case for creating a new customer order
class CreateOrderUseCase
    implements UseCase<CustomerOrderEntity, CustomerOrderEntity> {
  final OrderCreationService orderCreationService;

  CreateOrderUseCase(this.orderCreationService);

  @override
  Future<Either<Failure, CustomerOrderEntity>> call(
    CustomerOrderEntity order,
  ) async {
    try {
      // Supabase payload: tovaru = [{ nom_guid, count }]
      final List<Map<String, dynamic>> goodsList = order.items
          .map(
            (item) => {
              'nom_guid': item.nomenclature.guid,
              'count': item.quantity,
            },
          )
          .toList();

      await orderCreationService.createOrder(order.customerGuid, goodsList);

      // Return the created order
      return Right(order);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
