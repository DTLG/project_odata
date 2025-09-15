part of 'repair_request_cubit.dart';

class RepairRequestState extends Equatable {
  final KontragentModel? customer;
  final String nomenclatureGuid;
  final String repairType;
  final String status;
  final String description;
  final double price;
  final List<dynamic> zapchastyny;
  final List<dynamic> diagnostyka;
  final List<dynamic> roboty;

  const RepairRequestState({
    this.customer,
    this.nomenclatureGuid = '',
    this.repairType = '',
    this.status = '',
    this.description = '',
    this.price = 0.0,
    this.zapchastyny = const [],
    this.diagnostyka = const [],
    this.roboty = const [],
  });

  RepairRequestState copyWith({
    KontragentModel? customer,
    String? nomenclatureGuid,
    String? repairType,
    String? status,
    String? description,
    double? price,
    List<dynamic>? zapchastyny,
    List<dynamic>? diagnostyka,
    List<dynamic>? roboty,
  }) {
    return RepairRequestState(
      customer: customer ?? this.customer,
      nomenclatureGuid: nomenclatureGuid ?? this.nomenclatureGuid,
      repairType: repairType ?? this.repairType,
      status: status ?? this.status,
      description: description ?? this.description,
      price: price ?? this.price,
      zapchastyny: zapchastyny ?? this.zapchastyny,
      diagnostyka: diagnostyka ?? this.diagnostyka,
      roboty: roboty ?? this.roboty,
    );
  }

  @override
  List<Object?> get props => [
    customer?.guid,
    nomenclatureGuid,
    repairType,
    status,
    description,
    price,
    zapchastyny,
    diagnostyka,
    roboty,
  ];
}
