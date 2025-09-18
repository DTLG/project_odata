import 'package:get_it/get_it.dart';
import '../domain/repositories/customer_order_repository.dart';
import '../data/repositories/customer_order_repository_impl.dart';
import '../domain/usecases/create_order_usecase.dart';
import '../domain/usecases/get_available_customers_usecase.dart';
import '../domain/usecases/get_available_nomenclature_usecase.dart';
import '../domain/usecases/search_customers_usecase.dart';
import '../domain/usecases/search_nomenclature_usecase.dart';
import '../domain/usecases/search_nomenclature_by_barcode_usecase.dart';
import '../presentation/cubit/customer_order_cubit.dart';
import '../../../core/services/order_creation_service.dart';
import '../domain/usecases/save_local_order_usecase.dart';
import '../../customer_order/domain/repositories/orders_repository.dart';
import '../../customer_order/data/datasources/local/orders_local_data_source.dart';
import '../../customer_order/data/repositories/orders_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dependency injection setup for customer order feature
class CustomerOrderInjection {
  static void setup(GetIt sl) {
    // Services
    sl.registerLazySingleton(
      () => OrderCreationService(
        supabase: sl.isRegistered<SupabaseClient>()
            ? sl<SupabaseClient>()
            : null,
      ),
    );

    // Repository
    sl.registerLazySingleton<CustomerOrderRepository>(
      () => CustomerOrderRepositoryImpl(
        kontragentRepository: sl(),
        nomenclatureRepository: sl(),
      ),
    );

    // Use cases
    sl.registerLazySingleton(() => CreateOrderUseCase(sl()));
    sl.registerLazySingleton(() => GetAvailableCustomersUseCase(sl()));
    sl.registerLazySingleton(() => GetAvailableNomenclatureUseCase(sl()));
    sl.registerLazySingleton(() => SearchCustomersUseCase(sl()));
    sl.registerLazySingleton(() => SearchNomenclatureUseCase(sl()));
    sl.registerLazySingleton(() => SearchNomenclatureByBarcodeUseCase(sl()));
    // Orders local stack
    if (!sl.isRegistered<OrdersLocalDataSource>()) {
      sl.registerLazySingleton<OrdersLocalDataSource>(
        () => OrdersLocalDataSourceImpl(),
      );
    }
    if (!sl.isRegistered<OrdersRepository>()) {
      sl.registerLazySingleton<OrdersRepository>(
        () => OrdersRepositoryImpl(sl(), sl(), sl()),
      );
    }
    if (!sl.isRegistered<SaveLocalOrderUseCase>()) {
      sl.registerLazySingleton(() => SaveLocalOrderUseCase(sl()));
    }

    // Cubit (shared across app to keep cache warm)
    if (!sl.isRegistered<CustomerOrderCubit>()) {
      sl.registerLazySingleton(
        () => CustomerOrderCubit(
          createOrderUseCase: sl(),
          saveLocalOrderUseCase: sl(),
          getAvailableCustomersUseCase: sl(),
          getAvailableNomenclatureUseCase: sl(),
          searchCustomersUseCase: sl(),
          searchNomenclatureUseCase: sl(),
          searchNomenclatureByBarcodeUseCase: sl(),
        ),
      );
    }
  }
}
