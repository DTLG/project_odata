import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:project_odata/objectbox.dart';
import '../../domain/usecases/get_local_nomenclature_usecase.dart';
import '../../domain/usecases/get_nomenclature_count_usecase.dart';
import '../../domain/usecases/search_nomenclature_by_article_usecase.dart';
import '../../domain/usecases/search_nomenclature_by_name_usecase.dart';
import '../../domain/usecases/search_nomenclature_by_barcode_usecase.dart';
import '../../domain/usecases/sync_nomenclature_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/injection/injection_container.dart';
import '../../domain/repositories/nomenclature_repository.dart';
import '../../data/datasources/remote/supabase_nomenclature_datasource.dart';
import '../../data/datasources/local/objectbox_nomenclature_datasource.dart';
import 'nomenclature_state.dart';
// import removed: local datasource not used directly here
import '../../../../core/objectbox/objectbox_entities.dart';
import '../../domain/entities/nomenclature_entity.dart';
import '../../../common/widgets/search_mode_switch.dart';
import '../../domain/usecases/get_root_folders_usecase.dart';

/// Cubit для управління станом номенклатури
/// Дотримується принципу Single Responsibility (SOLID)
class NomenclatureCubit extends Cubit<NomenclatureState> {
  final SyncNomenclatureUseCase _syncNomenclatureUseCase;
  final GetRootFoldersUseCase _getRootFoldersUseCase;
  final GetLocalNomenclatureUseCase _getLocalNomenclatureUseCase;
  final SearchNomenclatureByNameUseCase _searchNomenclatureByNameUseCase;
  final SearchNomenclatureByArticleUseCase _searchNomenclatureByArticleUseCase;
  final GetNomenclatureCountUseCase getNomenclatureCountUseCase;
  final SearchNomenclatureByBarcodeUseCase _searchNomenclatureByBarcodeUseCase;

  static const String rootGuid = '00000000-0000-0000-0000-000000000000';

  // In-memory tree cache
  final Map<String, List<NomenclatureEntity>> _childrenByParentGuid = {};
  ObjectBox? _obx;

  // Fast in-memory caches
  final Map<String, List<BarcodeEntity>> _barcodesByNomGuid = {};
  final Map<String, List<PriceEntity>> _pricesByNomGuid = {};
  final Map<String, List<NomenclatureObx>> _childrenByParentGuidObx = {};

  NomenclatureCubit({
    required SyncNomenclatureUseCase syncNomenclatureUseCase,
    required GetLocalNomenclatureUseCase getLocalNomenclatureUseCase,
    required SearchNomenclatureByNameUseCase searchNomenclatureByNameUseCase,
    required GetRootFoldersUseCase getRootFoldersUseCase,
    required SearchNomenclatureByArticleUseCase
    searchNomenclatureByArticleUseCase,
    required GetNomenclatureCountUseCase getNomenclatureCountUseCase,
    required SearchNomenclatureByBarcodeUseCase
    searchNomenclatureByBarcodeUseCase,
  }) : _syncNomenclatureUseCase = syncNomenclatureUseCase,
       _getLocalNomenclatureUseCase = getLocalNomenclatureUseCase,
       _searchNomenclatureByNameUseCase = searchNomenclatureByNameUseCase,
       _getRootFoldersUseCase = getRootFoldersUseCase,
       _searchNomenclatureByArticleUseCase = searchNomenclatureByArticleUseCase,
       this.getNomenclatureCountUseCase = getNomenclatureCountUseCase,
       _searchNomenclatureByBarcodeUseCase = searchNomenclatureByBarcodeUseCase,
       super(NomenclatureState(status: NomenclatureStatus.initial));

