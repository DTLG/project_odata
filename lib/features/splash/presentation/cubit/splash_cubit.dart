import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:project_odata/core/config/supabase_config.dart';
import '../../domain/usecases/bootstrap_app.dart';

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

      emit(
        state.copyWith(
          status: SplashStatus.success,
          message: 'Готово',
          current: 100,
          total: 100,
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

  Future<void> setSchema(String schema) async {
    await SupabaseConfig.saveToPrefs(newSchema: schema);
    await SupabaseConfig.loadFromPrefs();

    // після вибору схеми запускаємо initialize() ще раз
    await initialize();
  }
}
