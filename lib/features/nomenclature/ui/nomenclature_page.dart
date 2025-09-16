import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/injection/injection_container.dart';
import '../cubit/nomenclature_cubit.dart';
import '../cubit/nomenclature_state.dart';
import '../../../core/entities/nomenclature_entity.dart';
import 'widgets/nomenclature_search_widget.dart';
import 'widgets/nomenclature_item_widget.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:async';

/// Сторінка номенклатури
class NomenclaturePage extends StatelessWidget {
  const NomenclaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NomenclatureCubit>(
      create: (context) => sl<NomenclatureCubit>()..loadRootTree(),
      child: const NomenclatureView(),
    );
  }
}

/// View для номенклатури
class NomenclatureView extends StatelessWidget {
  const NomenclatureView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NomenclatureCubit, NomenclatureState>(
      listener: (context, state) {
        if (state is NomenclatureLoadingWithProgress) {
          _showProgressDialog(context, state);
        } else if (state is NomenclatureSyncSuccess) {
          if (_progressDialogShown) {
            _progressDialogShown = false;
            Navigator.of(context, rootNavigator: true).pop();
          }
          context.read<NomenclatureCubit>().loadRootTree();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Синхронізовано ${state.syncedCount} записів'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is NomenclatureError) {
          if (_progressDialogShown) {
            _progressDialogShown = false;
            Navigator.of(context, rootNavigator: true).pop();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Номенклатура'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'recreate') {
                  _recreateDatabase(context);
                } else if (value == 'sync') {
                  _showSyncDialog(context);
                } else if (value == 'clear_local') {
                  _confirmClearLocal(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'recreate',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Перестворити базу'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sync',
                  child: Row(
                    children: [
                      Icon(Icons.sync, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Синхронізувати'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_local',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Очистити локальні дані'),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: const NomenclatureSelectionTab(),

        // Column(
        //   children: [
        //     const NomenclatureSearchWidget(),
        //     Expanded(
        //       child: BlocBuilder<NomenclatureCubit, NomenclatureState>(
        //         builder: (context, state) {
        //           if (state is NomenclatureLoading) {
        //             return const Center(child: CircularProgressIndicator());
        //           }

        //           // Show flat list with back-to-folders button for search results
        //           if (state is NomenclatureLoaded) {
        //             return _NomenclatureListWithBack(
        //               items: state.nomenclatures,
        //             );
        //           }
        //           if (state is NomenclatureSearchResult) {
        //             return _NomenclatureListWithBack(
        //               items: state.searchResults,
        //             );
        //           }
        //           if (state is NomenclatureFoundByArticle) {
        //             return _NomenclatureListWithBack(
        //               items: [state.nomenclature],
        //             );
        //           }
        //           if (state is NomenclatureNotFoundByArticle) {
        //             return Column(
        //               mainAxisAlignment: MainAxisAlignment.center,
        //               children: [
        //                 const Icon(Icons.search_off, size: 64),
        //                 const SizedBox(height: 12),
        //                 Text(
        //                   'Номенклатуру з артикулом ${state.article} не знайдено',
        //                 ),
        //                 const SizedBox(height: 24),
        //                 _BackToFoldersButton(),
        //               ],
        //             );
        //           }

        //           // Default: hierarchical tree
        //           if (state is NomenclatureTreeLoaded) {
        //             return _NomenclatureTree(rootState: state);
        //           }
        //           return const Center(child: Text('Немає даних'));
        //         },
        //       ),
        //     ),
        //   ],
        // ),
      ),
    );
  }

  void _confirmClearLocal(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистити локальні дані?'),
        content: const Text(
          'Це видалить усі локально збережені записи номенклатури. Продовжити?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Очистити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await context.read<NomenclatureCubit>().clearLocalData();
      await context.read<NomenclatureCubit>().loadRootTree();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Локальні дані очищено')));
    }
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Синхронізація'),
        content: const Text(
          'Синхронізувати номенклатуру з сервером? Це може зайняти деякий час.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<NomenclatureCubit>().syncNomenclature();
            },
            child: const Text('Синхронізувати'),
          ),
        ],
      ),
    );
  }

  void _recreateDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Перестворити базу?'),
          ],
        ),
        content: const Text(
          'Це видалить всі локальні дані і створить нову базу.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Перестворити',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Перестворюємо базу...'),
            ],
          ),
        ),
      );
      context.read<NomenclatureCubit>().recreateLocalDatabase();
    }
  }

  static bool _progressDialogShown = false;
  void _showProgressDialog(
    BuildContext context,
    NomenclatureLoadingWithProgress state,
  ) {
    if (!_progressDialogShown) {
      _progressDialogShown = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.download, color: Colors.blue),
              SizedBox(width: 8),
              Text('Синхронізація'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: state.total != null && state.total! > 0
                    ? (state.current ?? 0) / state.total!
                    : null,
              ),
              const SizedBox(height: 16),
              Text(state.message, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ).then((_) {
        _progressDialogShown = false;
      });
    }
  }
}

