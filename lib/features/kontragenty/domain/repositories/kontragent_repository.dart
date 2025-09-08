import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/kontragent_entity.dart';

/// Repository interface for kontragent operations
abstract class KontragentRepository {
  /// Sync kontragenty from remote to local storage
  Future<Either<Failure, List<KontragentEntity>>> syncKontragenty();

  /// Get all kontragenty from local storage
  Future<Either<Failure, List<KontragentEntity>>> getLocalKontragenty();

  /// Search kontragenty by name
  Future<Either<Failure, List<KontragentEntity>>> searchByName(String query);

  /// Search kontragenty by EDRPOU
  Future<Either<Failure, List<KontragentEntity>>> searchByEdrpou(String query);

  /// Get root folders (isFolder=true, parentGuid=root)
  Future<Either<Failure, List<KontragentEntity>>> getRootFolders();

  /// Get children by parent GUID
  Future<Either<Failure, List<KontragentEntity>>> getChildren(
    String parentGuid,
  );

  /// Get kontragenty count
  Future<Either<Failure, int>> getKontragentyCount();

  /// Clear local data
  Future<Either<Failure, bool>> clearLocalData();
}
