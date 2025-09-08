import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../kontragenty/domain/entities/kontragent_entity.dart';
import '../repositories/customer_order_repository.dart';

/// Use case for searching customers by name
class SearchCustomersUseCase
    implements UseCase<List<KontragentEntity>, String> {
  final CustomerOrderRepository repository;

  SearchCustomersUseCase(this.repository);

  @override
  Future<Either<Failure, List<KontragentEntity>>> call(String query) async {
    return await repository.searchCustomersByName(query);
  }
}
