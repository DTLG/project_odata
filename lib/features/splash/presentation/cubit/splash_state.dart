part of 'splash_cubit.dart';

enum SplashStatus { initial, loading, success, error, askSchema }

class SplashState extends Equatable {
  final SplashStatus status;
  final String message;
  final int current;
  final int total;

  const SplashState({
    this.status = SplashStatus.initial,
    this.message = '',
    this.current = 0,
    this.total = 0,
  });

  SplashState copyWith({
    SplashStatus? status,
    String? message,
    int? current,
    int? total,
  }) {
    return SplashState(
      status: status ?? this.status,
      message: message ?? this.message,
      current: current ?? this.current,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [status, message, current, total];
}
