import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/kontragent_cubit.dart';
import '../widgets/kontragent_search_widget.dart';
import '../widgets/kontragent_item_widget.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/config/supabase_config.dart';

/// Page for displaying kontragenty
class KontragentPage extends StatelessWidget {
  const KontragentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<KontragentCubit>(),
      child: const _KontragentView(),
    );
  }
}

class _KontragentView extends StatelessWidget {
  const _KontragentView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контрагенти'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<KontragentCubit>().syncKontragenty();
            },
            icon: const Icon(Icons.sync),
            tooltip: 'Синхронізувати',
          ),
          IconButton(
            onPressed: () {
              _showClearDataDialog(context, context.read<KontragentCubit>());
            },
            icon: const Icon(Icons.clear_all),
            tooltip: 'Очистити локальні дані',
          ),
          IconButton(
            onPressed: () {
              _showInfoDialog(context, context.read<KontragentCubit>());
            },
            icon: const Icon(Icons.info),
            tooltip: 'Інформація про дані',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<KontragentCubit>().loadRootFolders(),
        child: BlocConsumer<KontragentCubit, KontragentState>(
          listener: (context, state) {
            if (state is KontragentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is KontragentInitial || state is KontragentLoading) {
              if (state is KontragentInitial) {
                // Спочатку перевіряємо чи є локальні дані, якщо ні - синхронізуємо
                _checkAndSyncIfNeeded(context);
              }
              return const Center(child: CircularProgressIndicator());
            }

            if (state is KontragentTreeLoaded) {
              return _buildHierarchicalView(context, state.rootFolders);
            }

            if (state is KontragentLoaded) {
              return _buildListView(context, state.kontragenty);
            }

            return const Center(child: Text('Немає даних для відображення'));
          },
        ),
      ),
    );
  }

  Widget _buildHierarchicalView(
    BuildContext context,
    List<dynamic> rootFolders,
  ) {
    return Column(
      children: [
        const KontragentSearchWidget(),
        Expanded(
          child: ListView.builder(
            itemCount: rootFolders.length,
            itemBuilder: (context, index) {
              final folder = rootFolders[index];
              return _FolderNode(
                entity: folder,
                cubit: context.read<KontragentCubit>(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView(BuildContext context, List<dynamic> kontragenty) {
    return Column(
      children: [
        const KontragentSearchWidget(),
        Expanded(
          child: ListView.builder(
            itemCount: kontragenty.length,
            itemBuilder: (context, index) {
              final kontragent = kontragenty[index];
              return KontragentItemWidget(kontragent: kontragent);
            },
          ),
        ),
      ],
    );
  }

  void _checkAndSyncIfNeeded(BuildContext context) async {
    final cubit = context.read<KontragentCubit>();

    // Перевіряємо кількість локальних записів
    final countResult = await cubit.getKontragentyCountUseCase(NoParams());

    countResult.fold(
      (failure) {
        // Якщо не вдалося отримати кількість, спробуємо синхронізувати
        print('⚠️ Не вдалося отримати кількість записів, синхронізуємо...');
        cubit.syncKontragenty();
      },
      (count) {
        if (count == 0) {
          print('📊 Локальних записів немає ($count), синхронізуємо...');
          cubit.syncKontragenty();
        } else {
          print('📊 Знайдено $count локальних записів, завантажуємо...');
          cubit.loadRootFolders();
        }
      },
    );
  }

  void _showClearDataDialog(BuildContext context, KontragentCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Очистити локальні дані'),
        content: const Text(
          'Ви впевнені, що хочете видалити всі локальні дані контрагентів?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await cubit.clearLocalData();
              await cubit.loadRootFolders();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Локальні дані очищено')),
              );
            },
            child: const Text('Очистити'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, KontragentCubit cubit) async {
    // Показуємо діалог з індикатором завантаження
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Отримуємо інформацію...'),
          ],
        ),
      ),
    );

    try {
      // Отримуємо кількість записів
      final countResult = await cubit.getKontragentyCountUseCase(NoParams());

      // Закриваємо діалог завантаження
      Navigator.pop(context);

      countResult.fold(
        (failure) {
          // Показуємо помилку
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Помилка'),
              content: Text(
                'Не вдалося отримати інформацію: ${failure.message}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        (count) {
          // Показуємо інформацію
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Інформація про дані'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 Локальних записів: $count'),
                  const SizedBox(height: 8),
                  Text('🗄️ База даних: kontragenty.db'),
                  const SizedBox(height: 8),
                  Text('🏷️ Таблиця: ${SupabaseConfig.schema}_kontragenty'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      // Закриваємо діалог завантаження
      Navigator.pop(context);

      // Показуємо помилку
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Помилка'),
          content: Text('Неочікувана помилка: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class _FolderNode extends StatelessWidget {
  const _FolderNode({required this.entity, required this.cubit});
  final dynamic entity;
  final KontragentCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (entity.isFolder) {
      return _LazyExpansionTile(
        title: Text(entity.name),
        leading: const Icon(Icons.folder),
        loadChildren: () => cubit.loadChildren(entity.guid),
        itemBuilder: (context, child) {
          return child.isFolder
              ? _FolderNode(entity: child, cubit: cubit)
              : KontragentItemWidget(kontragent: child);
        },
      );
    }
    return KontragentItemWidget(kontragent: entity);
  }
}

class _LazyExpansionTile extends StatefulWidget {
  const _LazyExpansionTile({
    required this.title,
    required this.leading,
    required this.loadChildren,
    required this.itemBuilder,
  });
  final Widget title;
  final Widget leading;
  final Future<List<dynamic>> Function() loadChildren;
  final Widget Function(BuildContext, dynamic) itemBuilder;

  @override
  State<_LazyExpansionTile> createState() => _LazyExpansionTileState();
}

class _LazyExpansionTileState extends State<_LazyExpansionTile> {
  bool _expanded = false;
  Future<List<dynamic>>? _future;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: widget.leading,
      title: widget.title,
      onExpansionChanged: (v) {
        setState(() => _expanded = v);
        if (v && _future == null) {
          _future = widget.loadChildren();
        }
      },
      children: _expanded
          ? [
              FutureBuilder<List<dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    );
                  }
                  final list = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) =>
                        widget.itemBuilder(context, list[index]),
                  );
                },
              ),
            ]
          : const <Widget>[],
    );
  }
}
