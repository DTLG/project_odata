import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/kontragent_repository.dart';

/// Use case for getting kontragenty count
class GetKontragentyCountUseCase implements UseCase<int, NoParams> {
  final KontragentRepository repository;

  GetKontragentyCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.getKontragentyCount();
  }
}
