import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_odata/common/shared_preferiences/db_conn.dart';

Future<DbConn> getdbConn() async {
  final prefs = await SharedPreferences.getInstance();
  final host = prefs.getString('host') ?? '';
  final dbName = prefs.getString('db_name') ?? '';
  final user = prefs.getString('user') ?? '';
  final pass = prefs.getString('pass') ?? '';
  return DbConn(host: host, dbName: dbName, user: user, pass: pass);
}

Future<String> getSchema() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('supabase_schema') ?? '';
}

Future<void> setSchema(String schema) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('supabase_schema', schema);
}

Future<String> getStorage() async {
  final prefs = await SharedPreferences.getInstance();

  final id =
      prefs.getString('storageId') ?? '00000000-0000-0000-0000-000000000000';
  return id;
}

Future<Map<String, String>> getPriceAndPackType() async {
  final prefs = await SharedPreferences.getInstance();

  final priceTypeKey =
      prefs.getString('priceTypeKey') ?? '00000000-0000-0000-0000-000000000000';
  final packtypeKey =
      prefs.getString('packTypeKey') ?? '00000000-0000-0000-0000-000000000000';

  return {"packTypeKey": packtypeKey, "priceTypeKey": priceTypeKey};
}

Future<String> getPriceType() async {
  final prefs = await SharedPreferences.getInstance();
  final priceTypeKey = prefs.getString('priceTypeKey') ?? '';
  return priceTypeKey;
}

Future<int> getPrinterDarknessIndex() async {
  final prefs = await SharedPreferences.getInstance();
  final darknessIndex = prefs.getInt('darkness') ?? 2;
  return darknessIndex;
}

Future<int> getPrinterDarkness() async {
  final darknessIndex = await getPrinterDarknessIndex();
  final darkness = switch (darknessIndex) {
    int() =>
      darknessIndex == 2
          ? 2
          : darknessIndex == 1
          ? -2
          : 10,
  };

  return darkness;
}
