import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_odata/core/config/supabase_config.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'features/splash/presentation/splash_page.dart';
import 'core/services/realtime_logger.dart';
import 'core/injection/injection_container.dart';
import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Ensure latest Supabase config (url/key/schema) is loaded before init
    await SupabaseConfig.loadFromPrefs();
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('✅ Supabase ініціалізовано успішно');
    // Start realtime logging
    RealtimeLoggerService.start();
  } catch (e) {
    print('❌ Помилка ініціалізації Supabase: $e');
    // Продовжуємо роботу навіть якщо Supabase не вдалося ініціалізувати
  }
  await initializeDependencies();
  await ThemeController.instance.load();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Project OData',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const SplashPage(),
          onGenerateRoute: AppRouter.generateRoute,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
