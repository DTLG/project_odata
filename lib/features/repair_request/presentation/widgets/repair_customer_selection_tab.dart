import 'package:flutter/material.dart';
import '../../../kontragenty/data/datasources/kontragent_local_data_source.dart';
import '../../../kontragenty/data/models/kontragent_model.dart';
import '../../../../core/injection/injection_container.dart';

class RepairCustomerSelectionTab extends StatefulWidget {
  final void Function(KontragentModel) onSelected;
  final List<KontragentModel>? prefetched;
  const RepairCustomerSelectionTab({
    super.key,
    required this.onSelected,
    this.prefetched,
  });

  @override
  State<RepairCustomerSelectionTab> createState() =>
      _RepairCustomerSelectionTabState();
}

class _RepairCustomerSelectionTabState
    extends State<RepairCustomerSelectionTab> {
  final TextEditingController _search = TextEditingController();
  late final KontragentLocalDataSource _kontrLocal;
  List<KontragentModel> _items = const [];
  bool _loading = true;
  KontragentModel? _selected;
  bool _isSearch = false;

  @override
  void initState() {
    super.initState();
    _kontrLocal = sl<KontragentLocalDataSource>();
    if (widget.prefetched != null && widget.prefetched!.isNotEmpty) {
      _items = widget.prefetched!;
      _loading = false;
      _isSearch = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _kontrLocal.getAllKontragenty();
    setState(() {
      _items = all;
      _loading = false;
      _isSearch = false;
    });
  }

  Future<void> _searchBy(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (widget.prefetched != null && widget.prefetched!.isNotEmpty) {
        setState(() {
          _items = widget.prefetched!;
          _loading = false;
          _isSearch = false;
        });
        return;
      }
      await _load();
      return;
    }
    setState(() => _loading = true);
    final byName = await _kontrLocal.searchByName(q);
    setState(() {
      _items = byName;
      _loading = false;
      _isSearch = true;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Пошук клієнта',
              hintText: 'Введіть назву клієнта',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        _load();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _searchBy,
          ),
        ),

        if (_selected != null)
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
                  _selected!.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_selected!.edrpou.isNotEmpty)
                  Text('ЄДРПОУ: ${_selected!.edrpou}'),
                if (_selected!.description.isNotEmpty)
                  Text('Опис: ${_selected!.description}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => widget.onSelected(_selected!),
                  child: const Text('Обрати клієнта'),
                ),
              ],
            ),
          ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(child: Text('Клієнти не знайдені'))
              : _isSearch
              ? _FlatSearchCustomersList(
                  items: _items,
                  selected: _selected,
                  onPick: (c) => setState(() => _selected = c),
                )
              : _TreeCustomersList(
                  items: _items,
                  selected: _selected,
                  onPick: (c) => setState(() => _selected = c),
                ),
        ),
      ],
    );
  }
}

class _FlatSearchCustomersList extends StatelessWidget {
  const _FlatSearchCustomersList({
    required this.items,
    required this.selected,
    required this.onPick,
  });
  final List<KontragentModel> items;
  final KontragentModel? selected;
  final void Function(KontragentModel) onPick;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final c = items[i];
        final isSel = selected?.guid == c.guid;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isSel ? Theme.of(context).colorScheme.primaryContainer : null,
          child: ListTile(
            leading: Icon(
              c.isFolder ? Icons.folder : Icons.person,
              color: c.isFolder
                  ? Colors.amber
                  : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(c.name),
            subtitle:
                (!c.isFolder &&
                    (c.edrpou.isNotEmpty || c.description.isNotEmpty))
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c.edrpou.isNotEmpty) Text('ЄДРПОУ: ${c.edrpou}'),
                      if (c.description.isNotEmpty)
                        Text(
                          c.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  )
                : null,
            trailing: isSel && !c.isFolder
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              if (c.isFolder) return; // no selection on folder in search
              onPick(c);
            },
          ),
        );
      },
    );
  }
}

class _TreeCustomersList extends StatelessWidget {
  const _TreeCustomersList({
    required this.items,
    required this.selected,
    required this.onPick,
  });
  final List<KontragentModel> items;
  final KontragentModel? selected;
  final void Function(KontragentModel) onPick;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<KontragentModel>> childrenByParent = {};
    for (final c in items) {
      final parent = c.parentGuid;
      childrenByParent.putIfAbsent(parent, () => <KontragentModel>[]);
      childrenByParent[parent]!.add(c);
    }
    final roots = [
      ...?childrenByParent['00000000-0000-0000-0000-000000000000'],
      ...?childrenByParent[''],
    ];

    return ListView.builder(
      itemCount: roots.length,
      itemBuilder: (_, i) {
        final node = roots[i];
        if (node.isFolder) {
          return _RepairCustomerFolderNode(
            node: node,
            childrenByParent: childrenByParent,
            onPick: onPick,
          );
        }
        final isSel = selected?.guid == node.guid;
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(node.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (node.edrpou.isNotEmpty) Text('ЄДРПОУ: ${node.edrpou}'),
              if (node.description.isNotEmpty)
                Text(
                  node.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: isSel
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () => onPick(node),
        );
      },
    );
  }
}

class _RepairCustomerFolderNode extends StatefulWidget {
  const _RepairCustomerFolderNode({
    required this.node,
    required this.childrenByParent,
    required this.onPick,
  });
  final KontragentModel node;
  final Map<String, List<KontragentModel>> childrenByParent;
  final void Function(KontragentModel) onPick;

  @override
  State<_RepairCustomerFolderNode> createState() =>
      _RepairCustomerFolderNodeState();
}

class _RepairCustomerFolderNodeState extends State<_RepairCustomerFolderNode> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final children =
        widget.childrenByParent[widget.node.guid] ?? const <KontragentModel>[];
    return ExpansionTile(
      leading: const Icon(Icons.folder),
      title: Text(widget.node.name),
      onExpansionChanged: (v) => setState(() => _expanded = v),
      children: _expanded
          ? children.map((child) {
              if (child.isFolder) {
                return _RepairCustomerFolderNode(
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
