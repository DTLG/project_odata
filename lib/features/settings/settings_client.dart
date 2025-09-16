import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_odata/features/settings/models/price_type.dart';
import 'package:project_odata/features/settings/models/storage_model.dart';
import 'package:project_odata/common/shared_preferiences/sp_func.dart';
import 'package:project_odata/common/shared_preferiences/sp_func.dart';
import 'package:http/http.dart' as http;
import 'package:project_odata/core/constants/app_constants.dart';

class SettingsClient {
  final client = http.Client();

  Future<Storages> getListStorage() async {
    final conn = await getdbConn();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

    try {
      final res = await http.get(
        Uri.http(
          host,
          "/$dbName${AppConstants.odataPath}Catalog_Склады?\$format=json",
        ),
        headers: {'Authorization': basicAuth, 'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return Storages.fromJson(json);
      } else {
        throw Exception('HTTP request failed with status ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending request: $e');
    } finally {
      client.close();
    }
  }

  Future<List<PriceType>> getPiceType() async {
    final conn = await getdbConn();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

    try {
      final res = await http.get(
        Uri.http(
          host,
          "/$dbName${AppConstants.odataPath}Catalog_ВидыЦен?\$format=json&\$select=Ref_Key,Description",
        ),
        headers: {'Authorization': basicAuth, 'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return PriceType.fromJsonList(json['value']);
      } else {
        throw Exception('HTTP request failed with status ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Немає з\'єднання з сервером 1с');
      // throw Exception('Error sending request: $e');
    } finally {
      client.close();
    }
  }

  Future<void> setQueryParameters() async {
    final conn = await getdbConn();
    final host = conn.host;
    final dbName = conn.dbName;
    final user = conn.user;
    final pass = conn.pass;
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

    final packRes = await http.get(
      Uri.http(
        host,
        "/$dbName${AppConstants.odataPath}Catalog_НаборыУпаковок?\$format=json&\$filter=Description eq 'Шт'",
      ),

      // Uri.parse(
      //     "${baseUrl}Catalog_НаборыУпаковок?\$format=json&\$filter=Description eq 'Шт'"),
      headers: {'Authorization': basicAuth, 'Accept': 'application/json'},
    );
    final priceTypeRes = await http.get(
      Uri.http(
        host,
        "/$dbName${AppConstants.odataPath}Catalog_ВидыЦен?\$format=json&\$filter=Description eq 'Ціна'",
      ),

      // Uri.parse(
      //     "${baseUrl}Catalog_ВидыЦен?\$format=json&\$filter=Description eq 'Ціна'"),
      headers: {'Authorization': basicAuth, 'Accept': 'application/json'},
    );

    final packJson = await jsonDecode(packRes.body);
    final packTypeKey = await packJson['value'][0]["Ref_Key"] ?? '';
    final priceTypeJson = await jsonDecode(priceTypeRes.body);
    final priceTypeKey = await priceTypeJson['value'][0]["Ref_Key"] ?? '';
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('packTypeKey', packTypeKey);
    prefs.setString('priceTypeKey', priceTypeKey);

    client.close();
  }
}
