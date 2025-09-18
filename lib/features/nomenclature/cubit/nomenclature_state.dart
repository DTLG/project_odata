import 'package:equatable/equatable.dart';
import '../../../core/entities/nomenclature_entity.dart';
import 'package:project_odata/objectbox.dart';

import '../../../core/objectbox/objectbox_entities.dart';

/// Стани для Nomenclature Cubit
abstract class NomenclatureState extends Equatable {
  const NomenclatureState();

  @override
  List<Object?> get props => [];
}

/// Початковий стан
class NomenclatureInitial extends NomenclatureState {}

/// Стан завантаження
class NomenclatureLoading extends NomenclatureState {}

/// Стан завантаження з прогресом
class NomenclatureLoadingWithProgress extends NomenclatureState {
  final String message;
  final int? current;
  final int? total;

  const NomenclatureLoadingWithProgress({
    required this.message,
    this.current,
    this.total,
  });

  @override
  List<Object?> get props => [message, current, total];
}

/// Стан успішного завантаження номенклатури (плоский список)
class NomenclatureLoaded extends NomenclatureState {
  final List<NomenclatureEntity> nomenclatures;
  final int totalCount;

  const NomenclatureLoaded({
    required this.nomenclatures,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [nomenclatures, totalCount];
}

/// Стан ієрархічного завантаження (дерево)
class NomenclatureTreeLoaded extends NomenclatureState {
  final List<NomenclatureObx> rootFolders;
  final Map<String, List<NomenclatureEntity>> childrenByParentGuid;
  final int totalCount;

  const NomenclatureTreeLoaded({
    required this.rootFolders,
    required this.childrenByParentGuid,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [rootFolders, childrenByParentGuid, totalCount];
}

/// Стан успішного пошуку номенклатури
class NomenclatureSearchResult extends NomenclatureState {
  final List<NomenclatureEntity> searchResults;
  final String searchQuery;

  const NomenclatureSearchResult({
    required this.searchResults,
    required this.searchQuery,
  });

  @override
  List<Object?> get props => [searchResults, searchQuery];
}

/// Стан успішного знаходження номенклатури за артикулом
class NomenclatureFoundByArticle extends NomenclatureState {
  final NomenclatureEntity nomenclature;
  final String article;

  const NomenclatureFoundByArticle({
    required this.nomenclature,
    required this.article,
  });

  @override
  List<Object?> get props => [nomenclature, article];
}

/// Стан коли номенклатуру не знайдено за артикулом
class NomenclatureNotFoundByArticle extends NomenclatureState {
  final String article;

  const NomenclatureNotFoundByArticle(this.article);

  @override
  List<Object?> get props => [article];
}

/// Стан успішної синхронізації
class NomenclatureSyncSuccess extends NomenclatureState {
  final int syncedCount;

  const NomenclatureSyncSuccess(this.syncedCount);

  @override
  List<Object?> get props => [syncedCount];
}

/// Стан успішного тестування підключення
class NomenclatureTestSuccess extends NomenclatureState {
  final Map<String, dynamic> testResult;

  const NomenclatureTestSuccess(this.testResult);

  @override
  List<Object?> get props => [testResult];
}

/// Стан помилки
class NomenclatureError extends NomenclatureState {
  final String message;

  const NomenclatureError(this.message);

  @override
  List<Object?> get props => [message];
}
