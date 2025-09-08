import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/kontragent_repository.dart';

/// Use case for clearing local data
class ClearLocalDataUseCase implements UseCase<bool, NoParams> {
  final KontragentRepository repository;

  ClearLocalDataUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.clearLocalData();
  }
}
