import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';

  // Збереження налаштування теми
  Future<void> saveThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  // Отримання збереженого налаштування теми
  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false; // За замовчуванням світла тема
  }

  // Скидання налаштувань теми
  Future<void> resetThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }
}
