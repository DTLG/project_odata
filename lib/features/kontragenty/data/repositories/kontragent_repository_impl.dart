import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/kontragent_entity.dart';
import '../../domain/repositories/kontragent_repository.dart';
import '../datasources/kontragent_remote_data_source.dart';
import '../datasources/kontragent_local_data_source.dart';
import '../models/kontragent_model.dart';

/// Implementation of kontragent repository
class KontragentRepositoryImpl implements KontragentRepository {
  final KontragentRemoteDataSource remoteDataSource;
  final KontragentLocalDataSource localDataSource;

  KontragentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<KontragentEntity>>> syncKontragenty({
    Function(String message, int current, int total)? onProgress,
  }) async {
    try {
      print('🔄 Починаємо синхронізацію контрагентів...');
      const int pageSize = 1000;
      int offset = 0;
      int totalLoaded = 0;
      final List<KontragentEntity> all = [];

      while (true) {
        final chunk = await remoteDataSource.getKontragentyChunk(
          lastId: offset,
          limit: pageSize,
        );
        // final chunk = await remoteDataSource.getAllKontragenty(
        //   offset,
        //   pageSize,
        // );
        if (chunk.isEmpty) break;

        // Дедуплікація на рівні поточного чанку
        final Map<String, KontragentEntity> byGuid = {
          for (final k in chunk) k.guid.trim(): k,
        };

        // Збереження порціями (upsert)
        await localDataSource.insertKontragenty(
          byGuid.values.map((e) => KontragentModel.fromEntity(e)).toList(),
        );

        all.addAll(byGuid.values);
        totalLoaded += byGuid.length;
        offset += pageSize;

        onProgress?.call('Завантажено $totalLoaded...', totalLoaded, 0);
        print('📦 Завантажено $totalLoaded контрагентів...');
      }

      print('✅ Синхронізація завершена успішно');
      return Right(all);
    } catch (e) {
      print('❌ Помилка синхронізації: $e');
      return Left(ServerFailure('Failed to sync kontragenty: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<KontragentEntity>>> getLocalKontragenty() async {
    try {
      final kontragenty = await localDataSource.getAllKontragenty();
      return Right(kontragenty);
    } catch (e) {
      return Left(
        CacheFailure('Failed to get local kontragenty: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<KontragentEntity>>> searchByName(
    String query,
  ) async {
    try {
      final kontragenty = await localDataSource.searchByName(query);
      return Right(kontragenty);
    } catch (e) {
      return Left(
        CacheFailure('Failed to search kontragenty by name: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<KontragentEntity>>> searchByEdrpou(
    String query,
  ) async {
    try {
      final kontragenty = await localDataSource.searchByEdrpou(query);
      return Right(kontragenty);
    } catch (e) {
      return Left(
        CacheFailure('Failed to search kontragenty by EDRPOU: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<KontragentEntity>>> getRootFolders() async {
    try {
      final folders = await localDataSource.getRootFolders();
      return Right(folders);
    } catch (e) {
      return Left(CacheFailure('Failed to get root folders: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<KontragentEntity>>> getChildren(
    String parentGuid,
  ) async {
    try {
      final children = await localDataSource.getChildren(parentGuid);
      return Right(children);
    } catch (e) {
      return Left(CacheFailure('Failed to get children: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getKontragentyCount() async {
    try {
      final count = await localDataSource.getKontragentyCount();
      return Right(count);
    } catch (e) {
      return Left(
        CacheFailure('Failed to get kontragenty count: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> clearLocalData() async {
    try {
      print('🗑️ Repository: Починаємо очищення локальних даних...');
      await localDataSource.clearAllData();
      print('✅ Repository: Очищення локальних даних завершено');
      return Right(true);
    } catch (e) {
      print('❌ Repository: Помилка очищення локальних даних: $e');
      return Left(CacheFailure('Failed to clear local data: ${e.toString()}'));
    }
  }
}
