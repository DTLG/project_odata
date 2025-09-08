import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../kontragenty/domain/entities/kontragent_entity.dart';
import '../repositories/customer_order_repository.dart';

/// Use case for getting available customers
class GetAvailableCustomersUseCase
    implements UseCase<List<KontragentEntity>, NoParams> {
  final CustomerOrderRepository repository;

  GetAvailableCustomersUseCase(this.repository);

  @override
  Future<Either<Failure, List<KontragentEntity>>> call(NoParams params) async {
    return await repository.getAvailableCustomers();
  }
}
