import 'package:get_it/get_it.dart';
import '../data/datasources/inventory_remote_data_source.dart';
import '../data/datasources/inventory_local_data_source.dart';
import '../data/repositories/inventory_repository_impl.dart';
import '../domain/repositories/inventory_repository.dart';
import '../domain/usecases/get_inventory_documents.dart';
import '../domain/usecases/create_inventory_document.dart';
import '../domain/usecases/get_document_items.dart';
import '../domain/usecases/add_or_update_item.dart';
import '../domain/usecases/close_document.dart';
import '../domain/usecases/set_sku.dart';
import '../presentation/cubit/inventory_cubit.dart';
import '../data/datasources/inventory_remote_data_source_impl.dart';
import '../data/datasources/inventory_local_data_source_impl.dart';

/// Dependency injection setup for inventory feature
class InventoryInjection {
  static void setup(GetIt sl) {
    // Data sources
    sl.registerLazySingleton<InventoryRemoteDataSource>(
      () => InventoryRemoteDataSourceImpl(),
    );

    sl.registerLazySingleton<InventoryLocalDataSource>(
      () => InventoryLocalDataSourceImpl(),
    );

    // Repository
    sl.registerLazySingleton<InventoryRepository>(
      () => InventoryRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ),
    );

    // Use cases
    sl.registerLazySingleton(() => GetInventoryDocuments(sl()));
    sl.registerLazySingleton(() => CreateInventoryDocument(sl()));
    sl.registerLazySingleton(() => GetDocumentItems(sl()));
    sl.registerLazySingleton(() => AddOrUpdateItem(sl()));
    sl.registerLazySingleton(() => CloseDocument(sl()));
    sl.registerLazySingleton(() => SetSku(sl()));

    // Cubit
    sl.registerFactory(
      () => InventoryCubit(
        getInventoryDocuments: sl(),
        createInventoryDocument: sl(),
        getDocumentItems: sl(),
        addOrUpdateItem: sl(),
        closeDocument: sl(),
        setSku: sl(),
      ),
    );
  }
}
