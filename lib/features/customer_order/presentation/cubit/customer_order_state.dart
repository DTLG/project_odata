part of 'customer_order_cubit.dart';

/// Base state for customer order
abstract class CustomerOrderState extends Equatable {
  const CustomerOrderState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CustomerOrderInitial extends CustomerOrderState {}

/// Initialized state with all data loaded
class CustomerOrderInitialized extends CustomerOrderState {
  final List<KontragentEntity> customers;
  final List<NomenclatureEntity> nomenclature;

  const CustomerOrderInitialized({
    required this.customers,
    required this.nomenclature,
  });

  @override
  List<Object?> get props => [customers, nomenclature];
}

/// Loading state
class CustomerOrderLoading extends CustomerOrderState {}

/// Error state
class CustomerOrderError extends CustomerOrderState {
  final String message;

  const CustomerOrderError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Customers loaded state
class CustomersLoaded extends CustomerOrderState {
  final List<KontragentEntity> customers;

  const CustomersLoaded(this.customers);

  @override
  List<Object?> get props => [customers];
}

/// Nomenclature loaded state
class NomenclatureLoaded extends CustomerOrderState {
  final List<NomenclatureEntity> nomenclature;

  const NomenclatureLoaded(this.nomenclature);

  @override
  List<Object?> get props => [nomenclature];
}

/// Nomenclature found by barcode state
class NomenclatureFound extends CustomerOrderState {
  final NomenclatureEntity nomenclature;

  const NomenclatureFound(this.nomenclature);

  @override
  List<Object?> get props => [nomenclature];
}

/// Customer order loaded state
class CustomerOrderLoaded extends CustomerOrderState {
  final KontragentEntity? selectedCustomer;
  final List<OrderItemEntity> orderItems;
  final double totalAmount;

  const CustomerOrderLoaded({
    this.selectedCustomer,
    required this.orderItems,
    required this.totalAmount,
  });

  CustomerOrderLoaded copyWith({
    KontragentEntity? selectedCustomer,
    List<OrderItemEntity>? orderItems,
    double? totalAmount,
  }) {
    return CustomerOrderLoaded(
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      orderItems: orderItems ?? this.orderItems,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  @override
  List<Object?> get props => [selectedCustomer, orderItems, totalAmount];
}

/// Customer order with nomenclature loaded state
class CustomerOrderWithNomenclatureLoaded extends CustomerOrderInitialized {
  final KontragentEntity? selectedCustomer;
  final List<OrderItemEntity> orderItems;
  final double totalAmount;

  CustomerOrderWithNomenclatureLoaded({
    this.selectedCustomer,
    required this.orderItems,
    required this.totalAmount,
    List<KontragentEntity> customers = const [],
    List<NomenclatureEntity> nomenclature = const [],
  }) : super(customers: customers, nomenclature: nomenclature);

  CustomerOrderWithNomenclatureLoaded copyWith({
    KontragentEntity? selectedCustomer,
    List<OrderItemEntity>? orderItems,
    double? totalAmount,
    List<KontragentEntity>? customers,
    List<NomenclatureEntity>? nomenclature,
  }) {
    return CustomerOrderWithNomenclatureLoaded(
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      orderItems: orderItems ?? this.orderItems,
      totalAmount: totalAmount ?? this.totalAmount,
      customers: customers ?? this.customers,
      nomenclature: nomenclature ?? this.nomenclature,
    );
  }

  @override
  List<Object?> get props => [
    selectedCustomer,
    orderItems,
    totalAmount,
    customers,
    nomenclature,
  ];
}

/// Order created state
class OrderCreated extends CustomerOrderState {
  final CustomerOrderEntity order;

  const OrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}
