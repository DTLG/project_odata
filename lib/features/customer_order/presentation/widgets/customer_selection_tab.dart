import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/customer_order_cubit.dart';
import '../../../kontragenty/domain/entities/kontragent_entity.dart';

/// Tab for customer selection
class CustomerSelectionTab extends StatefulWidget {
  final Function(KontragentEntity) onCustomerSelected;

  const CustomerSelectionTab({super.key, required this.onCustomerSelected});

  @override
  State<CustomerSelectionTab> createState() => _CustomerSelectionTabState();
}

class _CustomerSelectionTabState extends State<CustomerSelectionTab> {
  final TextEditingController _searchController = TextEditingController();
  KontragentEntity? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    // Data will be loaded automatically by the main page initialization
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Пошук клієнта',
              hintText: 'Введіть назву клієнта',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<CustomerOrderCubit>()
                            .loadAvailableCustomers();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              context.read<CustomerOrderCubit>().searchCustomers(value);
            },
          ),
        ),

        // Selected customer info
        if (_selectedCustomer != null)
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Обраний клієнт:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedCustomer!.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_selectedCustomer!.edrpou.isNotEmpty)
                  Text('ЄДРПОУ: ${_selectedCustomer!.edrpou}'),
                if (_selectedCustomer!.description.isNotEmpty)
                  Text('Опис: ${_selectedCustomer!.description}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onCustomerSelected(_selectedCustomer!);
                  },
                  child: const Text('Обрати клієнта'),
                ),
              ],
            ),
          ),

        // Customers list
        Expanded(
          child: BlocBuilder<CustomerOrderCubit, CustomerOrderState>(
            builder: (context, state) {
              if (state is CustomerOrderLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CustomerOrderError) {
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
                        state.message,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<CustomerOrderCubit>().initialize();
                        },
                        child: const Text('Спробувати знову'),
                      ),
                    ],
                  ),
                );
              }

              List<KontragentEntity> customers = [];
              if (state is CustomersLoaded) {
                customers = state.customers;
              } else if (state is CustomerOrderInitialized) {
                customers = state.customers;
              } else if (state is CustomerOrderWithNomenclatureLoaded) {
                customers = state.customers;
              }

              if (customers.isNotEmpty) {
                final bool isSearchMode = _searchController.text
                    .trim()
                    .isNotEmpty;

                if (isSearchMode) {
                  // Flat list during search
                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final isSelected =
                          _selectedCustomer?.guid == customer.guid;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          leading: Icon(
                            customer.isFolder ? Icons.folder : Icons.person,
                            color: customer.isFolder
                                ? Colors.amber
                                : Theme.of(context).colorScheme.secondary,
                          ),
                          title: Text(customer.name),
                          subtitle:
                              (!customer.isFolder &&
                                  (customer.edrpou.isNotEmpty ||
                                      customer.description.isNotEmpty))
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (customer.edrpou.isNotEmpty)
                                      Text('ЄДРПОУ: ${customer.edrpou}'),
                                    if (customer.description.isNotEmpty)
                                      Text(
                                        customer.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                )
                              : null,
                          trailing: isSelected && !customer.isFolder
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            if (customer.isFolder)
                              return; // do nothing in search for folders
                            setState(() {
                              _selectedCustomer = customer;
                            });
                          },
                        ),
                      );
                    },
                  );
                }

                // Build hierarchy map for tree mode
                final Map<String, List<KontragentEntity>> childrenByParent = {};
                for (final c in customers) {
                  final parent = c.parentGuid;
                  childrenByParent.putIfAbsent(
                    parent,
                    () => <KontragentEntity>[],
                  );
                  childrenByParent[parent]!.add(c);
                }
                // Roots: parentGuid empty or all-zero GUID
                final roots = [
                  ...?childrenByParent['00000000-0000-0000-0000-000000000000'],
                  ...?childrenByParent[''],
                ];

                return ListView.builder(
                  itemCount: roots.length,
                  itemBuilder: (context, index) {
                    final node = roots[index];
                    if (node.isFolder) {
                      return _CustomerFolderNode(
                        node: node,
                        childrenByParent: childrenByParent,
                        onPick: (kontragent) {
                          setState(() {
                            _selectedCustomer = kontragent;
                          });
                        },
                      );
                    }
                    final isSelected = _selectedCustomer?.guid == node.guid;
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(node.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (node.edrpou.isNotEmpty)
                            Text('ЄДРПОУ: ${node.edrpou}'),
                          if (node.description.isNotEmpty)
                            Text(
                              node.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCustomer = node;
                        });
                      },
                    );
                  },
                );
              }

              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 64),
                    SizedBox(height: 16),
                    Text('Клієнти не знайдені'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomerFolderNode extends StatefulWidget {
  const _CustomerFolderNode({
    required this.node,
    required this.childrenByParent,
    required this.onPick,
  });
  final KontragentEntity node;
  final Map<String, List<KontragentEntity>> childrenByParent;
  final void Function(KontragentEntity) onPick;

  @override
  State<_CustomerFolderNode> createState() => _CustomerFolderNodeState();
}

class _CustomerFolderNodeState extends State<_CustomerFolderNode> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final children =
        widget.childrenByParent[widget.node.guid] ?? const <KontragentEntity>[];
    return ExpansionTile(
      leading: const Icon(Icons.folder),
      title: Text(widget.node.name),
      onExpansionChanged: (v) => setState(() => _expanded = v),
      children: _expanded
          ? children.map((child) {
              if (child.isFolder) {
                return _CustomerFolderNode(
                  node: child,
                  childrenByParent: widget.childrenByParent,
                  onPick: widget.onPick,
                );
              }
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(child.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (child.edrpou.isNotEmpty)
                      Text('ЄДРПОУ: ${child.edrpou}'),
                    if (child.description.isNotEmpty)
                      Text(
                        child.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                onTap: () => widget.onPick(child),
              );
            }).toList()
          : const <Widget>[],
    );
  }
}
