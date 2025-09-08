import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static const String _kThemeModeKey = 'theme_mode';

  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Read raw value to support legacy types (e.g., bool)
    final Object? raw = prefs.get(_kThemeModeKey);

    String? value;
    if (raw is String) {
      value = raw;
    } else if (raw is bool) {
      // Legacy: map true -> dark, false -> light and migrate to string
      value = raw ? 'dark' : 'light';
      await prefs.setString(_kThemeModeKey, value);
    } else {
      value = null;
    }

    switch (value) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeModeNotifier.value = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kThemeModeKey,
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system',
    );
  }
}
