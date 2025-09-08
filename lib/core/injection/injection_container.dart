import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/local/sqflite_nomenclature_datasource.dart';
import '../../data/datasources/remote/supabase_nomenclature_datasource.dart';
import '../../data/repositories/nomenclature_repository_impl.dart';
import '../repositories/nomenclature_repository.dart';
import '../usecases/nomenclature/get_local_nomenclature_usecase.dart';
import '../usecases/nomenclature/get_nomenclature_count_usecase.dart';
import '../usecases/nomenclature/search_nomenclature_by_article_usecase.dart';
import '../usecases/nomenclature/search_nomenclature_by_name_usecase.dart';
import '../usecases/nomenclature/search_nomenclature_by_barcode_usecase.dart';
import '../usecases/nomenclature/sync_nomenclature_usecase.dart';
import '../../features/nomenclature/cubit/nomenclature_cubit.dart';
import '../database/sqlite_helper.dart';
import '../../features/inventory/di/inventory_injection.dart';
import '../../features/kontragenty/di/kontragent_injection.dart';
import '../../features/customer_order/di/customer_order_injection.dart';
import '../../features/kontragenty/data/datasources/kontragent_remote_data_source.dart';
import '../../features/kontragenty/data/datasources/kontragent_local_data_source.dart';
import '../../features/kontragenty/data/datasources/remote/supabase_kontragent_datasource.dart';
import '../../features/kontragenty/data/datasources/local/sqflite_kontragent_datasource.dart';
import '../../features/kontragenty/data/repositories/kontragent_repository_impl.dart';
import '../../features/kontragenty/domain/repositories/kontragent_repository.dart';
import '../../features/kontragenty/domain/usecases/sync_kontragenty_usecase.dart';
import '../../features/kontragenty/domain/usecases/get_local_kontragenty_usecase.dart';
import '../../features/kontragenty/domain/usecases/search_kontragenty_by_name_usecase.dart';
import '../../features/kontragenty/domain/usecases/search_kontragenty_by_edrpou_usecase.dart';
import '../../features/kontragenty/domain/usecases/get_root_folders_usecase.dart';
import '../../features/kontragenty/domain/usecases/get_children_usecase.dart';
import '../../features/kontragenty/domain/usecases/get_kontragenty_count_usecase.dart';
import '../../features/kontragenty/domain/usecases/clear_local_data_usecase.dart';
import '../../features/kontragenty/presentation/cubit/kontragent_cubit.dart';

final GetIt sl = GetIt.instance;

/// Ініціалізація всіх залежностей
/// Дотримується принципу Dependency Inversion (SOLID)
Future<void> initializeDependencies() async {
  // External dependencies
  await _initExternalDependencies();

  // Data sources
  _initDataSources();

  // Repositories
  _initRepositories();

  // Use cases
  _initUseCases();

  // Cubits
  _initCubits();

  // Feature-specific injections
  _initFeatureInjections();
}

/// Ініціалізація зовнішніх залежностей (Supabase, SQLite)
Future<void> _initExternalDependencies() async {
  // Безпечна реєстрація Supabase client
  try {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
    print('✅ Supabase client зареєстрований');
  } catch (e) {
    print('⚠️ Supabase client недоступний: $e');
    // Продовжуємо без Supabase - буде працювати тільки локально
  }

  // Ініціалізуємо SQLite для всіх платформ
  await SqliteHelper.initialize();

  print('✅ SQLite готовий до роботи');
}

/// Ініціалізація джерел даних
void _initDataSources() {
  // Nomenclature data sources
  sl.registerLazySingleton<SupabaseNomenclatureDatasource>(
    () => SupabaseNomenclatureDatasourceImpl(sl()),
  );
  sl.registerLazySingleton<SqliteNomenclatureDatasource>(
    () => SqliteNomenclatureDatasourceImpl(),
  );

  // Kontragent data sources
  sl.registerLazySingleton<KontragentRemoteDataSource>(
    () => SupabaseKontragentDatasourceImpl(sl()),
  );
  sl.registerLazySingleton<KontragentLocalDataSource>(
    () => SqliteKontragentDatasourceImpl(),
  );
}

/// Ініціалізація репозиторіїв
void _initRepositories() {
  // Nomenclature repository
  sl.registerLazySingleton<NomenclatureRepository>(
    () => NomenclatureRepositoryImpl(
      remoteDatasource: sl(),
      localDatasource: sl(),
    ),
  );

  // Kontragent repository
  sl.registerLazySingleton<KontragentRepository>(
    () =>
        KontragentRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );
}

/// Ініціалізація use cases
void _initUseCases() {
  // Nomenclature use cases
  sl.registerLazySingleton(() => SyncNomenclatureUseCase(sl()));
  sl.registerLazySingleton(() => GetLocalNomenclatureUseCase(sl()));
  sl.registerLazySingleton(() => SearchNomenclatureByNameUseCase(sl()));
  sl.registerLazySingleton(() => SearchNomenclatureByBarcodeUseCase(sl()));
  sl.registerLazySingleton(() => SearchNomenclatureByArticleUseCase(sl()));
  sl.registerLazySingleton(() => GetNomenclatureCountUseCase(sl()));

  // Kontragent use cases
  sl.registerLazySingleton(() => SyncKontragentyUseCase(sl()));
  sl.registerLazySingleton(() => GetLocalKontragentyUseCase(sl()));
  sl.registerLazySingleton(() => SearchKontragentyByNameUseCase(sl()));
  sl.registerLazySingleton(() => SearchKontragentyByEdrpouUseCase(sl()));
  sl.registerLazySingleton(() => GetRootFoldersUseCase(sl()));
  sl.registerLazySingleton(() => GetChildrenUseCase(sl()));
  sl.registerLazySingleton(() => GetKontragentyCountUseCase(sl()));
  sl.registerLazySingleton(() => ClearLocalDataUseCase(sl()));
}

/// Ініціалізація cubits
void _initCubits() {
  // Nomenclature cubit
  sl.registerFactory(
    () => NomenclatureCubit(
      syncNomenclatureUseCase: sl(),
      getLocalNomenclatureUseCase: sl(),
      searchNomenclatureByNameUseCase: sl(),
      searchNomenclatureByArticleUseCase: sl(),
      getNomenclatureCountUseCase: sl(),
      searchNomenclatureByBarcodeUseCase: sl(),
    ),
  );

  // Kontragent cubit
  sl.registerFactory(
    () => KontragentCubit(
      syncKontragentyUseCase: sl(),
      getLocalKontragentyUseCase: sl(),
      searchKontragentyByNameUseCase: sl(),
      searchKontragentyByEdrpouUseCase: sl(),
      getRootFoldersUseCase: sl(),
      getChildrenUseCase: sl(),
      getKontragentyCountUseCase: sl(),
      clearLocalDataUseCase: sl(),
    ),
  );
}

/// Ініціалізація feature-specific injections
void _initFeatureInjections() {
  // Inventory feature
  InventoryInjection.setup(sl);

  // Kontragent feature
  // KontragentInjection.setup(sl);

  // Customer Order feature
  CustomerOrderInjection.setup(sl);
}
