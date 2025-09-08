import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/kontragent_entity.dart';
import '../../domain/usecases/sync_kontragenty_usecase.dart';
import '../../domain/usecases/get_local_kontragenty_usecase.dart';
import '../../domain/usecases/search_kontragenty_by_name_usecase.dart';
import '../../domain/usecases/search_kontragenty_by_edrpou_usecase.dart';
import '../../domain/usecases/get_root_folders_usecase.dart';
import '../../domain/usecases/get_children_usecase.dart';
import '../../domain/usecases/get_kontragenty_count_usecase.dart';
import '../../domain/usecases/clear_local_data_usecase.dart';
import '../../../../core/usecases/usecase.dart';

part 'kontragent_state.dart';

/// Cubit for managing kontragent state
class KontragentCubit extends Cubit<KontragentState> {
  final SyncKontragentyUseCase syncKontragentyUseCase;
  final GetLocalKontragentyUseCase getLocalKontragentyUseCase;
  final SearchKontragentyByNameUseCase searchKontragentyByNameUseCase;
  final SearchKontragentyByEdrpouUseCase searchKontragentyByEdrpouUseCase;
  final GetRootFoldersUseCase getRootFoldersUseCase;
  final GetChildrenUseCase getChildrenUseCase;
  final GetKontragentyCountUseCase getKontragentyCountUseCase;
  final ClearLocalDataUseCase clearLocalDataUseCase;

  // Cache for hierarchical data
  final Map<String, List<KontragentEntity>> _childrenByParentGuid = {};

  KontragentCubit({
    required this.syncKontragentyUseCase,
    required this.getLocalKontragentyUseCase,
    required this.searchKontragentyByNameUseCase,
    required this.searchKontragentyByEdrpouUseCase,
    required this.getRootFoldersUseCase,
    required this.getChildrenUseCase,
    required this.getKontragentyCountUseCase,
    required this.clearLocalDataUseCase,
  }) : super(KontragentInitial());

  /// Sync kontragenty from remote to local storage
  Future<void> syncKontragenty() async {
    print('🚀 KontragentCubit: Починаємо синхронізацію...');
    emit(KontragentLoading());

    final result = await syncKontragentyUseCase(NoParams());

    result.fold(
      (failure) {
        print('❌ KontragentCubit: Помилка синхронізації: ${failure.message}');
        emit(KontragentError(failure.message));
      },
      (kontragenty) {
        print(
          '✅ KontragentCubit: Синхронізація завершена, отримано ${kontragenty.length} записів',
        );
        _buildHierarchy(kontragenty);
        emit(KontragentLoaded(kontragenty));
      },
    );
  }

  /// Load kontragenty from local storage
  Future<void> loadLocalKontragenty() async {
    emit(KontragentLoading());

    final result = await getLocalKontragentyUseCase(NoParams());

    result.fold((failure) => emit(KontragentError(failure.message)), (
      kontragenty,
    ) {
      print(
        '🎯 KontragentCubit: Завантажено ${kontragenty.length} контрагентів з локального сховища',
      );

      // Виводимо перші три елементи для діагностики
      print('🔍 Перші три контрагенти в Cubit:');
      for (int i = 0; i < kontragenty.length && i < 3; i++) {
        final kontragent = kontragenty[i];
        print(
          '  [${i + 1}] ${kontragent.isFolder ? "📁" : "👤"} ${kontragent.name}',
        );
        print('      - GUID: ${kontragent.guid}');
        print('      - isFolder: ${kontragent.isFolder}');
        print('      - parentGuid: ${kontragent.parentGuid}');
      }

      _buildHierarchy(kontragenty);
      emit(KontragentLoaded(kontragenty));
    });
  }

  /// Search kontragenty by name
  Future<void> searchByName(String query) async {
    if (query.isEmpty) {
      loadLocalKontragenty();
      return;
    }

    // emit(KontragentLoading());

    final result = await searchKontragentyByNameUseCase(query);

    result.fold(
      (failure) => emit(KontragentError(failure.message)),
      (kontragenty) => emit(KontragentLoaded(kontragenty)),
    );
  }

  /// Search kontragenty by EDRPOU
  Future<void> searchByEdrpou(String query) async {
    if (query.isEmpty) {
      loadLocalKontragenty();
      return;
    }

    emit(KontragentLoading());

    final result = await searchKontragentyByEdrpouUseCase(query);

    result.fold(
      (failure) => emit(KontragentError(failure.message)),
      (kontragenty) => emit(KontragentLoaded(kontragenty)),
    );
  }

  /// Load root elements (folders and kontragenty with no parent) for hierarchical view
  Future<void> loadRootFolders() async {
    emit(KontragentLoading());

    final result = await getRootFoldersUseCase(NoParams());

    result.fold((failure) => emit(KontragentError(failure.message)), (folders) {
      print(
        '🎯 KontragentCubit: Завантажено ${folders.length} кореневих елементів',
      );

      // Виводимо перші три елементи для діагностики
      print('🔍 Перші три кореневі елементи в Cubit:');
      for (int i = 0; i < folders.length && i < 3; i++) {
        final folder = folders[i];
        print('  [${i + 1}] ${folder.isFolder ? "📁" : "👤"} ${folder.name}');
        print('      - GUID: ${folder.guid}');
        print('      - isFolder: ${folder.isFolder}');
        print('      - parentGuid: ${folder.parentGuid}');
      }

      emit(KontragentTreeLoaded(folders));
    });
  }

  /// Get children by parent GUID
  List<KontragentEntity> getChildren(String parentGuid) {
    return _childrenByParentGuid[parentGuid] ?? [];
  }

  /// Clear local data
  Future<void> clearLocalData() async {
    print('🗑️ KontragentCubit: Починаємо очищення локальних даних...');
    final result = await clearLocalDataUseCase(NoParams());

    result.fold(
      (failure) {
        print('❌ KontragentCubit: Помилка очищення: ${failure.message}');
        emit(KontragentError(failure.message));
      },
      (_) {
        print('✅ KontragentCubit: Очищення завершено успішно');
        emit(KontragentInitial());
      },
    );
  }

  /// Build hierarchy from flat list
  void _buildHierarchy(List<KontragentEntity> kontragenty) {
    _childrenByParentGuid.clear();

    for (final kontragent in kontragenty) {
      final parentGuid = kontragent.parentGuid;
      if (!_childrenByParentGuid.containsKey(parentGuid)) {
        _childrenByParentGuid[parentGuid] = [];
      }
      _childrenByParentGuid[parentGuid]!.add(kontragent);
    }
  }
}
