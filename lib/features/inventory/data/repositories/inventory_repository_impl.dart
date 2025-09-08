import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/inventory_document.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_data_source.dart';
import '../datasources/inventory_local_data_source.dart';

/// Implementation of inventory repository
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  final InventoryLocalDataSource localDataSource;

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<InventoryDocument>>> getDocuments() async {
    try {
      // Try to get from remote first
      final remoteDocuments = await remoteDataSource.getDocuments();

      // Cache the results
      await localDataSource.cacheDocuments(remoteDocuments);

      return Right(remoteDocuments);
    } catch (e) {
      // If remote fails, try local cache
      try {
        final cachedDocuments = await localDataSource.getCachedDocuments();
        return Right(cachedDocuments);
      } catch (cacheError) {
        return Left(ServerFailure('Failed to load documents: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, InventoryDocument>> createDocument() async {
    try {
      final document = await remoteDataSource.createDocument();
      return Right(document);
    } catch (e) {
      return Left(ServerFailure('Failed to create document: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> getDocumentItems(
    String documentId,
  ) async {
    try {
      // Try to get from remote first
      final remoteItems = await remoteDataSource.getDocumentItems(documentId);

      // Cache the results
      await localDataSource.cacheDocumentItems(documentId, remoteItems);

      return Right(remoteItems);
    } catch (e) {
      // If remote fails, try local cache
      try {
        final cachedItems = await localDataSource.getCachedDocumentItems(
          documentId,
        );
        return Right(cachedItems);
      } catch (cacheError) {
        return Left(
          ServerFailure('Failed to load document items: ${e.toString()}'),
        );
      }
    }
  }

  @override
  Future<Either<Failure, InventoryItem>> addOrUpdateItem({
    required String documentId,
    required String nomenclatureId,
    required double count,
  }) async {
    try {
      final item = await remoteDataSource.addOrUpdateItem(
        documentId: documentId,
        nomenclatureId: nomenclatureId,
        count: count,
      );
      return Right(item);
    } catch (e) {
      return Left(ServerFailure('Failed to add/update item: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> closeDocument(String documentId) async {
    try {
      final result = await remoteDataSource.closeDocument(documentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Failed to close document: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InventoryItem>> setSku({
    required String documentId,
    required String barcode,
  }) async {
    try {
      final item = await remoteDataSource.setSku(
        documentId: documentId,
        barcode: barcode,
      );
      return Right(item);
    } catch (e) {
      return Left(ServerFailure('Failed to scan barcode: ${e.toString()}'));
    }
  }
}
