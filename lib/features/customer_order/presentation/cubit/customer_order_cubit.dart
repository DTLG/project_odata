import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/customer_order_entity.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/get_available_customers_usecase.dart';
import '../../domain/usecases/get_available_nomenclature_usecase.dart';
import '../../domain/usecases/search_customers_usecase.dart';
import '../../domain/usecases/search_nomenclature_usecase.dart';
import '../../domain/usecases/search_nomenclature_by_barcode_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../kontragenty/domain/entities/kontragent_entity.dart';
import '../../../../core/entities/nomenclature_entity.dart';

part 'customer_order_state.dart';

/// Cubit for managing customer order state
class CustomerOrderCubit extends Cubit<CustomerOrderState> {
  final CreateOrderUseCase createOrderUseCase;
  final GetAvailableCustomersUseCase getAvailableCustomersUseCase;
  final GetAvailableNomenclatureUseCase getAvailableNomenclatureUseCase;
  final SearchCustomersUseCase searchCustomersUseCase;
  final SearchNomenclatureUseCase searchNomenclatureUseCase;
  final SearchNomenclatureByBarcodeUseCase searchNomenclatureByBarcodeUseCase;

  // Cache for loaded data
  List<KontragentEntity>? _cachedCustomers;
  List<NomenclatureEntity>? _cachedNomenclature;
  bool _isInitialized = false;

  CustomerOrderCubit({
    required this.createOrderUseCase,
    required this.getAvailableCustomersUseCase,
    required this.getAvailableNomenclatureUseCase,
    required this.searchCustomersUseCase,
    required this.searchNomenclatureUseCase,
    required this.searchNomenclatureByBarcodeUseCase,
  }) : super(CustomerOrderInitial());

