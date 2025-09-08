import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing order-specific settings
class OrderSettingsService {
  static const String _kontagentIdKey = 'kontagentId';
  static const String _storageIdKey = 'storageId';
  static const String _ofertaKey = 'oferta';

  /// Get kontagent ID from SharedPreferences
  static Future<String> getKontagentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kontagentIdKey) ?? '';
  }

  /// Save kontagent ID to SharedPreferences
  static Future<void> setKontagentId(String kontagentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kontagentIdKey, kontagentId);
  }

  /// Get storage ID
  static Future<String> getStorageId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageIdKey) ?? '';
  }

  /// Save storage ID
  static Future<void> setStorageId(String storageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageIdKey, storageId);
  }

  /// Save oferta (agreement) for kontagent
  static Future<void> setOferta(String kontagentId, String oferta) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_ofertaKey}_$kontagentId', oferta);
  }
}
