import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/customer_order_cubit.dart';
import '../../domain/entities/customer_order_entity.dart';
import '../../../../core/entities/nomenclature_entity.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:async';
import '../../../common/widgets/search_mode_switch.dart' as common;
import '../../../../core/injection/injection_container.dart';
import '../../../nomenclature/cubit/nomenclature_cubit.dart' as nomen;
import '../../../nomenclature/cubit/nomenclature_state.dart' as nstate;

/// Tab for selecting products and adding to cart
class ProductSelectionTab extends StatefulWidget {
  final Function(OrderItemEntity) onItemAdded;

  const ProductSelectionTab({super.key, required this.onItemAdded});

  @override
  State<ProductSelectionTab> createState() => _ProductSelectionTabState();
}

class _ProductSelectionTabState extends State<ProductSelectionTab> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  bool _isSearchMode = false;
  bool _byName = true;
  bool _byBarcode = false;
  bool _byArticle = false;
  Timer? _debounce;
  List<NomenclatureEntity> allItems = const [];

  @override
  void initState() {
    super.initState();
    // Ensure initial nomenclature list is loaded on first open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Ensure global NomenclatureCubit has data (initialized in Splash)
      try {
        final globalNom = sl<nomen.NomenclatureCubit>();
        if (globalNom.state is! nstate.NomenclatureLoaded &&
            globalNom.state is! nstate.NomenclatureTreeLoaded) {
          globalNom.loadRootTree();
        }
      } catch (_) {}
      final cubit = context.read<CustomerOrderCubit>();
      cubit.loadAvailableNomenclature();
    });
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
        // Search and barcode section
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
                            context
                                .read<CustomerOrderCubit>()
                                .loadAvailableNomenclature();
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
                        setState(() => _isSearchMode = false);
                        context
                            .read<CustomerOrderCubit>()
                            .loadAvailableNomenclature();
                        return;
                      }
                      if (_byBarcode) {
                        context
                            .read<CustomerOrderCubit>()
                            .searchNomenclatureByBarcode(q);
                      } else if (_byArticle) {
                        // Use existing name search for article as well
                        context.read<CustomerOrderCubit>().searchNomenclature(
                          q,
                        );
                      } else {
                        context.read<CustomerOrderCubit>().searchNomenclature(
                          q,
                        );
                      }
                    },
                  );
                },
                onSubmitted: (value) {
                  final q = value.trim();
                  if (q.isEmpty) return;
                  setState(() => _isSearchMode = true);
                  if (_byBarcode) {
                    context
                        .read<CustomerOrderCubit>()
                        .searchNomenclatureByBarcode(q);
                  } else if (_byArticle) {
                    context.read<CustomerOrderCubit>().searchNomenclature(q);
                  } else {
                    context.read<CustomerOrderCubit>().searchNomenclature(q);
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

        // Nomenclature list
        Expanded(
          child: BlocBuilder<CustomerOrderCubit, CustomerOrderState>(
            builder: (context, state) {
              if (state is CustomerOrderLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // If single item found by barcode – show it with a back-to-folders button
              if (state is NomenclatureFound) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          _buildNomenclatureTile(
                            context,
                            state,
                            state.nomenclature,
                          ),
                        ],
                      ),
                    ),
                    _backToFoldersButton(context),
                  ],
                );
              }

              List<NomenclatureEntity> nomenclatureList = [];

              if (state is NomenclatureLoaded) {
                allItems = state.nomenclature;
                nomenclatureList = state.nomenclature;
              } else if (state is CustomerOrderWithNomenclatureLoaded) {
                nomenclatureList = state.nomenclature;
              } else if (state is CustomerOrderInitialized) {
                nomenclatureList = state.nomenclature;
              } else if (state is NomenclatureFound) {
                nomenclatureList = [state.nomenclature];
              }

              if (nomenclatureList.isEmpty) {
                return const Center(child: Text('Товари не знайдені'));
              }

              if (_isSearchMode) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: nomenclatureList.length,
                        itemBuilder: (context, index) {
                          final nomenclature = nomenclatureList[index];
                          return _buildNomenclatureTile(
                            context,
                            state,
                            nomenclature,
                          );
                        },
                      ),
                    ),
                    _backToFoldersButton(context),
                  ],
                );
              }

              // Hierarchical tree view when not searching
              final tree = _buildTree(nomenclatureList);
              final roots = tree.rootFolders;
              return ListView.builder(
                itemCount: roots.length,
                itemBuilder: (context, index) {
                  final root = roots[index];
                  if (root.isFolder) {
                    return _FolderNode(
                      node: root,
                      childrenByParent: tree.childrenByParent,
                      tileBuilder: (item) =>
                          _buildNomenclatureTile(context, state, item),
                    );
                  }
                  return _buildNomenclatureTile(context, state, root);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNomenclatureTile(
    BuildContext context,
    CustomerOrderState state,
    NomenclatureEntity nomenclature,
  ) {
    // Determine current quantity of this item in the cart
    int currentQuantity = 0;
    String? existingItemId;
    if (state is CustomerOrderLoaded) {
      for (final it in state.orderItems) {
        if (it.nomenclature.guid == nomenclature.guid) {
          currentQuantity = it.quantity.toInt();
          existingItemId = it.id;
          break;
        }
      }
    } else if (state is CustomerOrderWithNomenclatureLoaded) {
      for (final it in state.orderItems) {
        if (it.nomenclature.guid == nomenclature.guid) {
          currentQuantity = it.quantity.toInt();
          existingItemId = it.id;
          break;
        }
      }
    }

    if (nomenclature.isFolder) {
      return const SizedBox.shrink();
    }

    return ListTile(
      title: Text(nomenclature.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nomenclature.article.isNotEmpty)
            Text('Артикул: ${nomenclature.article}'),
          Text('Ціна: ${nomenclature.price.toStringAsFixed(2)} грн'),
          if (currentQuantity > 0) const SizedBox(height: 4),
          if (currentQuantity > 0) Text('В кошику: $currentQuantity шт.'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: currentQuantity > 0
                ? () {
                    final cubit = context.read<CustomerOrderCubit>();
                    if (currentQuantity <= 1 && existingItemId != null) {
                      cubit.removeOrderItem(existingItemId);
                    } else if (existingItemId != null) {
                      cubit.updateItemQuantity(
                        existingItemId,
                        (currentQuantity - 1).toDouble(),
                      );
                    }
                  }
                : null,
          ),
          Text(
            currentQuantity.toString(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              final cubit = context.read<CustomerOrderCubit>();
              if (existingItemId == null) {
                final orderItem = OrderItemEntity(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nomenclature: nomenclature,
                  quantity: 1.0,
                  unitPrice: nomenclature.price,
                  totalPrice: nomenclature.price,
                );
                widget.onItemAdded(orderItem);
              } else {
                cubit.updateItemQuantity(
                  existingItemId,
                  (currentQuantity + 1).toDouble(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  _TreeData _buildTree(List<NomenclatureEntity> all) {
    const String rootGuid = '00000000-0000-0000-0000-000000000000';
    final Map<String, List<NomenclatureEntity>> childrenByParent = {};
    for (final e in all) {
      final String parent = (e.parentGuid.isEmpty) ? rootGuid : e.parentGuid;
      final list = childrenByParent[parent] ??= <NomenclatureEntity>[];
      list.add(e);
    }
    final List<NomenclatureEntity> roots =
        (childrenByParent[rootGuid] ?? <NomenclatureEntity>[])
          ..sort((a, b) => a.name.compareTo(b.name));
    return _TreeData(roots, childrenByParent);
  }

  Widget _backToFoldersButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _isSearchMode = false;
            });
            _searchController.clear();
            _barcodeController.clear();
            context.read<CustomerOrderCubit>().loadAvailableNomenclature();
          },
          child: const Text('Повернутись до папок'),
        ),
      ),
    );
  }
}

class _TreeData {
  final List<NomenclatureEntity> rootFolders;
  final Map<String, List<NomenclatureEntity>> childrenByParent;
  _TreeData(this.rootFolders, this.childrenByParent);
}

class _FolderNode extends StatelessWidget {
  const _FolderNode({
    required this.node,
    required this.childrenByParent,
    required this.tileBuilder,
  });
  final NomenclatureEntity node;
  final Map<String, List<NomenclatureEntity>> childrenByParent;
  final Widget Function(NomenclatureEntity) tileBuilder;

  @override
  Widget build(BuildContext context) {
    final children =
        childrenByParent[node.guid] ?? const <NomenclatureEntity>[];
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

extension on _ProductSelectionTabState {
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
        // Trigger search by scanned barcode
        if (!mounted) return;
        setState(() {
          _isSearchMode = true;
        });
        context.read<CustomerOrderCubit>().searchNomenclatureByBarcode(
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
