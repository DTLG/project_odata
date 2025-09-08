import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Helper клас для ініціалізації SQLite на різних платформах
class SqliteHelper {
  static bool _initialized = false;

  /// Ініціалізація SQLite для всіх платформ
  static Future<void> initialize() async {
    if (_initialized) return;

    // Ініціалізація для desktop платформ (Windows, Linux, macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Ініціалізуємо FFI для desktop
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('✅ SQLite ініціалізовано для desktop платформи');
    } else {
      // На мобільних платформах (Android, iOS) SQLite працює з коробки
      print('✅ SQLite готовий для мобільної платформи');
    }

    _initialized = true;
  }

  /// Перевірка чи ініціалізований SQLite
  static bool get isInitialized => _initialized;
}