  /// Load tree root (folders with parentGuid=root and isFolder=true)
  Future<void> loadRootTree() async {
    final totalSw = Stopwatch()..start();
    final emitLoadingSw = Stopwatch()..start();
    emit(state.copyWith(status: NomenclatureStatus.loading));
    emitLoadingSw.stop();

    // Load root folders via use case (repository -> datasource)
    final fetchSw = Stopwatch()..start();
    final result = await _getRootFoldersUseCase(const NoParams());
    fetchSw.stop();

    int rootsLen = 0;
    final buildSw = Stopwatch();
    final emitSw = Stopwatch();

    result.fold(
      (_) {
        emitSw.start();
        _childrenByParentGuid.clear();
        emit(
          NomenclatureState(
            status: NomenclatureStatus.treeLoaded,
            rootFolders: const <NomenclatureEntity>[],
            childrenByParentGuid: const <String, List<NomenclatureEntity>>{},
          ),
        );
        emitSw.stop();
      },
      (all) {
        buildSw.start();
        // Build children map from domain entities
        _childrenByParentGuid.clear();
        for (final e in all) {
          final String parent = (e.parentGuid.isEmpty)
              ? rootGuid
              : e.parentGuid;
          final list = _childrenByParentGuid[parent] ??= <NomenclatureEntity>[];
          list.add(e);
        }
        // Roots are folders directly under root
        final roots =
            (_childrenByParentGuid[rootGuid] ?? <NomenclatureEntity>[])
                .where((e) => e.isFolder)
                .toList();
        rootsLen = roots.length;
        buildSw.stop();

        emitSw.start();
        emit(
          NomenclatureState(
            status: NomenclatureStatus.treeLoaded,
            rootFolders: roots,
            childrenByParentGuid: Map<String, List<NomenclatureEntity>>.from(
              _childrenByParentGuid,
            ),
          ),
        );
        emitSw.stop();
      },
    );

    totalSw.stop();
    debugPrint(
      'loadRootTree timings -> total: ${totalSw.elapsedMilliseconds}ms, '
      'emitLoading: ${emitLoadingSw.elapsedMilliseconds}ms, '
      'fetch: ${fetchSw.elapsedMilliseconds}ms, '
      'build: ${buildSw.isRunning ? 0 : buildSw.elapsedMilliseconds}ms, '
      'emit: ${emitSw.isRunning ? 0 : emitSw.elapsedMilliseconds}ms, '
      'roots: $rootsLen',
    );
  }

  /// Get children for a given parent from cache (loadRootTree must be called first)
  // List<NomenclatureEntity> getChildren(String parentGuid) {
  //   return _childrenByParentGuid[parentGuid] ?? const <NomenclatureEntity>[];
  // }
  Future<List<NomenclatureEntity>> loadChildren(String parentGuid) async {
    final totalSw = Stopwatch()..start();
    final querySw = Stopwatch()..start();

    // Ensure ObjectBox facade is available
    if (_obx == null) {
      try {
        _obx = sl<ObjectBox>();
      } catch (_) {
        debugPrint('loadChildren error: ObjectBox not available');
        return const <NomenclatureEntity>[];
      }
    }

    // Always read fresh from ObjectBox
    final obxList = _obx!.getChildrenNomenclature(parentGuid);
    querySw.stop();

    // Update cache with latest
    _childrenByParentGuidObx[parentGuid] = obxList;

    final mapSw = Stopwatch()..start();
    final entities = obxList
        .map(
          (k) => NomenclatureEntity(
            guid: k.guid,
            name: k.name,
            nameLower: k.nameLower,
            isFolder: k.isFolder,
            parentGuid: k.parentGuid,
            description: '',
            createdAt: k.createdAtMs > 0
                ? DateTime.fromMillisecondsSinceEpoch(k.createdAtMs)
                : DateTime.now(),
            price: k.price,
            article: k.article,
            unitName: k.unitName,
            unitGuid: k.unitGuid,
            id: k.id,
          ),
        )
        .toList();
    mapSw.stop();
    totalSw.stop();

    debugPrint(
      'loadChildren($parentGuid) -> total: ${totalSw.elapsedMilliseconds}ms, '
      'query: ${querySw.elapsedMilliseconds}ms, map: ${mapSw.elapsedMilliseconds}ms, '
      'count: ${entities.length}',
    );

    return entities;
  }

