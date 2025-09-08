import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Базовий абстрактний клас для всіх use cases
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Клас для use cases без параметрів
class NoParams {
  const NoParams();
}