class NomenclatureSelectionTab extends StatefulWidget {
  const NomenclatureSelectionTab({super.key});

  @override
  State<NomenclatureSelectionTab> createState() =>
      _NomenclatureSelectionTabState();
}

class _NomenclatureSelectionTabState extends State<NomenclatureSelectionTab> {
  final TextEditingController _searchController = TextEditingController();
  // Single input used for all search modes
  bool _isSearchMode = false;
  // search mode flags
  bool _searchByName = true;
  bool _searchByBarcode = false;
  bool _searchByArticle = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Пошук',
                  hintText: _searchByName
                      ? 'Введіть назву'
                      : _searchByBarcode
                      ? 'Введіть/скануйте штрихкод'
                      : 'Введіть артикул',
                  prefixIcon: _searchByBarcode
                      ? const Icon(Icons.qr_code_scanner)
                      : const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchByBarcode)
                        IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: _scanBarcode,
                        ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _isSearchMode = false);
                            context.read<NomenclatureCubit>().loadRootTree();
                          },
                        ),
                    ],
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _isSearchMode = value.trim().isNotEmpty);
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 250), () {
                    if (!mounted) return;
                    final q = value.trim();
                    if (q.isEmpty) {
                      context.read<NomenclatureCubit>().loadRootTree();
                      return;
                    }
                    if (_searchByBarcode) {
                      context
                          .read<NomenclatureCubit>()
                          .searchNomenclatureByBarcode(q);
                    } else if (_searchByArticle) {
                      context
                          .read<NomenclatureCubit>()
                          .searchNomenclatureByArticle(q);
                    } else {
                      context
                          .read<NomenclatureCubit>()
                          .searchNomenclatureByName(q);
                    }
                  });
                },
                onSubmitted: (value) {
                  final q = value.trim();
                  if (q.isEmpty) return;
                  setState(() => _isSearchMode = true);
                  if (_searchByBarcode) {
                    context
                        .read<NomenclatureCubit>()
                        .searchNomenclatureByBarcode(q);
                  } else if (_searchByArticle) {
                    context
                        .read<NomenclatureCubit>()
                        .searchNomenclatureByArticle(q);
                  } else {
                    context.read<NomenclatureCubit>().searchNomenclatureByName(
                      q,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Назва'),

                      value: _searchByName,
                      onChanged: (v) {
                        if (v == true) {
                          setState(() {
                            _searchByName = true;
                            _searchByBarcode = false;
                            _searchByArticle = false;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Штрихкод'),
                      value: _searchByBarcode,
                      onChanged: (v) {
                        if (v == true) {
                          setState(() {
                            _searchByName = false;
                            _searchByBarcode = true;
                            _searchByArticle = false;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Артикул'),
                      value: _searchByArticle,
                      onChanged: (v) {
                        if (v == true) {
                          setState(() {
                            _searchByName = false;
                            _searchByBarcode = false;
                            _searchByArticle = true;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<NomenclatureCubit, NomenclatureState>(
            builder: (context, state) {
              if (state is NomenclatureLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is NomenclatureLoaded) {
                return _NomenclatureListWithBack(items: state.nomenclatures);
              }
              if (state is NomenclatureSearchResult) {
                return _NomenclatureListWithBack(items: state.searchResults);
              }
              if (state is NomenclatureFoundByArticle) {
                return _NomenclatureListWithBack(items: [state.nomenclature]);
              }
              if (state is NomenclatureNotFoundByArticle) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      'Номенклатуру з артикулом ${state.article} не знайдено',
                    ),
                    const SizedBox(height: 24),
                    const _BackToFoldersButton(),
                  ],
                );
              }

              if (!_isSearchMode && state is NomenclatureTreeLoaded) {
                return _NomenclatureTree(rootState: state);
              }

              return const Center(child: Text('Немає даних'));
            },
          ),
        ),
      ],
    );
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan(
        options: const ScanOptions(
          strings: {
            'cancel': 'Скасувати',
            'flash_on': 'Увімкнути спалах',
            'flash_off': 'Вимкнути спалах',
          },
          restrictFormat: [],
          useCamera: -1,
          autoEnableFlash: false,
          android: AndroidOptions(useAutoFocus: true),
        ),
      );

      if (!mounted) return;

      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        setState(() => _isSearchMode = true);
        context.read<NomenclatureCubit>().searchNomenclatureByBarcode(
          result.rawContent,
        );
        // _barcodeController.clear();
        _searchController.clear();
      } else if (result.type == ResultType.Error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка сканування: ${result.rawContent}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не вдалося запустити сканер: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _NomenclatureListWithBack extends StatelessWidget {
  const _NomenclatureListWithBack({required this.items});
  final List<NomenclatureEntity> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return NomenclatureItemWidget(nomenclature: item);
            },
          ),
        ),
        const _BackToFoldersButton(),
      ],
    );
  }
}

class _BackToFoldersButton extends StatelessWidget {
  const _BackToFoldersButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            context.read<NomenclatureCubit>().loadRootTree();
          },
          child: const Text('Повернутись до папок'),
        ),
      ),
    );
  }
}

