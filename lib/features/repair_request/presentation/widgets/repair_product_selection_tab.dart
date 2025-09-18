import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../../../common/widgets/search_mode_switch.dart' as common;
import '../../../nomenclature/cubit/nomenclature_cubit.dart';
import '../../../nomenclature/cubit/nomenclature_state.dart';
import '../cubit/repair_request_cubit.dart';

class RepairProductSelectionTab extends StatefulWidget {
  final String? initialGuid;
  final void Function(String guid) onSelected;
  final List<dynamic>? prefetched;
  const RepairProductSelectionTab({
    super.key,
    this.initialGuid,
    required this.onSelected,
    this.prefetched,
  });

  @override
  State<RepairProductSelectionTab> createState() =>
      _RepairProductSelectionTabState();
}

class _RepairProductSelectionTabState extends State<RepairProductSelectionTab> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  String? _selectedGuid; // deprecated local selection; kept for backward-compat
  // search mode flags
  bool _byName = true;
  bool _byBarcode = false;
  bool _byArticle = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedGuid = widget.initialGuid;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
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
                  hintText: _byName
                      ? 'Введіть назву'
                      : _byBarcode
                      ? 'Введіть/скануйте штрихкод'
                      : 'Введіть артикул',
                  prefixIcon: _byBarcode
                      ? const Icon(Icons.qr_code_scanner)
                      : const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_byBarcode)
                        IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: _scanBarcode,
                        ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<NomenclatureCubit>().loadRootTree();
                          },
                        ),
                    ],
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 250),
                    () async {
                      if (!mounted) return;
                      final q = value.trim();
                      if (q.isEmpty) {
                        context.read<NomenclatureCubit>().loadRootTree();
                        return;
                      }
                      final cubit = context.read<NomenclatureCubit>();
                      if (_byBarcode) {
                        await cubit.searchNomenclatureByBarcode(q);
                      } else if (_byArticle) {
                        await cubit.searchNomenclatureByArticle(q);
                      } else {
                        await cubit.searchNomenclatureByName(q);
                      }
                    },
                  );
                },
                onSubmitted: (value) {
                  final q = value.trim();
                  if (q.isEmpty) return;
                  final cubit = context.read<NomenclatureCubit>();
                  if (_byBarcode) {
                    cubit.searchNomenclatureByBarcode(q);
                  } else if (_byArticle) {
                    cubit.searchNomenclatureByArticle(q);
                  } else {
                    cubit.searchNomenclatureByName(q);
                  }
                },
              ),
              const SizedBox(height: 8),
              _SearchSwitch(
                byName: _byName,
                byBarcode: _byBarcode,
                byArticle: _byArticle,
                onChanged: (mode) {
                  setState(() {
                    _byName = mode == _SearchMode.name;
                    _byBarcode = mode == _SearchMode.barcode;
                    _byArticle = mode == _SearchMode.article;
                  });
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: BlocBuilder<NomenclatureCubit, NomenclatureState>(
            builder: (context, state) {
              if (state is NomenclatureLoading ||
                  state is NomenclatureLoadingWithProgress) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is NomenclatureFoundByArticle) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [_buildNomenclatureTile(state.nomenclature)],
                      ),
                    ),
                    _buildBackToFoldersButton(context),
                  ],
                );
              }

              if (state is NomenclatureSearchResult) {
                final list = state.searchResults;
                if (list.isEmpty) {
                  return const Center(child: Text('Товари не знайдені'));
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) => _buildNomenclatureTile(list[i]),
                      ),
                    ),
                    _buildBackToFoldersButton(context),
                  ],
                );
              }

              if (state is NomenclatureTreeLoaded) {
                final roots = state.rootFolders;
                if (roots.isEmpty) {
                  return const Center(child: Text('Товари не знайдені'));
                }
                return ListView.builder(
                  itemCount: roots.length,
                  itemBuilder: (_, i) {
                    final root = roots[i];
                    if (root.isFolder) {
                      return _ObxFolderNode(
                        node: root,
                        tileBuilder: _buildNomenclatureTile,
                      );
                    }
                    return _buildNomenclatureTile(root);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNomenclatureTile(dynamic n) {
    if (n.isFolder) return const SizedBox.shrink();
    return BlocBuilder<RepairRequestCubit, RepairRequestState>(
      buildWhen: (p, s) => p.nomenclatureGuid != s.nomenclatureGuid,
      builder: (context, s) {
        final selectedGuid = s.nomenclatureGuid.isNotEmpty
            ? s.nomenclatureGuid
            : null;
        final isSelected = selectedGuid == n.guid;
        return ListTile(
          title: Text(n.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (n.article.toString().isNotEmpty)
                Text('Артикул: ${n.article}'),
            ],
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.radio_button_unchecked),
          onTap: () {
            try {
              context.read<RepairRequestCubit>().setNomenclatureGuid(n.guid);
            } catch (_) {}
            // widget.onSelected(n.guid);
          },
        );
      },
    );
  }

  // No internal tree building; rely on cubit's tree state

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

      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        if (!mounted) return;
        context.read<NomenclatureCubit>().searchNomenclatureByBarcode(
          result.rawContent,
        );
        _barcodeController.clear();
      } else if (result.type == ResultType.Error) {
        if (!mounted) return;
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

  Widget _buildBackToFoldersButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            _searchController.clear();
            _barcodeController.clear();
            context.read<NomenclatureCubit>().loadRootTree();
          },
          child: const Text('Повернутись до папок'),
        ),
      ),
    );
  }
}

