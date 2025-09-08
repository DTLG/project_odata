import 'inventory_remote_data_source.dart';
import '../models/inventory_document_model.dart';
import '../models/inventory_item_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_odata/common/shared_preferiences/sp_func.dart';
import 'package:project_odata/core/constants/app_constants.dart';

const hsPath = AppConstants.hsPath;

/// Implementation of remote data source for inventory
class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final client = http.Client();

  @override
  Future<List<InventoryDocumentModel>> getDocuments() async {
    final conn = await getdbConn();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final storageId = await getStorage();
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
    final uri = Uri.http(host, '/$dbName$hsPath${'Documents/GetList'}', {
      'storage_guid': storageId,
    });

    try {
      final nomRes = await http.get(
        uri,
        headers: {
          'Authorization': basicAuth,
          "Accept": "application/json",
          "Accept-Charset": "UTF-8",
          "Content-Type": "application/json",
        },
      );

      if (nomRes.statusCode == 200) {
        final json = jsonDecode(nomRes.body);
        return (json['docs'] as List<dynamic>)
            .map(
              (e) => InventoryDocumentModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          "${nomRes.reasonPhrase ?? ''} ${nomRes.statusCode} ${utf8.decode(nomRes.bodyBytes)}",
        );
      }
    } catch (e) {
      throw Exception(e);
    } finally {
      client.close();
    }
  }

  Future<InventoryDocumentModel> createDocument() async {
    final conn = await getdbConn();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final storageId = await getStorage();
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
    final uri = Uri.http(host, '/$dbName$hsPath${'Documents/New'}', {
      'storage_guid': storageId,
    });

    try {
      final nomRes = await http.post(
        uri,
        headers: {
          'Authorization': basicAuth,
          "Accept": "application/json",
          "Accept-Charset": "UTF-8",
          "Content-Type": "application/json",
        },
      );

      if (nomRes.statusCode == 200) {
        final json = jsonDecode(nomRes.body);
        return InventoryDocumentModel.fromJson(json);
      } else {
        throw Exception(
          "${nomRes.reasonPhrase ?? ''} ${nomRes.statusCode} ${utf8.decode(nomRes.bodyBytes)}",
        );
      }
    } catch (e) {
      throw Exception(e);
    } finally {
      client.close();
    }
  }

  // @override
  // Future<InventoryDocumentModel> createDocument() async {
  //   // TODO: Implement actual API call
  //   await Future.delayed(const Duration(seconds: 1));

  //   return InventoryDocumentModel(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     number: 'INV-${DateTime.now().millisecondsSinceEpoch}',
  //     date: DateTime.now().toIso8601String().split('T')[0],
  //   );
  // }

  Future<List<InventoryItemModel>> getDocumentItems(String documentId) async {
    final conn = await getdbConn();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
    final uri = Uri.http(host, '/$dbName$hsPath${'Documents/GetData'}', {
      "doc_guid": documentId,
    });

    try {
      final nomRes = await http.get(
        uri,
        headers: {
          'Authorization': basicAuth,
          "Accept": "application/json",
          "Accept-Charset": "UTF-8",
          "Content-Type": "application/json",
        },
      );
      if (nomRes.statusCode == 200) {
        final json = jsonDecode(utf8.decode(nomRes.bodyBytes));
        return (json['noms'] as List<dynamic>)
            .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          "${nomRes.reasonPhrase ?? ''} ${nomRes.statusCode} ${utf8.decode(nomRes.bodyBytes)}",
        );
      }
    } catch (e) {
      throw Exception(e);
    } finally {
      client.close();
    }
  }

  // @override
  // Future<List<InventoryItemModel>> getDocumentItems(String documentId) async {
  //   // TODO: Implement actual API call
  //   await Future.delayed(const Duration(seconds: 1));

  //   return [
  //     InventoryItemModel(
  //       id: '1',
  //       documentId: documentId,
  //       nomenclatureId: 'nom-1',
  //       name: 'Товар 1',
  //       article: 'ART-001',
  //       unit: 'шт',
  //       count: 10.0,
  //       createdAt: DateTime.now(),
  //     ),
  //     InventoryItemModel(
  //       id: '2',
  //       documentId: documentId,
  //       nomenclatureId: 'nom-2',
  //       name: 'Товар 2',
  //       article: 'ART-002',
  //       unit: 'кг',
  //       count: 5.5,
  //       createdAt: DateTime.now(),
  //     ),
  //   ];
  // }

  @override
  Future<InventoryItemModel> addOrUpdateItem({
    required String documentId,
    required String nomenclatureId,
    required double count,
  }) async {
    final conn = await getdbConn();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
    final uri = Uri.http(host, '/$dbName$hsPath${'Documents/SetSkuCount'}', {
      "doc_guid": documentId,
      "nom_guid": nomenclatureId,
      "count": count.toString(),
    });

    try {
      final nomRes = await http.post(
        uri,
        headers: {
          'Authorization': basicAuth,
          "Accept": "application/json",
          "Accept-Charset": "UTF-8",
          "Content-Type": "application/json",
        },
      );

      if (nomRes.statusCode == 200) {
        final json = jsonDecode(utf8.decode(nomRes.bodyBytes));
        return InventoryItemModel.fromJson(json);
      } else {
        throw Exception(
          "${nomRes.reasonPhrase ?? ''} ${nomRes.statusCode} ${utf8.decode(nomRes.bodyBytes)}",
        );
      }
    } catch (e) {
      throw Exception(e);
    } finally {
      client.close();
    }
  }

  @override
  Future<bool> closeDocument(String documentId) async {
    final conn = await getdbConn();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
    final uri = Uri.http(host, '/$dbName$hsPath${'Documents/Close'}', {
      "doc_guid": documentId,
    });

    try {
      final nomRes = await http.post(
        uri,
        headers: {
          'Authorization': basicAuth,
          "Accept": "application/json",
          "Accept-Charset": "UTF-8",
          "Content-Type": "application/json",
        },
      );

      if (nomRes.statusCode == 200) {
        final json = jsonDecode(utf8.decode(nomRes.bodyBytes));
        return true;
      } else {
        throw Exception(
          "${nomRes.reasonPhrase ?? ''} ${nomRes.statusCode} ${utf8.decode(nomRes.bodyBytes)}",
        );
      }
    } catch (e) {
      throw Exception(e);
    } finally {
      client.close();
    }
  }

  @override
  Future<InventoryItemModel> setSku({
    required String documentId,
    required String barcode,
  }) async {
    final conn = await getdbConn();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
    final uri = Uri.http(host, '/$dbName$hsPath${'Documents/SetSku'}', {
      'doc_guid': documentId,
      'barcode': barcode,
    });

    try {
      final res = await http.post(
        uri,
        headers: {
          'Authorization': basicAuth,
          'Accept': 'application/json',
          'Accept-Charset': 'UTF-8',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return InventoryItemModel.fromJson(jsonMap);
      } else {
        throw Exception(
          '${res.reasonPhrase ?? ''} ${res.statusCode} ${utf8.decode(res.bodyBytes)}',
        );
      }
    } catch (e) {
      throw Exception(e);
    } finally {
      client.close();
    }
  }
}
