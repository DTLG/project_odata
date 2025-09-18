import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/kontragent_cubit.dart';
import '../widgets/kontragent_search_widget.dart';
import '../widgets/kontragent_item_widget.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/objectbox/objectbox_entities.dart';
import '../../domain/entities/kontragent_entity.dart';
import 'package:project_odata/objectbox.dart';

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

class _KontragentView extends StatefulWidget {
  const _KontragentView();

  @override
  State<_KontragentView> createState() => _KontragentViewState();
}

class _KontragentViewState extends State<_KontragentView> {
  ObjectBox? _obx;
  bool _loading = true;
  List<KontragentObx> _roots = const [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final obx = sl<ObjectBox>();
    final roots = obx.getRootKontragenty();
    setState(() {
      _obx = obx;
      _roots = roots;
      _loading = false;
    });
    if (roots.isEmpty) {
      // Якщо порожньо – ініціюємо синхронізацію через кубіт, після чого оновимо локальні дані
      // await context.read<KontragentCubit>().syncKontragenty();
      await _reloadFromLocal();
    }
  }

  Future<void> _reloadFromLocal() async {
    if (_obx == null) return;
    final roots = _obx!.getRootKontragenty();
    setState(() => _roots = roots);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контрагенти'),
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<KontragentCubit>().syncKontragenty();
              await _reloadFromLocal();
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reloadFromLocal,
              child: Column(
                children: [
                  const KontragentSearchWidget(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _roots.length,
                      itemBuilder: (context, index) {
                        final folder = _roots[index];
                        return _FolderNode(
                          entity: folder,
                          loadChildren: _loadChildren,
                          toEntity: _toEntity,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<List<KontragentObx>> _loadChildren(String parentGuid) async {
    if (_obx == null) return const [];
    return _obx!.getChildrenKontragenty(parentGuid);
  }

  KontragentEntity _toEntity(KontragentObx k) => KontragentEntity(
    guid: k.guid,
    name: k.name,
    edrpou: k.edrpou ?? '',
    isFolder: k.isFolder,
    parentGuid: k.parentGuid,
    description: '',
    createdAt: DateTime.now(),
  );

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
  const _FolderNode({
    required this.entity,
    required this.loadChildren,
    required this.toEntity,
  });
  final KontragentObx entity;
  final Future<List<KontragentObx>> Function(String parentGuid) loadChildren;
  final KontragentEntity Function(KontragentObx) toEntity;

  @override
  Widget build(BuildContext context) {
    if (entity.isFolder) {
      return _LazyExpansionTile(
        title: Text(entity.name),
        leading: const Icon(Icons.folder),
        loadChildren: () => loadChildren(entity.guid),
        itemBuilder: (context, child) {
          return child.isFolder
              ? _FolderNode(
                  entity: child,
                  loadChildren: loadChildren,
                  toEntity: toEntity,
                )
              : KontragentItemWidget(kontragent: toEntity(child));
        },
      );
    }
    return KontragentItemWidget(kontragent: toEntity(entity));
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
  final Future<List<KontragentObx>> Function() loadChildren;
  final Widget Function(BuildContext, KontragentObx) itemBuilder;

  @override
  State<_LazyExpansionTile> createState() => _LazyExpansionTileState();
}

class _LazyExpansionTileState extends State<_LazyExpansionTile> {
  bool _expanded = false;
  Future<List<KontragentObx>>? _future;

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
              FutureBuilder<List<KontragentObx>>(
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