  /// Stream children incrementally in pages so UI can render progressively
  Stream<List<NomenclatureEntity>> streamChildren(
    String parentGuid, {
    int pageSize = 200,
  }) async* {
    if (_obx == null) {
      try {
        _obx = sl<ObjectBox>();
      } catch (_) {
        yield const <NomenclatureEntity>[];
        return;
      }
    }

    int offset = 0;

    while (true) {
      final batch = _obx!.getChildrenNomenclaturePaged(
        parentGuid,
        offset: offset,
        limit: pageSize,
      );
      if (batch.isEmpty) break;

      final entities = batch
          .map(
            (k) => NomenclatureEntity(
              guid: k.guid,
              name: k.name,
              nameLower: k.nameLower,
              isFolder: k.isFolder,
              parentGuid: k.parentGuid,
              description: '',
              createdAt: k.createdAtMs > 0
                  ? DateTime.fromMillisecondsSinceEpoch(k.createdAtMs)
                  : DateTime.now(),
              price: k.price,
              article: k.article,
              unitName: k.unitName,
              unitGuid: k.unitGuid,
              id: k.id,
            ),
          )
          .toList();

      // ⚡ Тільки цей батч!
      yield entities;

      offset += batch.length;
      if (batch.length < pageSize) break;

      // Невелика пауза, щоб не блокувати UI
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  /// Begin streaming children into state (incremental rendering via BlocBuilder)
  Future<void> beginStreamChildren(
    String parentGuid, {
    int pageSize = 100,
  }) async {
    final totalSw = Stopwatch()..start();
    final resetSw = Stopwatch()..start();

    // Reset list for this parent and emit
    final resetMap = Map<String, List<NomenclatureEntity>>.from(
      state.childrenByParentGuid,
    );
    resetMap[parentGuid] = <NomenclatureEntity>[];
    emit(
      state.copyWith(
        status: NomenclatureStatus.treeLoaded,
        childrenByParentGuid: resetMap,
      ),
    );
    resetSw.stop();

    int pages = 0;
    int totalItems = 0;
    int pagesSinceEmit = 0;
    final emitIntervalMs = 50; // throttle UI updates to ~20 FPS
    final lastEmitSw = Stopwatch()..start();

    await for (final batch in streamChildren(parentGuid, pageSize: pageSize)) {
      final mergeSw = Stopwatch()..start();
      final updated = Map<String, List<NomenclatureEntity>>.from(
        state.childrenByParentGuid,
      );
      final current = updated[parentGuid] ?? <NomenclatureEntity>[];
      updated[parentGuid] = <NomenclatureEntity>[...current, ...batch];
      mergeSw.stop();

      Duration emitElapsed = Duration.zero;
      final emitSw = Stopwatch();
      bool didEmit = false;

      // Throttle: emit only if enough time passed or enough pages batched
      if (lastEmitSw.elapsedMilliseconds >= emitIntervalMs ||
          pagesSinceEmit >= 5) {
        emitSw.start();
        emit(
          state.copyWith(
            status: NomenclatureStatus.treeLoaded,
            childrenByParentGuid: updated,
          ),
        );
        emitSw.stop();
        emitElapsed = Duration(milliseconds: emitSw.elapsedMilliseconds);
        lastEmitSw.reset();
        didEmit = true;
        pagesSinceEmit = 0;
        // Yield to event loop to keep UI responsive
        await Future.delayed(const Duration(milliseconds: 0));
      } else {
        // keep state local; next loop may emit
        // Note: we still update state reference so next emit has merged data
        emit(
          state.copyWith(
            status: NomenclatureStatus.treeLoaded,
            childrenByParentGuid: updated,
          ),
        );
        didEmit = true;
      }

      pages += 1;
      totalItems += batch.length;
      pagesSinceEmit += 1;
      debugPrint(
        'beginStreamChildren($parentGuid) page $pages: merge=${mergeSw.elapsedMilliseconds}ms, emit=${didEmit ? emitElapsed.inMilliseconds : 0}ms, batch=${batch.length}, total=$totalItems',
      );
    }

    totalSw.stop();
    debugPrint(
      'beginStreamChildren($parentGuid) finished: pages=$pages, totalItems=$totalItems, reset=${resetSw.elapsedMilliseconds}ms, total=${totalSw.elapsedMilliseconds}ms',
    );
  }

  // /// Preload all barcodes and prices into memory (for instant UI mapping)
  // Future<void> preloadBarcodesAndPrices() async {
  //   final obx = sl<ObjectBox>();
  //   // Barcodes
  //   final allBarcodes = obx.barcodeBox.getAll();
  //   _barcodesByNomGuid.clear();
  //   for (final b in allBarcodes) {
  //     final list = _barcodesByNomGuid[b.nomGuid] ??= <BarcodeEntity>[];
  //     list.add(BarcodeEntity(nomGuid: b.nomGuid, barcode: b.barcode));
  //   }
  //   // Prices
  //   final allPrices = obx.priceBox.getAll();
  //   _pricesByNomGuid.clear();
  //   for (final p in allPrices) {
  //     final list = _pricesByNomGuid[p.nomGuid] ??= <PriceEntity>[];
  //     list.add(
  //       PriceEntity(
  //         nomGuid: p.nomGuid,
  //         price: p.price,
  //         createdAt: p.createdAtMs != null
  //             ? DateTime.fromMillisecondsSinceEpoch(p.createdAtMs!)
  //             : null,
  //       ),
  //     );
  //   }
  //   // Sort each price history ascending by createdAt
  //   for (final e in _pricesByNomGuid.entries) {
  //     e.value.sort(
  //       (a, b) => (a.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
  //         b.createdAt?.millisecondsSinceEpoch ?? 0,
  //       ),
  //     );
  //   }
  // }

  // List<BarcodeEntity> getBarcodesFor(String nomGuid) =>
  //     _barcodesByNomGuid[nomGuid] ?? const <BarcodeEntity>[];
  // List<PriceEntity> getPricesFor(String nomGuid) =>
  //     _pricesByNomGuid[nomGuid] ?? const <PriceEntity>[];

  /// Синхронізація номенклатури з сервером (з прогресом)
  Future<void> syncNomenclature() async {
    emit(state.copyWith(status: NomenclatureStatus.loading));

    try {
      final datasource = sl<SupabaseNomenclatureDatasource>();

      // Отримуємо дані з прогресом
      await datasource.syncNomenclatureWithProgress(
        local: sl<ObjectboxNomenclatureDatasource>(),
        onProgress: (message, current, total) {
          emit(
            NomenclatureState(
              status: NomenclatureStatus.loading,
              message: message,
              current: current,
              total: total,
            ),
            //   message: message,
            //   current: current,
            //   total: total,
            // ),
          );
        },
      );

      // Зберігаємо в локальну базу через repository
      final repository = sl<NomenclatureRepository>();

      emit(
        const NomenclatureState(
          status: NomenclatureStatus.loading,
          message: 'Збереження в локальну базу...',
          current: 0,
          total: 100,
        ),
        //   message: 'Збереження в локальну базу...',
        //   current: 0,
        //   total: 100,
        // ),
      );

      // Очищення старої бази не потрібне: дані вже вставлено під час синку

      emit(
        const NomenclatureState(
          status: NomenclatureStatus.loading,
          message: 'Збереження даних...',
          current: 50,
          total: 100,
        ),
      );

      // Note: saving handled via direct buffered insert during sync

      emit(
        const NomenclatureState(
          status: NomenclatureStatus.loading,
          message: 'Завершення збереження...',
          current: 100,
          total: 100,
        ),
      );

      emit(
        NomenclatureState(
          status: NomenclatureStatus.syncSuccess,
          // syncedCount: nomenclatures.length,
        ),
      );
    } catch (e) {
      emit(
        NomenclatureState(
          status: NomenclatureStatus.error,
          errorMessage: 'Помилка синхронізації: $e',
        ),
      );
    }
  }

  /// Завантаження номенклатури з локальної бази (плоский список)
  Future<void> loadLocalNomenclature() async {
    emit(state.copyWith(status: NomenclatureStatus.loading));

    // Спочатку отримуємо кількість записів
    final countResult = await getNomenclatureCountUseCase(const NoParams());

    int totalCount = 0;
    countResult.fold(
      (failure) => totalCount = 0,
      (count) => totalCount = count,
    );

    // Потім завантажуємо дані
    final result = await _getLocalNomenclatureUseCase(const NoParams());

    result.fold(
      (failure) => emit(
        NomenclatureState(
          status: NomenclatureStatus.loaded,
          nomenclatures: const <NomenclatureEntity>[],
          totalCount: totalCount,
        ),
      ),
      (nomenclatures) => emit(
        NomenclatureState(
          status: NomenclatureStatus.loaded,
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

    emit(state.copyWith(status: NomenclatureStatus.loading));

    final result = await _searchNomenclatureByNameUseCase(
      SearchNomenclatureByNameParams(name),
    );

    result.fold(
      (failure) => emit(
        NomenclatureState(
          status: NomenclatureStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (nomenclatures) => emit(
        NomenclatureState(
          status: NomenclatureStatus.searchResult,
          searchResults: nomenclatures,
          searchQuery: name,
        ),
      ),
    );
  }

  /// Пошук номенклатури за артикулом
  Future<void> searchNomenclatureByArticle(String article) async {
    if (article.trim().isEmpty) {
      emit(
        const NomenclatureState(
          status: NomenclatureStatus.error,
          errorMessage: 'Артикул не може бути пустим',
        ),
      );
      return;
    }

    emit(state.copyWith(status: NomenclatureStatus.loading));

    final result = await _searchNomenclatureByArticleUseCase(
      SearchNomenclatureByArticleParams(article),
    );

    result.fold(
      (failure) => emit(
        NomenclatureState(
          status: NomenclatureStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (list) {
        if (list.isNotEmpty) {
          emit(
            NomenclatureState(
              status: NomenclatureStatus.searchResult,
              searchResults: list,
              searchQuery: article,
            ),
          );
        } else {
          emit(
            NomenclatureState(
              status: NomenclatureStatus.notFound,
              article: article,
            ),
          );
        }
      },
    );
  }

  /// Пошук номенклатури за штрихкодом
  Future<void> searchNomenclatureByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) {
      emit(
        const NomenclatureState(
          status: NomenclatureStatus.error,
          errorMessage: 'Штрихкод не може бути пустим',
        ),
      );
      return;
    }

    emit(state.copyWith(status: NomenclatureStatus.loading));

    final result = await _searchNomenclatureByBarcodeUseCase(
      SearchNomenclatureByBarcodeParams(barcode),
    );

    result.fold(
      (failure) => emit(
        NomenclatureState(
          status: NomenclatureStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (nomenclature) {
        if (nomenclature != null) {
          emit(
            NomenclatureState(
              status: NomenclatureStatus.searchResult,
              nomenclature: nomenclature,
              // article: barcode,
              searchBy: SearchParam.barcode,
            ),
          );
        } else {
          emit(
            NomenclatureState(
              status: NomenclatureStatus.notFound,
              searchBy: SearchParam.barcode,
            ),
          );
        }
      },
    );
  }

  /// Очистити пошук та повернутися до всієї номенклатури
  Future<void> clearSearch() async {
    await loadLocalNomenclature();
  }

  /// Оновити кількість номенклатури
  Future<void> refreshCount() async {
    final result = await getNomenclatureCountUseCase(const NoParams());

    result.fold(
      (failure) => emit(
        NomenclatureState(
          status: NomenclatureStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (count) {
        emit(
          NomenclatureState(
            status: NomenclatureStatus.loaded,
            totalCount: count,
          ),
        );
      },
    );
  }

  /// Перестворення локальної бази даних (виправлення проблем)
  Future<void> recreateLocalDatabase() async {
    //todo: implement повна синхронізація
    emit(
      NomenclatureState(
        status: NomenclatureStatus.error,
        errorMessage: 'Метод поки не реалізований',
      ),
    );
    // emit(NomenclatureLoading());

    // try {
    //   final localDatasource = sl<NomenclatureLocalDatasource>();
    //   await localDatasource.recreateDatabase();

    //   emit(
    //     NomenclatureTestSuccess({
    //       'status': 'success',
    //       'message': 'База даних SQLite перестворена',
    //       'action': 'recreate_database',
    //       'time': DateTime.now().toIso8601String(),
    //     }),
    //   );
    // } catch (e) {
    //   emit(NomenclatureError('Помилка перестворення локальної БД: $e'));
    // }
  }

  /// Повністю очистити локальні дані (без перестворення таблиць)
  Future<void> clearLocalData() async {
    emit(NomenclatureState(status: NomenclatureStatus.loading));
    try {
      final repository = sl<NomenclatureRepository>();
      await repository.clearLocalNomenclature();
      emit(
        NomenclatureState(
          status: NomenclatureStatus.syncSuccess,
          testResult: {
            'status': 'success',
            'message': 'Локальні дані очищено',
            'action': 'clear_local_data',
            'time': DateTime.now().toIso8601String(),
          },
        ),
      );
    } catch (e) {
      emit(
        NomenclatureState(
          status: NomenclatureStatus.error,
          errorMessage: 'Не вдалося очистити локальні дані: $e',
        ),
      );
    }
  }
}
