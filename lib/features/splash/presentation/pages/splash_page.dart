import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_router.dart';
import '../cubit/splash_cubit.dart';
import '../../../../core/injection/injection_container.dart';
import '../dialog/ask_schema_dialog.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SplashCubit>()..initialize(),
      child: BlocConsumer<SplashCubit, SplashState>(
        listener: (context, state) async {
          if (state.status == SplashStatus.success) {
            AppRouter.navigateToAndReplace(context, AppRouter.home);
          } else if (state.status == SplashStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Помилка: ${state.message}')),
            );
            AppRouter.navigateToAndReplace(context, AppRouter.home);
          } else if (state.status == SplashStatus.askSchema) {
            await askSchema(context, context.read<SplashCubit>().setSchema);
          }
        },
        builder: (context, state) {
          final progress = state.total > 0 ? state.current / state.total : 0.0;
          final percentage = (progress * 100).round();

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Прогрес бар
                  Container(
                    width: 200,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.current} з ${state.total}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