class _FolderNode extends StatelessWidget {
  const _FolderNode({
    required this.node,
    required this.childrenByParent,
    required this.tileBuilder,
  });
  final dynamic node;
  final Map<String, List<dynamic>> childrenByParent;
  final Widget Function(dynamic) tileBuilder;

  @override
  Widget build(BuildContext context) {
    final children = childrenByParent[node.guid] ?? const <dynamic>[];
    return ExpansionTile(
      leading: const Icon(Icons.folder),
      title: Text(node.name),
      children: children.map((child) {
        if (child.isFolder) {
          return _FolderNode(
            node: child,
            childrenByParent: childrenByParent,
            tileBuilder: tileBuilder,
          );
        }
        return tileBuilder(child);
      }).toList(),
    );
  }
}

class _ObxFolderNode extends StatefulWidget {
  const _ObxFolderNode({required this.node, required this.tileBuilder});
  final dynamic node;
  final Widget Function(dynamic) tileBuilder;

  @override
  State<_ObxFolderNode> createState() => _ObxFolderNodeState();
}

class _ObxFolderNodeState extends State<_ObxFolderNode> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.folder),
      title: Text(widget.node.name),
      onExpansionChanged: (v) => setState(() => _expanded = v),
      children: _expanded
          ? [
              FutureBuilder<List<dynamic>>(
                future: context.read<NomenclatureCubit>().loadChildren(
                  widget.node.guid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final children = snapshot.data ?? const <dynamic>[];
                  if (children.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: children.map((child) {
                      if (child.isFolder) {
                        return _ObxFolderNode(
                          node: child,
                          tileBuilder: widget.tileBuilder,
                        );
                      }
                      return widget.tileBuilder(child);
                    }).toList(),
                  );
                },
              ),
            ]
          : const <Widget>[],
    );
  }
}

class _SearchSwitch extends StatelessWidget {
  const _SearchSwitch({
    required this.byName,
    required this.byBarcode,
    required this.byArticle,
    required this.onChanged,
  });
  final bool byName;
  final bool byBarcode;
  final bool byArticle;
  final ValueChanged<_SearchMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final common.SearchParam current = byBarcode
        ? common.SearchParam.barcode
        : byArticle
        ? common.SearchParam.article
        : common.SearchParam.name;
    return common.SearchModeSwitch(
      value: current,
      onChanged: (p) {
        switch (p) {
          case common.SearchParam.name:
            onChanged(_SearchMode.name);
            break;
          case common.SearchParam.barcode:
            onChanged(_SearchMode.barcode);
            break;
          case common.SearchParam.article:
            onChanged(_SearchMode.article);
            break;
        }
      },
    );
  }
}

enum _SearchMode { name, barcode, article }
