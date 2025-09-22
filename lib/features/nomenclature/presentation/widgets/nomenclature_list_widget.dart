import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/nomenclature_entity.dart';
import '../cubit/nomenclature_cubit.dart';
import '../cubit/nomenclature_state.dart';
import 'nomenclature_item_widget.dart';
import '../../../common/widgets/search_mode_switch.dart';

/// Віджет для відображення списку номенклатури
class NomenclatureListWidget extends StatelessWidget {
  const NomenclatureListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NomenclatureCubit, NomenclatureState>(
      builder: (context, state) {
        if (state.status.isInitial) {
          return const Center(
            child: Text(
              'Натисніть кнопку синхронізації для завантаження даних',
            ),
          );
        }

        if (state.status.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status.isError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Помилка',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    state.message ?? '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<NomenclatureCubit>().loadLocalNomenclature(),
                  child: const Text('Спробувати знову'),
                ),
              ],
            ),
          );
        }

        if (state.status.isSyncSuccess) {
          // Після успішної синхронізації завантажуємо дані
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<NomenclatureCubit>().loadLocalNomenclature();
          });
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Синхронізацію завершено',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('Синхронізовано ${state.syncedCount} записів'),
              ],
            ),
          );
        }

        if (state.status.isLoaded && state.searchBy == SearchParam.article) {
          return _buildSingleItemView(
            context,
            state.nomenclature!,
            'Знайдено за артикулом: ${state.article}',
          );
        }

        if (state.status.isNotFound && state.searchBy == SearchParam.article) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Не знайдено',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('Номенклатуру з артикулом "${state.article}" не знайдено'),
              ],
            ),
          );
        }

        if (state.status.isLoaded) {
          return _buildNomenclatureList(
            context,
            state.nomenclatures,
            'Завантажено ${state.nomenclatures.length} з ${state.totalCount} записів',
          );
        }

        if (state.status.isSearchResult) {
          return _buildNomenclatureList(
            context,
            state.searchResults,
            'Знайдено ${state.searchResults.length} записів за запитом: "${state.searchQuery}"',
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildSingleItemView(
    BuildContext context,
    NomenclatureEntity nomenclature,
    String subtitle,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ),
        NomenclatureItemWidget(nomenclature: nomenclature),
        const Spacer(),
      ],
    );
  }

  Widget _buildNomenclatureList(
    BuildContext context,
    List<NomenclatureEntity> nomenclatures,
    String subtitle,
  ) {
    if (nomenclatures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Номенклатура відсутня',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text('Синхронізуйте дані з сервером'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: nomenclatures.length,
            itemBuilder: (context, index) {
              return NomenclatureItemWidget(nomenclature: nomenclatures[index]);
            },
          ),
        ),
      ],
    );
  }
}
