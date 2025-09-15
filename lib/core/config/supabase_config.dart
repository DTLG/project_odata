import 'package:shared_preferences/shared_preferences.dart';

/// Конфігурація для Supabase
/// УВАГА: Замініть ці значення на ваші реальні дані з Supabase
class SupabaseConfig {
  static String supabaseUrl = 'https://ygrfbkojpzybjhxbpzfq.supabase.co';
  static String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlncmZia29qcHp5YmpoeGJwemZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyODA2MTYsImV4cCI6MjA3MTg1NjYxNn0.xEN2MDMf3DcPkPtQxU3Ydy_8rVLIpZ6N_MaM4mnNeqc';
  static String schema = 'public';

  static const String _kUrl = 'supabase_url';
  static const String _kKey = 'supabase_anon_key';
  static const String _kSchema = 'supabase_schema';

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    supabaseUrl = prefs.getString(_kUrl) ?? supabaseUrl;
    supabaseAnonKey = prefs.getString(_kKey) ?? supabaseAnonKey;
    schema = prefs.getString(_kSchema) ?? schema;
  }

  static Future<void> saveToPrefs({
    String? url,
    String? anonKey,
    String? newSchema,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      supabaseUrl = url;
      await prefs.setString(_kUrl, url);
    }
    if (anonKey != null) {
      supabaseAnonKey = anonKey;
      await prefs.setString(_kKey, anonKey);
    }
    if (newSchema != null) {
      schema = newSchema;
      await prefs.setString(_kSchema, newSchema);
    }
  }
}
