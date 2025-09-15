import '../../domain/entities/customer_order_entity.dart';

abstract class OrdersRepository {
  Future<void> saveLocalOrder(CustomerOrderEntity order);
  Future<List<CustomerOrderEntity>> getLocalOrders();
  Future<void> deleteLocalOrder(String id);
  Future<void> clearLocalOrders();
}
