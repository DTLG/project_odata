import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/kontragent_entity.dart';
import '../repositories/kontragent_repository.dart';

/// Use case for getting kontragenty from local storage
class GetLocalKontragentyUseCase
    implements UseCase<List<KontragentEntity>, NoParams> {
  final KontragentRepository repository;

  GetLocalKontragentyUseCase(this.repository);

  @override
  Future<Either<Failure, List<KontragentEntity>>> call(NoParams params) async {
    return await repository.getLocalKontragenty();
  }
}
