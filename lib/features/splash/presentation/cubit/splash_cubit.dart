import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:project_odata/core/config/supabase_config.dart';
import '../../domain/usecases/bootstrap_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../main.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final BootstrapApp bootstrapApp;

  SplashCubit(this.bootstrapApp) : super(const SplashState());

  Future<void> initialize() async {
    emit(
      state.copyWith(
        status: SplashStatus.loading,
        message: 'Підготовка...',
        current: 0,
        total: 100,
      ),
    );

    try {
      final schemaOk = await _checkSchema();
      if (!schemaOk) {
        emit(
          state.copyWith(
            status: SplashStatus.askSchema,
            message: 'Схема не встановлена',
          ),
        );
        return;
      }

      // Check app version (non-blocking prompt)
      final versionOk = await _checkAppVersion();
      if (!versionOk) {
        emit(state.copyWith(needsUpdate: true));
      }

      await bootstrapApp(
        (msg, current, total) => emit(
          state.copyWith(
            status: SplashStatus.loading,
            message: msg,
            current: current,
            total: total,
          ),
        ),
      );

      // After bootstrap, check if selected agent is saved
      final hasAgent = await _hasSelectedAgent();
      emit(
        state.copyWith(
          status: SplashStatus.success,
          message: hasAgent ? 'Готово' : 'Оберіть агента',
          current: 100,
          total: 100,
          hasAgent: hasAgent,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SplashStatus.error, message: e.toString()));
    }
  }

  Future<bool> _checkSchema() async {
    final schema = SupabaseConfig.schema;
    if (schema.isNotEmpty && schema != 'public') {
      await SupabaseConfig.saveToPrefs(newSchema: schema);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _checkAppVersion() async {
    try {
      final client = Supabase.instance.client;
      final row = await client
          .schema('public')
          .from('app_version')
          .select('version')
          .limit(1)
          .maybeSingle();

      if (row == null || row['version'] == null) return true;

      final remote = (row['version'] as String).trim();

      // appVersion from main.dart; normalize to semver
      String local = appVersion.trim();

      final ok = local == remote;
      if (!ok) {
        // You may emit a state or show dialog later; for now just log
        // ignore: avoid_print
        print('App version mismatch: local=$local, remote=$remote');
      }
      return ok;
    } catch (e) {
      // ignore: avoid_print
      print('Version check failed: $e');
      return true; // fail-open
    }
  }

  Future<void> setSchema(String schema) async {
    await SupabaseConfig.saveToPrefs(newSchema: schema);
    await SupabaseConfig.loadFromPrefs();

    // після вибору схеми запускаємо initialize() ще раз
    await initialize();
  }

  Future<bool> _hasSelectedAgent() async {
    final prefs = await SharedPreferences.getInstance();
    final guid = prefs.getString('agent_guid') ?? '';
    return guid.isNotEmpty;
  }
}
