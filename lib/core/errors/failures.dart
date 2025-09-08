abstract class Failure {
  final String message;
  final String? code;
  
  const Failure(this.message, [this.code]);
  
  @override
  String toString() => 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
}

class ServerFailure extends Failure {
  const ServerFailure(String message, [String? code]) : super(message, code);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, [String? code]) : super(message, code);
}

class CacheFailure extends Failure {
  const CacheFailure(String message, [String? code]) : super(message, code);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, [String? code]) : super(message, code);
}

class AuthFailure extends Failure {
  const AuthFailure(String message, [String? code]) : super(message, code);
}
