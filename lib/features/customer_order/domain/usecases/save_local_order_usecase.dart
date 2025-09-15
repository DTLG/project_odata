import '../repositories/orders_repository.dart';
import '../../domain/entities/customer_order_entity.dart';

class SaveLocalOrderUseCase {
  final OrdersRepository repo;
  SaveLocalOrderUseCase(this.repo);
  Future<void> call(CustomerOrderEntity order) => repo.saveLocalOrder(order);
}
