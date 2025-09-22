import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../data/datasources/local/nomenclature_local_datasource.dart';
import '../../../../core/objectbox/objectbox_entities.dart';
import '../../domain/entities/nomenclature_entity.dart';
import '../../../common/widgets/search_mode_switch.dart';

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

  // Fast in-memory caches
  final Map<String, List<BarcodeEntity>> _barcodesByNomGuid = {};
  final Map<String, List<PriceEntity>> _pricesByNomGuid = {};
  final Map<String, List<NomenclatureObx>> _childrenByParentGuidObx = {};

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
       super(NomenclatureState(status: NomenclatureStatus.initial));

  /// Load tree root (folders with parentGuid=root and isFolder=true)
  Future<void> loadRootTree() async {
    emit(state.copyWith(status: NomenclatureStatus.loading));

    final obx = sl<ObjectBox>();
    _obx = obx;
    final roots = obx.getRootNomenclature();
    // load all locally then filter roots
    final countResult = await _getNomenclatureCountUseCase(const NoParams());
    int totalCount = 0;
    countResult.fold((_) {}, (c) => totalCount = c);
    emit(
      NomenclatureState(
        status: NomenclatureStatus.treeLoaded,
        rootFolders: roots,
        childrenByParentGuid: Map<String, List<NomenclatureEntity>>.from(
          _childrenByParentGuid,
        ),
        totalCount: totalCount,
      ),
    );
    print(
      '🎯 NomenclatureCubit: Завантажено ${roots.length} номенклатури з локального сховища',
    );

    // // Виводимо перші три елементи для діагностики
    // print('🔍 Перші три контрагенти в Cubit:');
    // for (int i = 0; i < roots.length && i < 3; i++) {
    //   final kontragent = roots[i];
    //   print(
    //     '  [${i + 1}] ${kontragent.isFolder ? "📁" : "👤"} ${kontragent.name}',
    //   );
    //   print('      - GUID: ${kontragent.guid}');
    //   print('      - isFolder: ${kontragent.isFolder}');
    //   print('      - name: ${kontragent.name}');
    //   print('      - nameLower: ${kontragent.nameLower}');
    //   print('      - parentGuid: ${kontragent.parentGuid}');
    // }
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
    final cached = _childrenByParentGuidObx[parentGuid];
    if (cached != null) return cached;
    if (_obx == null) return const [];
    final list = _obx!.getChildrenNomenclature(parentGuid);
    _childrenByParentGuidObx[parentGuid] = list;
    return list;
  }

  /// Preload all barcodes and prices into memory (for instant UI mapping)
  Future<void> preloadBarcodesAndPrices() async {
    final obx = sl<ObjectBox>();
    // Barcodes
    final allBarcodes = obx.barcodeBox.getAll();
    _barcodesByNomGuid.clear();
    for (final b in allBarcodes) {
      final list = _barcodesByNomGuid[b.nomGuid] ??= <BarcodeEntity>[];
      list.add(BarcodeEntity(nomGuid: b.nomGuid, barcode: b.barcode));
    }
    // Prices
    final allPrices = obx.priceBox.getAll();
    _pricesByNomGuid.clear();
    for (final p in allPrices) {
      final list = _pricesByNomGuid[p.nomGuid] ??= <PriceEntity>[];
      list.add(
        PriceEntity(
          nomGuid: p.nomGuid,
          price: p.price,
          createdAt: p.createdAtMs != null
              ? DateTime.fromMillisecondsSinceEpoch(p.createdAtMs!)
              : null,
        ),
      );
    }
    // Sort each price history ascending by createdAt
    for (final e in _pricesByNomGuid.entries) {
      e.value.sort(
        (a, b) => (a.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
          b.createdAt?.millisecondsSinceEpoch ?? 0,
        ),
      );
    }
  }

  List<BarcodeEntity> getBarcodesFor(String nomGuid) =>
      _barcodesByNomGuid[nomGuid] ?? const <BarcodeEntity>[];
  List<PriceEntity> getPricesFor(String nomGuid) =>
      _pricesByNomGuid[nomGuid] ?? const <PriceEntity>[];

  /// Синхронізація номенклатури з сервером (з прогресом)
  Future<void> syncNomenclature() async {
    emit(state.copyWith(status: NomenclatureStatus.loading));

    try {
      final datasource = sl<SupabaseNomenclatureDatasource>();

      // Отримуємо дані з прогресом
      final nomenclatures = await datasource.syncNomenclatureWithProgress(
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

      // Очищуємо стару базу
      await repository.clearLocalNomenclature();

      emit(
        const NomenclatureState(
          status: NomenclatureStatus.loading,
          message: 'Збереження даних...',
          current: 50,
          total: 100,
        ),
      );

      // Зберігаємо нові дані
      // await repository.saveLocalNomenclature(
      // nomenclatures.map((m) => m.toEntity()).toList(),
      // nomenclatures,
      // );

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
    final result = await _getNomenclatureCountUseCase(const NoParams());

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
