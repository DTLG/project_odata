import 'package:shared_preferences/shared_preferences.dart';

/// Config for Repair Request types
class RepairConfig {
  static String paidRepairTypeGuid = '1';
  static String warrantyRepairTypeGuid = '2';

  static const String _kPaid = 'repair_paid_type_guid';
  static const String _kWarranty = 'repair_warranty_type_guid';

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    paidRepairTypeGuid = prefs.getString(_kPaid) ?? paidRepairTypeGuid;
    warrantyRepairTypeGuid =
        prefs.getString(_kWarranty) ?? warrantyRepairTypeGuid;
  }

  static Future<void> saveToPrefs({String? paid, String? warranty}) async {
    final prefs = await SharedPreferences.getInstance();
    if (paid != null) {
      paidRepairTypeGuid = paid;
      await prefs.setString(_kPaid, paid);
    }
    if (warranty != null) {
      warrantyRepairTypeGuid = warranty;
      await prefs.setString(_kWarranty, warranty);
    }
  }
}
