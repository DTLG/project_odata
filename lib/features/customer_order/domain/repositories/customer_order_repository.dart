import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/customer_order_entity.dart';
import '../../../kontragenty/domain/entities/kontragent_entity.dart';
import '../../../../core/entities/nomenclature_entity.dart';

/// Repository interface for customer order operations
abstract class CustomerOrderRepository {
  /// Create a new customer order
  Future<Either<Failure, CustomerOrderEntity>> createOrder(
    CustomerOrderEntity order,
  );

  /// Update an existing customer order
  Future<Either<Failure, CustomerOrderEntity>> updateOrder(
    CustomerOrderEntity order,
  );

  /// Get order by ID
  Future<Either<Failure, CustomerOrderEntity?>> getOrderById(String id);

  /// Get all orders
  Future<Either<Failure, List<CustomerOrderEntity>>> getAllOrders();

  /// Get orders by customer
  Future<Either<Failure, List<CustomerOrderEntity>>> getOrdersByCustomer(
    String customerId,
  );

  /// Delete order
  Future<Either<Failure, bool>> deleteOrder(String id);

  /// Get available customers (kontragenty)
  Future<Either<Failure, List<KontragentEntity>>> getAvailableCustomers();

  /// Get available nomenclature items
  Future<Either<Failure, List<NomenclatureEntity>>> getAvailableNomenclature();

  /// Search customers by name
  Future<Either<Failure, List<KontragentEntity>>> searchCustomersByName(
    String query,
  );

  /// Search nomenclature by name
  Future<Either<Failure, List<NomenclatureEntity>>> searchNomenclatureByName(
    String query,
  );

  /// Search nomenclature by barcode
  Future<Either<Failure, NomenclatureEntity?>> searchNomenclatureByBarcode(
    String barcode,
  );
}