class _NomenclatureTree extends StatelessWidget {
  const _NomenclatureTree({required this.rootState});
  final NomenclatureTreeLoaded rootState;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NomenclatureCubit>();
    final roots = rootState.rootFolders;
    return ListView.builder(
      itemCount: roots.length,
      itemBuilder: (context, index) {
        return _FolderNode(entity: roots[index], cubit: cubit);
      },
    );
  }
}

class _FolderNode extends StatelessWidget {
  const _FolderNode({required this.entity, required this.cubit});
  final NomenclatureEntity entity;
  final NomenclatureCubit cubit;

  @override
  Widget build(BuildContext context) {
    final children = cubit.getChildren(entity.guid);
    if (entity.isFolder) {
      return _LazyExpansionTile(
        title: Text(entity.name),
        leading: const Icon(Icons.folder),
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];
          if (child.isFolder) {
            return _FolderNode(entity: child, cubit: cubit);
          }
          return NomenclatureItemWidget(nomenclature: child);
        },
      );
    }
    return NomenclatureItemWidget(nomenclature: entity);
  }
}

class _LazyExpansionTile extends StatefulWidget {
  const _LazyExpansionTile({
    required this.title,
    required this.leading,
    required this.itemCount,
    required this.itemBuilder,
  });
  final Widget title;
  final Widget leading;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  State<_LazyExpansionTile> createState() => _LazyExpansionTileState();
}

class _LazyExpansionTileState extends State<_LazyExpansionTile> {
  bool _expanded = false;
  final ScrollController _innerController = ScrollController();

  @override
  void dispose() {
    _innerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: widget.leading,
      title: widget.title,
      onExpansionChanged: (v) => setState(() => _expanded = v),
      children: _expanded
          ? <Widget>[
              Builder(
                builder: (context) {
                  final double screenHeight = MediaQuery.of(
                    context,
                  ).size.height;
                  const double perItemHeight = 56.0; // approx tile height
                  const double minHeight =
                      perItemHeight * 3; // show at least ~3
                  final double estimated = widget.itemCount * perItemHeight;
                  final double maxHeight =
                      screenHeight * 0.6; // cap at 60% screen
                  final double height = estimated.clamp(minHeight, maxHeight);

                  return ListView.builder(
                    controller: _innerController,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: widget.itemCount,
                    itemBuilder: widget.itemBuilder,
                  );
                },
              ),
            ]
          : const <Widget>[],
    );
  }
}
