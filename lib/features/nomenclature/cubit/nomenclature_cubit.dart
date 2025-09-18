import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_odata/objectbox.dart';
import '../../../core/usecases/nomenclature/get_local_nomenclature_usecase.dart';
import '../../../core/usecases/nomenclature/get_nomenclature_count_usecase.dart';
import '../../../core/usecases/nomenclature/search_nomenclature_by_article_usecase.dart';
import '../../../core/usecases/nomenclature/search_nomenclature_by_name_usecase.dart';
import '../../../core/usecases/nomenclature/search_nomenclature_by_barcode_usecase.dart';
import '../../../core/usecases/nomenclature/sync_nomenclature_usecase.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/injection/injection_container.dart';
import '../../../core/repositories/nomenclature_repository.dart';
import '../../../data/datasources/remote/supabase_nomenclature_datasource.dart';
import '../../../core/entities/nomenclature_entity.dart';
import 'nomenclature_state.dart';
import '../../../../data/datasources/local/nomenclature_local_datasource.dart';
import '../../../core/objectbox/objectbox_entities.dart';

/// Cubit для управління станом номенклатури
/// Дотримується принципу Single Responsibility (SOLID)
class NomenclatureCubit extends Cubit<NomenclatureState> {
  final SyncNomenclatureUseCase _syncNomenclatureUseCase;
  final GetLocalNomenclatureUseCase _getLocalNomenclatureUseCase;
  final SearchNomenclatureByNameUseCase _searchNomenclatureByNameUseCase;
  final SearchNomenclatureByArticleUseCase _searchNomenclatureByArticleUseCase;
  final GetNomenclatureCountUseCase _getNomenclatureCountUseCase;
  final SearchNomenclatureByBarcodeUseCase _searchNomenclatureByBarcodeUseCase;

  static const String rootGuid = '00000000-0000-0000-0000-000000000000';

  // In-memory tree cache
  final Map<String, List<NomenclatureEntity>> _childrenByParentGuid = {};
  ObjectBox? _obx;

  NomenclatureCubit({
    required SyncNomenclatureUseCase syncNomenclatureUseCase,
    required GetLocalNomenclatureUseCase getLocalNomenclatureUseCase,
    required SearchNomenclatureByNameUseCase searchNomenclatureByNameUseCase,
    required SearchNomenclatureByArticleUseCase
    searchNomenclatureByArticleUseCase,
    required GetNomenclatureCountUseCase getNomenclatureCountUseCase,
    required SearchNomenclatureByBarcodeUseCase
    searchNomenclatureByBarcodeUseCase,
  }) : _syncNomenclatureUseCase = syncNomenclatureUseCase,
       _getLocalNomenclatureUseCase = getLocalNomenclatureUseCase,
       _searchNomenclatureByNameUseCase = searchNomenclatureByNameUseCase,
       _searchNomenclatureByArticleUseCase = searchNomenclatureByArticleUseCase,
       _getNomenclatureCountUseCase = getNomenclatureCountUseCase,
       _searchNomenclatureByBarcodeUseCase = searchNomenclatureByBarcodeUseCase,
       super(NomenclatureInitial());

  /// Load tree root (folders with parentGuid=root and isFolder=true)
  Future<void> loadRootTree() async {
    emit(NomenclatureLoading());

    final obx = sl<ObjectBox>();
    _obx = obx;
    final roots = obx.getRootNomenclature();
    // load all locally then filter roots
    final countResult = await _getNomenclatureCountUseCase(const NoParams());
    int totalCount = 0;
    countResult.fold((_) {}, (c) => totalCount = c);
    emit(
      NomenclatureTreeLoaded(
        rootFolders: roots,
        childrenByParentGuid: Map<String, List<NomenclatureEntity>>.from(
          _childrenByParentGuid,
        ),
        totalCount: totalCount,
      ),
    );
    // load all locally then filter roots
    // final countResult = await _getNomenclatureCountUseCase(const NoParams());
    // int totalCount = 0;
    // countResult.fold((_) {}, (c) => totalCount = c);

    // final result = await _getLocalNomenclatureUseCase(const NoParams());
    // result.fold(
    //   (failure) {
    //     // Allow page to open with empty tree; UI can show failure.message
    //     _childrenByParentGuid.clear();
    //     emit(
    //       NomenclatureTreeLoaded(
    //         rootFolders: const <NomenclatureEntity>[],
    //         childrenByParentGuid: const <String, List<NomenclatureEntity>>{},
    //         totalCount: totalCount,
    //       ),
    //     );
    //   },
    //   (all) {
    //     // cache children by parent
    //     _childrenByParentGuid.clear();
    //     for (final e in all) {
    //       // Treat empty or missing parent as root
    //       final String parent = (e.parentGuid.isEmpty)
    //           ? rootGuid
    //           : e.parentGuid;
    //       final list = _childrenByParentGuid[parent] ??= <NomenclatureEntity>[];
    //       list.add(e);
    //     }
    //     // Roots are folders directly under root
    //     final roots =
    //         (_childrenByParentGuid[rootGuid] ?? <NomenclatureEntity>[])
    //             .where((e) => e.isFolder)
    //             .toList();
    //     emit(
    //       NomenclatureTreeLoaded(
    //         rootFolders: roots,
    //         childrenByParentGuid: Map<String, List<NomenclatureEntity>>.from(
    //           _childrenByParentGuid,
    //         ),
    //         totalCount: totalCount,
    //       ),
    //     );
    //   },
    // );
  }

