import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/customer_order_entity.dart';
import '../../domain/repositories/customer_order_repository.dart';
import '../../../kontragenty/domain/entities/kontragent_entity.dart';
import '../../../kontragenty/domain/repositories/kontragent_repository.dart';
import '../../../../core/entities/nomenclature_entity.dart';
import '../../../../core/repositories/nomenclature_repository.dart';

/// Implementation of customer order repository
class CustomerOrderRepositoryImpl implements CustomerOrderRepository {
  final KontragentRepository kontragentRepository;
  final NomenclatureRepository nomenclatureRepository;

  CustomerOrderRepositoryImpl({
    required this.kontragentRepository,
    required this.nomenclatureRepository,
  });

  @override
  Future<Either<Failure, CustomerOrderEntity>> createOrder(
    CustomerOrderEntity order,
  ) async {
    try {
      // TODO: Implement actual order creation logic
      // For now, return the order as is
      return Right(order);
    } catch (e) {
      return Left(ServerFailure('Failed to create order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerOrderEntity>> updateOrder(
    CustomerOrderEntity order,
  ) async {
    try {
      // TODO: Implement actual order update logic
      // For now, return the order as is
      return Right(order);
    } catch (e) {
      return Left(ServerFailure('Failed to update order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerOrderEntity?>> getOrderById(String id) async {
    try {
      // TODO: Implement actual order retrieval logic
      // For now, return null
      return Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to get order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CustomerOrderEntity>>> getAllOrders() async {
    try {
      // TODO: Implement actual orders retrieval logic
      // For now, return empty list
      return Right([]);
    } catch (e) {
      return Left(ServerFailure('Failed to get orders: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CustomerOrderEntity>>> getOrdersByCustomer(
    String customerId,
  ) async {
    try {
      // TODO: Implement actual orders retrieval logic
      // For now, return empty list
      return Right([]);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get orders by customer: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> deleteOrder(String id) async {
    try {
      // TODO: Implement actual order deletion logic
      // For now, return true
      return Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to delete order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<KontragentEntity>>>
  getAvailableCustomers() async {
    try {
      final result = await kontragentRepository.getLocalKontragenty();
      return result.fold(
        (failure) => Left(failure),
        (kontragenty) => Right(kontragenty),
      );
    } catch (e) {
      return Left(
        ServerFailure('Failed to get available customers: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<NomenclatureEntity>>>
  getAvailableNomenclature() async {
    try {
      final result = await nomenclatureRepository.getLocalNomenclature();
      return result.fold(
        (failure) => Left(failure),
        (nomenclature) => Right(nomenclature),
      );
    } catch (e) {
      return Left(
        ServerFailure('Failed to get available nomenclature: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<KontragentEntity>>> searchCustomersByName(
    String query,
  ) async {
    try {
      final result = await kontragentRepository.searchByName(query);
      return result.fold(
        (failure) => Left(failure),
        (kontragenty) => Right(kontragenty),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to search customers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<NomenclatureEntity>>> searchNomenclatureByName(
    String query,
  ) async {
    try {
      final result = await nomenclatureRepository.searchNomenclatureByName(
        query,
      );
      return result.fold(
        (failure) => Left(failure),
        (nomenclature) => Right(nomenclature),
      );
    } catch (e) {
      return Left(
        ServerFailure('Failed to search nomenclature: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, NomenclatureEntity?>> searchNomenclatureByBarcode(
    String barcode,
  ) async {
    try {
      final result = await nomenclatureRepository.searchNomenclatureByBarcode(
        barcode,
      );
      return result.fold(
        (failure) => Left(failure),
        (nomenclature) => Right(nomenclature),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          'Failed to search nomenclature by barcode: ${e.toString()}',
        ),
      );
    }
  }
}
