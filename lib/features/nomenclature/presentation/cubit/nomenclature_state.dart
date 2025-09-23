import 'package:equatable/equatable.dart';
import '../../domain/entities/nomenclature_entity.dart';
// import removed: not needed in state after switching to domain entities for tree
import '../../../common/widgets/search_mode_switch.dart';

/// Перелік можливих статусів стану
enum NomenclatureStatus {
  initial,
  loading,
  loaded,
  treeLoaded,
  searchResult,
  notFound,
  syncSuccess,
  isSyncing,
  error,
}

extension NomenclatureStatusX on NomenclatureStatus {
  bool get isInitial => this == NomenclatureStatus.initial;
  bool get isLoading => this == NomenclatureStatus.loading;
  bool get isLoaded => this == NomenclatureStatus.loaded;
  bool get isTreeLoaded => this == NomenclatureStatus.treeLoaded;
  bool get isSearchResult => this == NomenclatureStatus.searchResult;
  bool get isNotFound => this == NomenclatureStatus.notFound;
  bool get isSyncSuccess => this == NomenclatureStatus.syncSuccess;
  bool get isSyncing => this == NomenclatureStatus.isSyncing;
  bool get isError => this == NomenclatureStatus.error;
}

class NomenclatureState extends Equatable {
  final NomenclatureStatus status;

  // Для loadingWithProgress
  final String? message;
  final int? current;
  final int? total;
  final SearchParam searchBy;

  // Для loaded
  final List<NomenclatureEntity> nomenclatures;
  final int totalCount;

  // Для treeLoaded
  final List<NomenclatureEntity> rootFolders;
  final Map<String, List<NomenclatureEntity>> childrenByParentGuid;

  // Для пошуку
  final List<NomenclatureEntity> searchResults;
  final String? searchQuery;

  // Для foundByArticle
  final NomenclatureEntity? nomenclature;
  final String? article;

  // Для syncSuccess
  final int? syncedCount;

  // Для testSuccess
  final Map<String, dynamic>? testResult;

  // Для error
  final String? errorMessage;

  const NomenclatureState({
    this.status = NomenclatureStatus.initial,
    this.message,
    this.current,
    this.total,
    this.searchBy = SearchParam.name,
    this.nomenclatures = const [],
    this.totalCount = 0,
    this.rootFolders = const [],
    this.childrenByParentGuid = const {},
    this.searchResults = const [],
    this.searchQuery,
    this.nomenclature,
    this.article,
    this.syncedCount,
    this.testResult,
    this.errorMessage,
  });

  NomenclatureState copyWith({
    NomenclatureStatus? status,
    String? message,
    int? current,
    int? total,
    SearchParam? searchBy,
    List<NomenclatureEntity>? nomenclatures,
    int? totalCount,
    List<NomenclatureEntity>? rootFolders,
    Map<String, List<NomenclatureEntity>>? childrenByParentGuid,
    List<NomenclatureEntity>? searchResults,
    String? searchQuery,
    NomenclatureEntity? nomenclature,
    String? article,
    int? syncedCount,
    Map<String, dynamic>? testResult,
    String? errorMessage,
  }) {
    return NomenclatureState(
      status: status ?? this.status,
      message: message ?? this.message,
      current: current ?? this.current,
      total: total ?? this.total,
      searchBy: searchBy ?? this.searchBy,
      nomenclatures: nomenclatures ?? this.nomenclatures,
      totalCount: totalCount ?? this.totalCount,
      rootFolders: rootFolders ?? this.rootFolders,
      childrenByParentGuid: childrenByParentGuid ?? this.childrenByParentGuid,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      nomenclature: nomenclature ?? this.nomenclature,
      article: article ?? this.article,
      syncedCount: syncedCount ?? this.syncedCount,
      testResult: testResult ?? this.testResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    current,
    total,
    searchBy,
    nomenclatures,
    totalCount,
    rootFolders,
    childrenByParentGuid,
    searchResults,
    searchQuery,
    nomenclature,
    article,
    syncedCount,
    testResult,
    errorMessage,
  ];
}
