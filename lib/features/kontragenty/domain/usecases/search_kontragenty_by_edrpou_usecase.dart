import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/kontragent_entity.dart';
import '../repositories/kontragent_repository.dart';

/// Use case for searching kontragenty by EDRPOU
class SearchKontragentyByEdrpouUseCase
    implements UseCase<List<KontragentEntity>, String> {
  final KontragentRepository repository;

  SearchKontragentyByEdrpouUseCase(this.repository);

  @override
  Future<Either<Failure, List<KontragentEntity>>> call(String query) async {
    return await repository.searchByEdrpou(query);
  }
}