  /// Initialize the cubit by loading all necessary data
  Future<void> initialize() async {
    if (_isInitialized) return;

    emit(CustomerOrderLoading());

    try {
      // Load customers and nomenclature in parallel
      final customersResult = await getAvailableCustomersUseCase(NoParams());
      final nomenclatureResult = await getAvailableNomenclatureUseCase(
        NoParams(),
      );

      customersResult.fold(
        (failure) => emit(CustomerOrderError(failure.message)),
        (customers) {
          _cachedCustomers = customers;
          nomenclatureResult.fold(
            (failure) => emit(CustomerOrderError(failure.message)),
            (nomenclature) {
              _cachedNomenclature = nomenclature;
              _isInitialized = true;
              emit(
                CustomerOrderInitialized(
                  customers: customers,
                  nomenclature: nomenclature,
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      emit(CustomerOrderError('Помилка ініціалізації: ${e.toString()}'));
    }
  }

  /// Load available customers
  Future<void> loadAvailableCustomers() async {
    // If we already have cached customers, just update the current state shape
    if (_cachedCustomers != null) {
      final customers = _cachedCustomers!;
      if (state is CustomerOrderWithNomenclatureLoaded) {
        final current = state as CustomerOrderWithNomenclatureLoaded;
        emit(current.copyWith(customers: customers));
      } else if (state is CustomerOrderInitialized) {
        final current = state as CustomerOrderInitialized;
        emit(
          CustomerOrderInitialized(
            customers: customers,
            nomenclature: current.nomenclature,
          ),
        );
      } else if (state is CustomerOrderLoaded) {
        final current = state as CustomerOrderLoaded;
        emit(
          CustomerOrderWithNomenclatureLoaded(
            selectedCustomer: current.selectedCustomer,
            orderItems: current.orderItems,
            totalAmount: current.totalAmount,
            customers: customers,
            nomenclature: _cachedNomenclature ?? const <NomenclatureEntity>[],
          ),
        );
      } else {
        emit(CustomersLoaded(customers));
      }
      return;
    }

    emit(CustomerOrderLoading());

    final result = await getAvailableCustomersUseCase(NoParams());

    result.fold((failure) => emit(CustomerOrderError(failure.message)), (
      customers,
    ) {
      _cachedCustomers = customers;
      if (state is CustomerOrderWithNomenclatureLoaded) {
        final current = state as CustomerOrderWithNomenclatureLoaded;
        emit(current.copyWith(customers: customers));
      } else if (state is CustomerOrderInitialized) {
        final current = state as CustomerOrderInitialized;
        emit(
          CustomerOrderInitialized(
            customers: customers,
            nomenclature: current.nomenclature,
          ),
        );
      } else if (state is CustomerOrderLoaded) {
        final current = state as CustomerOrderLoaded;
        emit(
          CustomerOrderWithNomenclatureLoaded(
            selectedCustomer: current.selectedCustomer,
            orderItems: current.orderItems,
            totalAmount: current.totalAmount,
            customers: customers,
            nomenclature: _cachedNomenclature ?? const <NomenclatureEntity>[],
          ),
        );
      } else {
        emit(CustomersLoaded(customers));
      }
    });
  }

  /// Search customers by name
  Future<void> searchCustomers(String query) async {
    // Empty query -> restore full list without changing current state type
    if (query.isEmpty) {
      if (_cachedCustomers != null) {
        final customers = _cachedCustomers!;
        if (state is CustomerOrderWithNomenclatureLoaded) {
          final current = state as CustomerOrderWithNomenclatureLoaded;
          emit(current.copyWith(customers: customers));
        } else if (state is CustomerOrderInitialized) {
          final current = state as CustomerOrderInitialized;
          emit(
            CustomerOrderInitialized(
              customers: customers,
              nomenclature: current.nomenclature,
            ),
          );
        } else if (state is CustomerOrderLoaded) {
          final current = state as CustomerOrderLoaded;
          emit(
            CustomerOrderWithNomenclatureLoaded(
              selectedCustomer: current.selectedCustomer,
              orderItems: current.orderItems,
              totalAmount: current.totalAmount,
              customers: customers,
              nomenclature: _cachedNomenclature ?? const <NomenclatureEntity>[],
            ),
          );
        } else {
          emit(CustomersLoaded(customers));
        }
      } else {
        await loadAvailableCustomers();
      }
      return;
    }

    // If we have cached customers, filter them locally and preserve state
    if (_cachedCustomers != null) {
      final filteredCustomers = _cachedCustomers!
          .where(
            (customer) =>
                customer.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      if (state is CustomerOrderWithNomenclatureLoaded) {
        final current = state as CustomerOrderWithNomenclatureLoaded;
        emit(current.copyWith(customers: filteredCustomers));
      } else if (state is CustomerOrderInitialized) {
        final current = state as CustomerOrderInitialized;
        emit(
          CustomerOrderInitialized(
            customers: filteredCustomers,
            nomenclature: current.nomenclature,
          ),
        );
      } else if (state is CustomerOrderLoaded) {
        // Promote to combined state to preserve order while showing filtered customers
        final current = state as CustomerOrderLoaded;
        emit(
          CustomerOrderWithNomenclatureLoaded(
            selectedCustomer: current.selectedCustomer,
            orderItems: current.orderItems,
            totalAmount: current.totalAmount,
            customers: filteredCustomers,
            nomenclature: _cachedNomenclature ?? const <NomenclatureEntity>[],
          ),
        );
      } else {
        emit(CustomersLoaded(filteredCustomers));
      }
      return;
    }

    // Fallback to API search but still preserve state shape on success
    emit(CustomerOrderLoading());

    final result = await searchCustomersUseCase(query);

    result.fold((failure) => emit(CustomerOrderError(failure.message)), (
      customers,
    ) {
      if (state is CustomerOrderWithNomenclatureLoaded) {
        final current = state as CustomerOrderWithNomenclatureLoaded;
        emit(current.copyWith(customers: customers));
      } else if (state is CustomerOrderInitialized) {
        final current = state as CustomerOrderInitialized;
        emit(
          CustomerOrderInitialized(
            customers: customers,
            nomenclature: current.nomenclature,
          ),
        );
      } else if (state is CustomerOrderLoaded) {
        final current = state as CustomerOrderLoaded;
        emit(
          CustomerOrderWithNomenclatureLoaded(
            selectedCustomer: current.selectedCustomer,
            orderItems: current.orderItems,
            totalAmount: current.totalAmount,
            customers: customers,
            nomenclature: _cachedNomenclature ?? const <NomenclatureEntity>[],
          ),
        );
      } else {
        emit(CustomersLoaded(customers));
      }
    });
  }

  /// Load available nomenclature
  Future<void> loadAvailableNomenclature() async {
    // If we already have a customer order state, preserve it
    if (state is CustomerOrderLoaded) {
      final currentState = state as CustomerOrderLoaded;

      if (_cachedNomenclature != null) {
        emit(
          CustomerOrderWithNomenclatureLoaded(
            selectedCustomer: currentState.selectedCustomer,
            orderItems: currentState.orderItems,
            totalAmount: currentState.totalAmount,
            nomenclature: _cachedNomenclature!,
          ),
        );
        return;
      }

      emit(CustomerOrderLoading());

      final result = await getAvailableNomenclatureUseCase(NoParams());

      result.fold((failure) => emit(CustomerOrderError(failure.message)), (
        nomenclature,
      ) {
        _cachedNomenclature = nomenclature;
        emit(
          CustomerOrderWithNomenclatureLoaded(
            selectedCustomer: currentState.selectedCustomer,
            orderItems: currentState.orderItems,
            totalAmount: currentState.totalAmount,
            nomenclature: nomenclature,
          ),
        );
      });
    } else if (state is CustomerOrderWithNomenclatureLoaded) {
      final currentState = state as CustomerOrderWithNomenclatureLoaded;

      if (_cachedNomenclature != null) {
        emit(currentState.copyWith(nomenclature: _cachedNomenclature!));
        return;
        // emit(
        //   CustomerOrderWithNomenclatureLoaded(
        //     selectedCustomer: currentState.selectedCustomer,
        //     orderItems: currentState.orderItems,
        //     totalAmount: currentState.totalAmount,
        //     nomenclature: _cachedNomenclature!,
        //   ),
        // );
        // return;
      }

      emit(CustomerOrderLoading());

      final result = await getAvailableNomenclatureUseCase(NoParams());

      result.fold((failure) => emit(CustomerOrderError(failure.message)), (
        nomenclature,
      ) {
        _cachedNomenclature = nomenclature;
        emit(
          CustomerOrderWithNomenclatureLoaded(
            selectedCustomer: currentState.selectedCustomer,
            orderItems: currentState.orderItems,
            totalAmount: currentState.totalAmount,
            nomenclature: nomenclature,
          ),
        );
      });
    } else {
      // Initial load without explicit customer-state
      if (_cachedNomenclature != null) {
        if (_cachedCustomers != null) {
          emit(
            CustomerOrderInitialized(
              customers: _cachedCustomers!,
              nomenclature: _cachedNomenclature!,
            ),
          );
        } else {
          emit(NomenclatureLoaded(_cachedNomenclature!));
        }
        return;
      }

      emit(CustomerOrderLoading());

      final result = await getAvailableNomenclatureUseCase(NoParams());

      result.fold((failure) => emit(CustomerOrderError(failure.message)), (
        nomenclature,
      ) {
        _cachedNomenclature = nomenclature;
        if (_cachedCustomers != null) {
          emit(
            CustomerOrderInitialized(
              customers: _cachedCustomers!,
              nomenclature: nomenclature,
            ),
          );
        } else {
          emit(NomenclatureLoaded(nomenclature));
        }
      });
    }
  }

  /// Search nomenclature by name
  Future<void> searchNomenclature(String query) async {
    if (query.isEmpty) {
      loadAvailableNomenclature();
      return;
    }

    // If we have cached nomenclature, filter it locally
    if (_cachedNomenclature != null) {
      final filteredNomenclature = _cachedNomenclature!
          .where(
            (item) =>
                item.name.toLowerCase().contains(query.toLowerCase()) ||
                item.article.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      // Preserve customer order state if it exists
      if (state is CustomerOrderLoaded) {
        final currentState = state as CustomerOrderLoaded;
        emit(
          CustomerOrderWithNomenclatureLoaded(
            selectedCustomer: currentState.selectedCustomer,
            orderItems: currentState.orderItems,
            totalAmount: currentState.totalAmount,
            nomenclature: filteredNomenclature,
          ),
        );
      } else if (state is CustomerOrderWithNomenclatureLoaded) {
        final currentState = state as CustomerOrderWithNomenclatureLoaded;
        emit(currentState.copyWith(nomenclature: filteredNomenclature));
      } else {
        emit(NomenclatureLoaded(filteredNomenclature));
      }
      return;
    }

    // Fallback to API search if no cache
    // Preserve customer order state if it exists
    if (state is CustomerOrderLoaded) {
      final currentState = state as CustomerOrderLoaded;
      emit(CustomerOrderLoading());

      final result = await searchNomenclatureUseCase(query);

      result.fold(
        (failure) => emit(CustomerOrderError(failure.message)),
        (nomenclature) => emit(
          CustomerOrderWithNomenclatureLoaded(
            selectedCustomer: currentState.selectedCustomer,
            orderItems: currentState.orderItems,
            totalAmount: currentState.totalAmount,
            nomenclature: nomenclature,
          ),
        ),
      );
    } else if (state is CustomerOrderWithNomenclatureLoaded) {
      final currentState = state as CustomerOrderWithNomenclatureLoaded;
      emit(CustomerOrderLoading());

      final result = await searchNomenclatureUseCase(query);

      result.fold(
        (failure) => emit(CustomerOrderError(failure.message)),
        (nomenclature) =>
            emit(currentState.copyWith(nomenclature: nomenclature)),
      );
    } else {
      // Initial search without customer
      emit(CustomerOrderLoading());

      final result = await searchNomenclatureUseCase(query);

      result.fold(
        (failure) => emit(CustomerOrderError(failure.message)),
        (nomenclature) => emit(NomenclatureLoaded(nomenclature)),
      );
    }
  }

  /// Search nomenclature by barcode
  Future<void> searchNomenclatureByBarcode(String barcode) async {
    // If we have cached nomenclature, search it locally first
    if (_cachedNomenclature != null) {
      final foundItem = _cachedNomenclature!.firstWhere(
        (item) => item.barcodes.any(
          (barcodeEntity) => barcodeEntity.barcode == barcode,
        ),
        orElse: () => throw StateError('Not found'),
      );

      // If we have a customer order state, preserve it
      if (state is CustomerOrderLoaded) {
        final currentState = state as CustomerOrderLoaded;
        emit(
          CustomerOrderWithNomenclatureLoaded(
            selectedCustomer: currentState.selectedCustomer,
            orderItems: currentState.orderItems,
            totalAmount: currentState.totalAmount,
            nomenclature: [foundItem],
          ),
        );
      } else if (state is CustomerOrderWithNomenclatureLoaded) {
        final currentState = state as CustomerOrderWithNomenclatureLoaded;
        emit(currentState.copyWith(nomenclature: [foundItem]));
      } else {
        emit(NomenclatureFound(foundItem));
      }
      return;
    }

    // Fallback to API search if no cache
    emit(CustomerOrderLoading());

    final result = await searchNomenclatureByBarcodeUseCase(barcode);

    result.fold((failure) => emit(CustomerOrderError(failure.message)), (
      nomenclature,
    ) {
      if (nomenclature != null) {
        // If we have a customer order state, preserve it
        if (state is CustomerOrderLoaded) {
          final currentState = state as CustomerOrderLoaded;
          emit(
            CustomerOrderWithNomenclatureLoaded(
              selectedCustomer: currentState.selectedCustomer,
              orderItems: currentState.orderItems,
              totalAmount: currentState.totalAmount,
              nomenclature: [nomenclature],
            ),
          );
        } else if (state is CustomerOrderWithNomenclatureLoaded) {
          final currentState = state as CustomerOrderWithNomenclatureLoaded;
          emit(currentState.copyWith(nomenclature: [nomenclature]));
        } else {
          emit(NomenclatureFound(nomenclature));
        }
      } else {
        emit(CustomerOrderError('Товар з таким штрихкодом не знайдено'));
      }
    });
  }

  /// Set selected customer
  void setSelectedCustomer(KontragentEntity customer) {
    if (state is CustomerOrderWithNomenclatureLoaded) {
      final currentState = state as CustomerOrderWithNomenclatureLoaded;
      emit(currentState.copyWith(selectedCustomer: customer));
    } else if (state is CustomerOrderInitialized) {
      final currentState = state as CustomerOrderInitialized;
      emit(
        CustomerOrderWithNomenclatureLoaded(
          orderItems: [],
          totalAmount: 0.0,
          selectedCustomer: customer,
          customers: currentState.customers,
          nomenclature: currentState.nomenclature,
        ),
      );
    } else {
      emit(
        CustomerOrderWithNomenclatureLoaded(
          selectedCustomer: customer,
          orderItems: [],
          totalAmount: 0.0,
        ),
      );
    }
  }

  /// Add item to order
  void addOrderItem(OrderItemEntity item) {
    if (state is CustomerOrderLoaded) {
      final currentState = state as CustomerOrderLoaded;
      final updatedItems = List<OrderItemEntity>.from(currentState.orderItems);
      updatedItems.add(item);

      final totalAmount = updatedItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      emit(
        currentState.copyWith(
          orderItems: updatedItems,
          totalAmount: totalAmount,
        ),
      );
    } else if (state is CustomerOrderWithNomenclatureLoaded) {
      final currentState = state as CustomerOrderWithNomenclatureLoaded;
      final updatedItems = List<OrderItemEntity>.from(currentState.orderItems);
      updatedItems.add(item);

      final totalAmount = updatedItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      emit(
        currentState.copyWith(
          orderItems: updatedItems,
          totalAmount: totalAmount,
        ),
      );
    }
  }

  /// Remove item from order
  void removeOrderItem(String itemId) {
    if (state is CustomerOrderLoaded) {
      final currentState = state as CustomerOrderLoaded;
      final updatedItems = currentState.orderItems
          .where((item) => item.id != itemId)
          .toList();

      final totalAmount = updatedItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      emit(
        currentState.copyWith(
          orderItems: updatedItems,
          totalAmount: totalAmount,
        ),
      );
    } else if (state is CustomerOrderWithNomenclatureLoaded) {
      final currentState = state as CustomerOrderWithNomenclatureLoaded;
      final updatedItems = currentState.orderItems
          .where((item) => item.id != itemId)
          .toList();

      final totalAmount = updatedItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      emit(
        currentState.copyWith(
          orderItems: updatedItems,
          totalAmount: totalAmount,
        ),
      );
    }
  }

  /// Update item quantity
  void updateItemQuantity(String itemId, double quantity) {
    if (state is CustomerOrderLoaded) {
      final currentState = state as CustomerOrderLoaded;
      final updatedItems = currentState.orderItems.map((item) {
        if (item.id == itemId) {
          return OrderItemEntity(
            id: item.id,
            nomenclature: item.nomenclature,
            quantity: quantity,
            unitPrice: item.unitPrice,
            totalPrice: quantity * item.unitPrice,
            notes: item.notes,
          );
        }
        return item;
      }).toList();

      final totalAmount = updatedItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      emit(
        currentState.copyWith(
          orderItems: updatedItems,
          totalAmount: totalAmount,
        ),
      );
    } else if (state is CustomerOrderWithNomenclatureLoaded) {
      final currentState = state as CustomerOrderWithNomenclatureLoaded;
      final updatedItems = currentState.orderItems.map((item) {
        if (item.id == itemId) {
          return OrderItemEntity(
            id: item.id,
            nomenclature: item.nomenclature,
            quantity: quantity,
            unitPrice: item.unitPrice,
            totalPrice: quantity * item.unitPrice,
            notes: item.notes,
          );
        }
        return item;
      }).toList();

      final totalAmount = updatedItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      emit(
        currentState.copyWith(
          orderItems: updatedItems,
          totalAmount: totalAmount,
        ),
      );
    }
  }

  /// Create order
  Future<void> createOrder() async {
    CustomerOrderLoaded? orderState;

    if (state is CustomerOrderLoaded) {
      orderState = state as CustomerOrderLoaded;
    } else if (state is CustomerOrderWithNomenclatureLoaded) {
      final currentState = state as CustomerOrderWithNomenclatureLoaded;
      orderState = CustomerOrderLoaded(
        selectedCustomer: currentState.selectedCustomer,
        orderItems: currentState.orderItems,
        totalAmount: currentState.totalAmount,
      );
    } else {
      emit(CustomerOrderError('Немає даних для створення замовлення'));
      return;
    }

    if (orderState.selectedCustomer == null) {
      emit(CustomerOrderError('Оберіть клієнта'));
      return;
    }

    if (orderState.orderItems.isEmpty) {
      emit(CustomerOrderError('Додайте товари до замовлення'));
      return;
    }

    emit(CustomerOrderLoading());

    final order = CustomerOrderEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      number: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      customer: orderState.selectedCustomer!,
      items: orderState.orderItems,
      totalAmount: orderState.totalAmount,
      status: OrderStatus.draft,
    );

    final result = await createOrderUseCase(order);

    result.fold(
      (failure) => emit(CustomerOrderError(failure.message)),
      (createdOrder) => emit(OrderCreated(createdOrder)),
    );
  }

  /// Reset to initial state
  void reset() {
    _cachedCustomers = null;
    _cachedNomenclature = null;
    _isInitialized = false;
    emit(CustomerOrderInitial());
  }
}
