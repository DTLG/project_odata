import 'package:flutter/material.dart';
import 'dart:async';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../common/widgets/search_mode_switch.dart' as common;
import '../../../../data/datasources/local/nomenclature_local_datasource.dart';

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
  late final NomenclatureLocalDatasource _local;

  List<dynamic> _all = const [];
  List<dynamic> _shown = const [];
  bool _loading = true;
  bool _isSearchMode = false;
  String? _selectedGuid;
  bool _loadedOnce = false;
  // search mode flags
  bool _byName = true;
  bool _byBarcode = false;
  bool _byArticle = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _local = sl<NomenclatureLocalDatasource>();
    _selectedGuid = widget.initialGuid;
    if (widget.prefetched != null && widget.prefetched!.isNotEmpty) {
      _all = widget.prefetched!;
      _shown = widget.prefetched!;
      _isSearchMode = false;
      _loading = false;
      _loadedOnce = true;
    } else {
      _loadOnce();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _local.getAllNomenclature();
    setState(() {
      _all = all;
      _shown = all;
      _isSearchMode = false;
      _loading = false;
    });
  }

  Future<void> _loadOnce() async {
    if (_loadedOnce) return;
    await _load();
    _loadedOnce = true;
  }

  Future<void> _searchByName(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearchMode = false;
        _shown = _all;
      });
      return;
    }
    final results = await _local.searchNomenclatureByName(query);
    setState(() {
      _isSearchMode = true;
      _shown = results;
    });
  }

  Future<void> _searchByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) {
      setState(() {
        _isSearchMode = false;
        _shown = _all;
      });
      return;
    }
    final one = await _local.getNomenclatureByBarcode(barcode);
    setState(() {
      _isSearchMode = true;
      _shown = one != null ? [one] : const [];
    });
  }

  Future<void> _searchByArticle(String article) async {
    final q = article.trim();
    if (q.isEmpty) {
      setState(() {
        _isSearchMode = false;
        _shown = _all;
      });
      return;
    }
    final String qLower = q.toLowerCase();
    // Filter locally to return multiple matches (up to 100)
    final List<dynamic> filtered = _all
        .where(
          (e) =>
              e.article != null &&
              e.article.toString().toLowerCase().contains(qLower),
        )
        .take(100)
        .toList();
    setState(() {
      _isSearchMode = true;
      _shown = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
                            setState(() => _isSearchMode = false);
                            _shown = _all;
                          },
                        ),
                    ],
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _isSearchMode = value.trim().isNotEmpty);
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 250),
                    () async {
                      if (!mounted) return;
                      final q = value.trim();
                      if (q.isEmpty) {
                        setState(() {
                          _isSearchMode = false;
                          _shown = _all;
                        });
                        return;
                      }
                      if (_byBarcode) {
                        await _searchByBarcode(q);
                      } else if (_byArticle) {
                        await _searchByArticle(q);
                      } else {
                        await _searchByName(q);
                      }
                    },
                  );
                },
                onSubmitted: (value) {
                  final q = value.trim();
                  if (q.isEmpty) return;
                  setState(() => _isSearchMode = true);
                  if (_byBarcode) {
                    _searchByBarcode(q);
                  } else if (_byArticle) {
                    _searchByArticle(q);
                  } else {
                    _searchByName(q);
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

        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_shown.isEmpty) {
      return const Center(child: Text('Товари не знайдені'));
    }
    if (_isSearchMode) {
      return ListView.builder(
        itemCount: _shown.length,
        itemBuilder: (_, i) => _buildNomenclatureTile(_shown[i]),
      );
    }
    final tree = _buildTree(_shown);
    final roots = tree.rootFolders;
    return ListView.builder(
      itemCount: roots.length,
      itemBuilder: (_, i) {
        final root = roots[i];
        if (root.isFolder) {
          return _FolderNode(
            node: root,
            childrenByParent: tree.childrenByParent,
            tileBuilder: _buildNomenclatureTile,
          );
        }
        return _buildNomenclatureTile(root);
      },
    );
  }

  Widget _buildNomenclatureTile(dynamic n) {
    if (n.isFolder) return const SizedBox.shrink();
    final isSelected = _selectedGuid == n.guid;
    return ListTile(
      title: Text(n.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (n.article.toString().isNotEmpty) Text('Артикул: ${n.article}'),
          // Text('Ціна: ${n.price.toStringAsFixed(2)} грн'),
        ],
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.radio_button_unchecked),
      onTap: () {
        setState(() => _selectedGuid = n.guid);
        widget.onSelected(n.guid);
      },
    );
  }

  _TreeData _buildTree(List<dynamic> all) {
    const String rootGuid = '00000000-0000-0000-0000-000000000000';
    final Map<String, List<dynamic>> childrenByParent = {};
    for (final e in all) {
      final String parent = (e.parentGuid.toString().isEmpty)
          ? rootGuid
          : e.parentGuid;
      final list = childrenByParent[parent] ??= <dynamic>[];
      list.add(e);
    }
    final List<dynamic> roots = (childrenByParent[rootGuid] ?? <dynamic>[])
      ..sort((a, b) => a.name.compareTo(b.name));
    return _TreeData(roots, childrenByParent);
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

      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        if (!mounted) return;
        await _searchByBarcode(result.rawContent);
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
}

class _TreeData {
  final List<dynamic> rootFolders;
  final Map<String, List<dynamic>> childrenByParent;
  _TreeData(this.rootFolders, this.childrenByParent);
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
