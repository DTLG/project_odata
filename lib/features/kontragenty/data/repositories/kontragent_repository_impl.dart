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
  Future<Either<Failure, List<KontragentEntity>>> syncKontragenty() async {
    try {
      print('🔄 Починаємо синхронізацію контрагентів...');

      // Get data from remote
      print('📡 Отримуємо дані з віддаленого джерела...');
      final remoteKontragenty = await remoteDataSource.getAllKontragenty();
      print(
        '📊 Отримано ${remoteKontragenty.length} контрагентів з віддаленого джерела',
      );

      // Debug: find and print duplicates by GUID
      final Map<String, List<KontragentEntity>> byGuidAll = {};
      for (final k in remoteKontragenty) {
        final key = (k.guid).trim();
        (byGuidAll[key] ??= []).add(k);
      }
      int dupGroups = 0;
      int dupItems = 0;
      byGuidAll.forEach((guid, list) {
        if (guid.isEmpty) return;
        if (list.length > 1) {
          dupGroups++;
          dupItems += list.length;
          print('🔁 DUP GUID=$guid x${list.length}');
          for (int i = 0; i < list.length; i++) {
            final it = list[i];
            print(
              '   • [$i] name="${it.name}" parentGuid=${it.parentGuid} isFolder=${it.isFolder}',
            );
          }
        }
      });
      if (dupGroups > 0) {
        print(
          '⚠️ Знайдено груп дублікатів: $dupGroups, елементів у них: $dupItems',
        );
      } else {
        print('✅ Дублікатів по GUID не знайдено');
      }

      // Deduplicate by GUID to avoid duplicates
      final Map<String, KontragentEntity> byGuid = {
        for (final k in remoteKontragenty) k.guid: k,
      };

      // Save to local storage (replace existing)
      print('💾 Очищаємо та зберігаємо дані в локальне сховище...');
      await localDataSource.clearAllData();
      await localDataSource.insertKontragenty(
        byGuid.values.map((e) => KontragentModel.fromEntity(e)).toList(),
      );
      print('✅ Синхронізація завершена успішно');

      return Right(remoteKontragenty);
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
