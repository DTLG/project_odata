import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/customer_order_cubit.dart';
import '../../domain/entities/customer_order_entity.dart';
import '../../../../core/entities/nomenclature_entity.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

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
              // Search field
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
                            setState(() {
                              _isSearchMode = false;
                            });
                            context
                                .read<CustomerOrderCubit>()
                                .loadAvailableNomenclature();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _isSearchMode = value.trim().isNotEmpty;
                  });
                  context.read<CustomerOrderCubit>().searchNomenclature(value);
                },
              ),
              const SizedBox(height: 8),
              // Barcode field
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
                onChanged: (value) {
                  if (value.trim().isEmpty && _searchController.text.isEmpty) {
                    setState(() {
                      _isSearchMode = false;
                    });
                    context
                        .read<CustomerOrderCubit>()
                        .loadAvailableNomenclature();
                  }
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _isSearchMode = true;
                    });
                    context
                        .read<CustomerOrderCubit>()
                        .searchNomenclatureByBarcode(value);
                    _barcodeController.clear();
                  }
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