  /// Get children for a given parent from cache (loadRootTree must be called first)
  // List<NomenclatureEntity> getChildren(String parentGuid) {
  //   return _childrenByParentGuid[parentGuid] ?? const <NomenclatureEntity>[];
  // }
  Future<List<NomenclatureObx>> loadChildren(String parentGuid) async {
    if (_obx == null) return const [];
    return _obx!.getChildrenNomenclature(parentGuid);
  }

  /// Синхронізація номенклатури з сервером (з прогресом)
  Future<void> syncNomenclature() async {
    emit(
      const NomenclatureLoadingWithProgress(
        message: 'Починаємо синхронізацію...',
        current: 0,
        total: 50500,
      ),
    );

    try {
      final datasource = sl<SupabaseNomenclatureDatasource>();

      // Отримуємо дані з прогресом
      final nomenclatures = await datasource.getAllNomenclatureWithProgress(
        onProgress: (message, current, total) {
          emit(
            NomenclatureLoadingWithProgress(
              message: message,
              current: current,
              total: total,
            ),
          );
        },
      );

      // Зберігаємо в локальну базу через repository
      final repository = sl<NomenclatureRepository>();

      emit(
        const NomenclatureLoadingWithProgress(
          message: 'Збереження в локальну базу...',
          current: 0,
          total: 100,
        ),
      );

      // Очищуємо стару базу
      await repository.clearLocalNomenclature();

      emit(
        const NomenclatureLoadingWithProgress(
          message: 'Збереження даних...',
          current: 50,
          total: 100,
        ),
      );

      // Зберігаємо нові дані
      await repository.saveLocalNomenclature(
        nomenclatures.map((m) => m.toEntity()).toList(),
      );

      emit(
        const NomenclatureLoadingWithProgress(
          message: 'Завершення збереження...',
          current: 100,
          total: 100,
        ),
      );

      emit(NomenclatureSyncSuccess(nomenclatures.length));
    } catch (e) {
      emit(NomenclatureError('Помилка синхронізації: $e'));
    }
  }

  /// Завантаження номенклатури з локальної бази (плоский список)
  Future<void> loadLocalNomenclature() async {
    emit(NomenclatureLoading());

    // Спочатку отримуємо кількість записів
    final countResult = await _getNomenclatureCountUseCase(const NoParams());

    int totalCount = 0;
    countResult.fold(
      (failure) => totalCount = 0,
      (count) => totalCount = count,
    );

    // Потім завантажуємо дані
    final result = await _getLocalNomenclatureUseCase(const NoParams());

    result.fold(
      (failure) => emit(
        NomenclatureLoaded(
          nomenclatures: const <NomenclatureEntity>[],
          totalCount: totalCount,
        ),
      ),
      (nomenclatures) => emit(
        NomenclatureLoaded(
          nomenclatures: nomenclatures
              .where((e) => e.isFolder && e.parentGuid == rootGuid)
              .toList(),
          totalCount: totalCount,
        ),
      ),
    );
  }

  /// Пошук номенклатури за назвою
  Future<void> searchNomenclatureByName(String name) async {
    if (name.trim().isEmpty) {
      await loadLocalNomenclature();
      return;
    }

    emit(NomenclatureLoading());

    final result = await _searchNomenclatureByNameUseCase(
      SearchNomenclatureByNameParams(name),
    );

    result.fold(
      (failure) => emit(NomenclatureError(failure.message)),
      (nomenclatures) => emit(
        NomenclatureSearchResult(
          searchResults: nomenclatures,
          searchQuery: name,
        ),
      ),
    );
  }

