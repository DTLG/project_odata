import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../../../../data/datasources/local/sqflite_nomenclature_datasource.dart';
import '../../../../core/injection/injection_container.dart';

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
  late final SqliteNomenclatureDatasource _local;

  List<dynamic> _all = const [];
  List<dynamic> _shown = const [];
  bool _loading = true;
  bool _isSearchMode = false;
  String? _selectedGuid;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _local = sl<SqliteNomenclatureDatasource>();
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
                  labelText: 'Пошук товару',
                  hintText: 'Введіть назву товару',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchByName('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: _searchByName,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Штрихкод',
                  hintText: 'Введіть або відскануйте штрихкод',
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _scanBarcode,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _searchByBarcode(value);
                    _barcodeController.clear();
                  }
                },
                onChanged: (value) {
                  if (value.trim().isEmpty && _searchController.text.isEmpty) {
                    _searchByName('');
                  }
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
