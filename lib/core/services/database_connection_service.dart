import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing database connection settings
class DatabaseConnectionService {
  static const String _hostKey = 'host';
  static const String _dbNameKey = 'db_name';
  static const String _userKey = 'user';
  static const String _passKey = 'pass';

  /// Get database connection settings from SharedPreferences
  static Future<DatabaseConnection> getConnection() async {
    final prefs = await SharedPreferences.getInstance();

    return DatabaseConnection(
      host: prefs.getString(_hostKey) ?? 'localhost',
      dbName: prefs.getString(_dbNameKey) ?? 'default_db',
      user: prefs.getString(_userKey) ?? 'admin',
      pass: prefs.getString(_passKey) ?? 'password',
    );
  }

  /// Save database connection settings to SharedPreferences
  static Future<void> saveConnection(DatabaseConnection connection) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_hostKey, connection.host);
    await prefs.setString(_dbNameKey, connection.dbName);
    await prefs.setString(_userKey, connection.user);
    await prefs.setString(_passKey, connection.pass);
  }
}

/// Database connection model
class DatabaseConnection {
  final String host;
  final String dbName;
  final String user;
  final String pass;

  const DatabaseConnection({
    required this.host,
    required this.dbName,
    required this.user,
    required this.pass,
  });
}