  /// Пошук номенклатури за артикулом
  Future<void> searchNomenclatureByArticle(String article) async {
    if (article.trim().isEmpty) {
      emit(const NomenclatureError('Артикул не може бути пустим'));
      return;
    }

    emit(NomenclatureLoading());

    final result = await _searchNomenclatureByArticleUseCase(
      SearchNomenclatureByArticleParams(article),
    );

    result.fold((failure) => emit(NomenclatureError(failure.message)), (list) {
      if (list.isNotEmpty) {
        emit(
          NomenclatureSearchResult(searchResults: list, searchQuery: article),
        );
      } else {
        emit(NomenclatureNotFoundByArticle(article));
      }
    });
  }

  /// Пошук номенклатури за штрихкодом
  Future<void> searchNomenclatureByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) {
      emit(const NomenclatureError('Штрихкод не може бути пустим'));
      return;
    }

    emit(NomenclatureLoading());

    final result = await _searchNomenclatureByBarcodeUseCase(
      SearchNomenclatureByBarcodeParams(barcode),
    );

    result.fold((failure) => emit(NomenclatureError(failure.message)), (
      nomenclature,
    ) {
      if (nomenclature != null) {
        emit(
          NomenclatureFoundByArticle(
            nomenclature: nomenclature,
            article: barcode,
          ),
        );
      } else {
        emit(NomenclatureNotFoundByArticle(barcode));
      }
    });
  }

  /// Очистити пошук та повернутися до всієї номенклатури
  Future<void> clearSearch() async {
    await loadLocalNomenclature();
  }

  /// Оновити кількість номенклатури
  Future<void> refreshCount() async {
    final result = await _getNomenclatureCountUseCase(const NoParams());

    result.fold((failure) => emit(NomenclatureError(failure.message)), (count) {
      if (state is NomenclatureLoaded) {
        final currentState = state as NomenclatureLoaded;
        emit(
          NomenclatureLoaded(
            nomenclatures: currentState.nomenclatures,
            totalCount: count,
          ),
        );
      } else if (state is NomenclatureTreeLoaded) {
        final current = state as NomenclatureTreeLoaded;
        emit(
          NomenclatureTreeLoaded(
            rootFolders: current.rootFolders,
            childrenByParentGuid: current.childrenByParentGuid,
            totalCount: count,
          ),
        );
      }
    });
  }

  /// Тестування підключення до Supabase
  Future<void> testConnection() async {
    emit(NomenclatureLoading());

    try {
      final datasource = sl<SupabaseNomenclatureDatasource>();
      final testResult = await datasource.testConnection();

      if (testResult['status'] == 'success') {
        emit(NomenclatureTestSuccess(testResult));
      } else {
        emit(NomenclatureError('Тест не пройдено: ${testResult['error']}'));
      }
    } catch (e) {
      emit(NomenclatureError('Помилка тестування підключення: $e'));
    }
  }

  /// Діагностика локальної бази даних SQLite
  Future<void> debugLocalDatabase() async {
    emit(NomenclatureLoading());

    try {
      final localDatasource = sl<NomenclatureLocalDatasource>();
      final debugResult = await localDatasource.debugDatabase();

      emit(NomenclatureTestSuccess(debugResult));
    } catch (e) {
      emit(NomenclatureError('Помилка діагностики локальної БД: $e'));
    }
  }

  /// Перестворення локальної бази даних (виправлення проблем)
  Future<void> recreateLocalDatabase() async {
    emit(NomenclatureLoading());

    try {
      final localDatasource = sl<NomenclatureLocalDatasource>();
      await localDatasource.recreateDatabase();

      emit(
        NomenclatureTestSuccess({
          'status': 'success',
          'message': 'База даних SQLite перестворена',
          'action': 'recreate_database',
          'time': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      emit(NomenclatureError('Помилка перестворення локальної БД: $e'));
    }
  }

  /// Повністю очистити локальні дані (без перестворення таблиць)
  Future<void> clearLocalData() async {
    emit(NomenclatureLoading());
    try {
      final repository = sl<NomenclatureRepository>();
      await repository.clearLocalNomenclature();
      emit(
        NomenclatureTestSuccess({
          'status': 'success',
          'message': 'Локальні дані очищено',
          'action': 'clear_local_data',
          'time': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      emit(NomenclatureError('Не вдалося очистити локальні дані: $e'));
    }
  }
}
