import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/kontragent_entity.dart';
import '../repositories/kontragent_repository.dart';

/// Use case for getting children by parent GUID
class GetChildrenUseCase implements UseCase<List<KontragentEntity>, String> {
  final KontragentRepository repository;

  GetChildrenUseCase(this.repository);

  @override
  Future<Either<Failure, List<KontragentEntity>>> call(
    String parentGuid,
  ) async {
    return await repository.getChildren(parentGuid);
  }
}
