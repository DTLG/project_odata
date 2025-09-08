import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../config/order_config.dart';
import 'database_connection_service.dart';
import 'order_settings_service.dart';

/// Service for creating orders in the database
class OrderCreationService {
  OrderCreationService();

  /// Create order in the database
  Future<void> createOrder(
    String clientGuid,
    List<Map<String, dynamic>> goodsList,
  ) async {
    final conn = await DatabaseConnectionService.getConnection();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final storageId = await OrderSettingsService.getStorageId();

    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

    try {
      final oferta = await getOferta(clientGuid);

      final body = jsonEncode({
        "Date": DateTime.now().toIso8601String(),
        "Posted": OrderConfig.defaultPosted,
        "DeletionMark": OrderConfig.defaultDeletionMark,
        "Контрагент_Key": clientGuid,
        "Партнер_Key": clientGuid,
        "Соглашение_Key": oferta,
        "Склад_Key": storageId,
        "ЖелаемаяДатаОтгрузки": DateTime.now().toIso8601String(),
        "ДатаОтгрузки": DateTime.now().toIso8601String(),
        "ЦенаВключаетНДС": OrderConfig.defaultPriceIncludesVAT,
        "АвторасчетНДС": OrderConfig.defaultAutoCalculateVAT,
        "Статус": OrderConfig.defaultStatus,
        "ХозяйственнаяОперация": OrderConfig.defaultBusinessOperation,
        "ДокументОснование_Type": OrderConfig.defaultDocumentBaseType,
        "Согласован": OrderConfig.defaultAgreed,
        "Организация_Key": OrderConfig.organizationKey,
        "Товары": goodsList,
      });

      final client = http.Client();
      final response = await client.post(
        Uri.http(
          host,
          "/$dbName${OrderConfig.odataPath}Document_ЗаказКлиента?\$format=json",
        ),
        headers: {
          'Authorization': basicAuth,
          "Accept": "application/json",
          "Accept-Charset": "UTF-8",
          "Content-Type": "application/json",
        },
        body: body,
      );

      if (response.statusCode == 201) {
        await _clearLocalOrders();
      } else {
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    } finally {
      // client is closed where created й
    }
  }

  Future<String> getOferta(String clientGuid) async {
    final conn = await DatabaseConnectionService.getConnection();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

    try {
      final client = http.Client();
      final res = await client.get(
        Uri.http(
          host,
          "/$dbName${OrderConfig.odataPath}Catalog_СоглашенияСКлиентами?\$format=json&\$top=10&\$filter=Контрагент_Key eq guid'$clientGuid'and Статус eq 'Действует'",
        ),

        // Uri.parse(
        //     "${baseUrl}Catalog_СоглашенияСКлиентами?\$format=json&\$top=10&\$filter=Контрагент_Key eq guid'$clientGuid'and Статус eq 'Действует'"),
        headers: {
          'Authorization': basicAuth,
          "Accept": "application/json",
          "Accept-Charset": "UTF-8",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        Map json = jsonDecode(res.body);
        return (json['value'] as List).isEmpty
            ? '00000000-0000-0000-0000-000000000000'
            : json['value'][0]['Ref_Key'];
      } else {
        throw Exception('Помилка HTTP-запиту зі статусом ${res.statusCode}');
      }
    } catch (e) {
      throw Exception(e);
    } finally {
      // client is closed where created
    }
  }

  /// Clear local orders from SQLite database
  Future<void> _clearLocalOrders() async {
    try {
      final database = await openDatabase('app_database.db');
      await database.rawQuery('DELETE FROM ${OrderConfig.ordersTable}');
      await database.close();
    } catch (e) {
      // Log error but don't throw - order was created successfully
      print('Warning: Failed to clear local orders: $e');
    }
  }

  /// This service now uses per-call HTTP clients; no global client to dispose.
  void dispose() {}
}
