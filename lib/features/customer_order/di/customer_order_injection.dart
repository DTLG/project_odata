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

/// Dependency injection setup for customer order feature
class CustomerOrderInjection {
  static void setup(GetIt sl) {
    // Services
    sl.registerLazySingleton(() => OrderCreationService());

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

    // Cubit
    sl.registerFactory(
      () => CustomerOrderCubit(
        createOrderUseCase: sl(),
        getAvailableCustomersUseCase: sl(),
        getAvailableNomenclatureUseCase: sl(),
        searchCustomersUseCase: sl(),
        searchNomenclatureUseCase: sl(),
        searchNomenclatureByBarcodeUseCase: sl(),
      ),
    );
  }
}
