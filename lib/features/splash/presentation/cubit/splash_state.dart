part of 'splash_cubit.dart';

enum SplashStatus { initial, loading, success, error, askSchema }

class SplashState extends Equatable {
  final SplashStatus status;
  final String message;
  final int current;
  final int total;
  final bool hasAgent;
  final bool needsUpdate;
  final String? remoteVersion;

  const SplashState({
    this.status = SplashStatus.initial,
    this.message = '',
    this.current = 0,
    this.total = 0,
    this.hasAgent = false,
    this.needsUpdate = false,
    this.remoteVersion,
  });

  SplashState copyWith({
    SplashStatus? status,
    String? message,
    int? current,
    int? total,
    bool? hasAgent,
    bool? needsUpdate,
    String? remoteVersion,
  }) {
    return SplashState(
      status: status ?? this.status,
      message: message ?? this.message,
      current: current ?? this.current,
      total: total ?? this.total,
      hasAgent: hasAgent ?? this.hasAgent,
      needsUpdate: needsUpdate ?? this.needsUpdate,
      remoteVersion: remoteVersion ?? this.remoteVersion,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    current,
    total,
    hasAgent,
    needsUpdate,
    remoteVersion,
  ];
}
