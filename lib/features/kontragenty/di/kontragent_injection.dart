import 'package:get_it/get_it.dart';
import '../data/datasources/kontragent_remote_data_source.dart';
import '../data/datasources/kontragent_local_data_source.dart';
import '../data/datasources/remote/supabase_kontragent_datasource.dart';
import '../data/datasources/local/sqflite_kontragent_datasource.dart';
import '../data/repositories/kontragent_repository_impl.dart';
import '../domain/repositories/kontragent_repository.dart';
import '../domain/usecases/sync_kontragenty_usecase.dart';
import '../domain/usecases/get_local_kontragenty_usecase.dart';
import '../domain/usecases/search_kontragenty_by_name_usecase.dart';
import '../domain/usecases/search_kontragenty_by_edrpou_usecase.dart';
import '../domain/usecases/get_root_folders_usecase.dart';
import '../domain/usecases/get_children_usecase.dart';
import '../domain/usecases/get_kontragenty_count_usecase.dart';
import '../domain/usecases/clear_local_data_usecase.dart';
import '../presentation/cubit/kontragent_cubit.dart';

/// Dependency injection setup for kontragent feature
class KontragentInjection {
  static void setup(GetIt sl) {
    // Data sources
    sl.registerLazySingleton<KontragentRemoteDataSource>(
      () => SupabaseKontragentDatasourceImpl(sl()),
    );

    sl.registerLazySingleton<KontragentLocalDataSource>(
      () => SqliteKontragentDatasourceImpl(),
    );

    // Repository
    sl.registerLazySingleton<KontragentRepository>(
      () => KontragentRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ),
    );

    // Use cases
    sl.registerLazySingleton(() => SyncKontragentyUseCase(sl()));
    sl.registerLazySingleton(() => GetLocalKontragentyUseCase(sl()));
    sl.registerLazySingleton(() => SearchKontragentyByNameUseCase(sl()));
    sl.registerLazySingleton(() => SearchKontragentyByEdrpouUseCase(sl()));
    sl.registerLazySingleton(() => GetRootFoldersUseCase(sl()));
    sl.registerLazySingleton(() => GetChildrenUseCase(sl()));
    sl.registerLazySingleton(() => GetKontragentyCountUseCase(sl()));
    sl.registerLazySingleton(() => ClearLocalDataUseCase(sl()));

    // Cubit
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
}
