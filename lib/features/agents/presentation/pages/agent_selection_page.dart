import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/agents_repository_impl.dart';
import '../../../../core/injection/injection_container.dart';
import '../cubit/agents_cubit.dart';
import '../../data/models/agent_model.dart';

class AgentSelectionPage extends StatefulWidget {
  const AgentSelectionPage({super.key});

  @override
  State<AgentSelectionPage> createState() => _AgentSelectionPageState();
}

class _AgentSelectionPageState extends State<AgentSelectionPage> {
  Future<void> _saveAgent(String guid, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('agent_guid', guid);
    await prefs.setString('agent_name', name);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repo = sl<AgentsRepository>();
    return BlocProvider(
      create: (_) => AgentsCubit(repo)..loadRoot(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Вибір агента')),
        body: _AgentSelectionBody(onPick: _saveAgent),
      ),
    );
  }
}

class _AgentSelectionBody extends StatefulWidget {
  const _AgentSelectionBody({required this.onPick});
  final Future<void> Function(String guid, String name) onPick;

  @override
  State<_AgentSelectionBody> createState() => _AgentSelectionBodyState();
}

class _AgentSelectionBodyState extends State<_AgentSelectionBody> {
  final TextEditingController _search = TextEditingController();
  bool _isSearch = false;

  Future<void> _attemptPick(AgentModel agent) async {
    final requiredPassword = (agent.password ?? '').trim();
    if (requiredPassword.isNotEmpty) {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Введіть пароль агента'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Пароль'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  ctx,
                ).pop(controller.text.trim() == requiredPassword);
              },
              child: const Text('Підтвердити'),
            ),
          ],
        ),
      );
      if (ok != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Невірний пароль агента')));
        return;
      }
    }
    await widget.onPick(agent.guid, agent.name);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AgentsCubit>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Пошук агента',
              hintText: 'Введіть ім’я агента',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        setState(() => _isSearch = false);
                        cubit.loadRoot();
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) {
              final isActive = v.trim().isNotEmpty;
              setState(() => _isSearch = isActive);
              if (isActive) {
                cubit.search(v);
              } else {
                cubit.loadRoot();
              }
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<AgentsCubit, AgentsState>(
            builder: (context, state) {
              if (state.status == AgentsStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == AgentsStatus.failure) {
                return Center(child: Text(state.error ?? 'Помилка'));
              }

              final items = state.items;
              if (items.isEmpty) {
                return const Center(child: Text('Нічого не знайдено'));
              }

              // Search mode -> flat list with back-to-folders button
              if (_isSearch) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final a = items[index];
                          if (a.isFolder) {
                            return ListTile(
                              leading: const Icon(Icons.folder),
                              title: Text(a.name),
                              onTap: () async {
                                // Expand to children on tap in search mode
                                final children = await cubit.repository
                                    .getChildren(a.guid);
                                if (!mounted) return;
                                showModalBottomSheet(
                                  context: context,
                                  builder: (ctx) => ListView.builder(
                                    itemCount: children.length,
                                    itemBuilder: (ctx, i) {
                                      final ch = children[i];
                                      if (ch.isFolder) {
                                        return ListTile(
                                          leading: const Icon(Icons.folder),
                                          title: Text(ch.name),
                                          onTap: () async {
                                            final sub = await cubit.repository
                                                .getChildren(ch.guid);
                                            // replace with sub-list
                                            Navigator.of(ctx).push(
                                              MaterialPageRoute(
                                                builder: (_) => Scaffold(
                                                  appBar: AppBar(
                                                    title: Text(ch.name),
                                                  ),
                                                  body: ListView.builder(
                                                    itemCount: sub.length,
                                                    itemBuilder: (context, j) {
                                                      final s = sub[j];
                                                      if (s.isFolder) {
                                                        return ListTile(
                                                          leading: const Icon(
                                                            Icons.folder,
                                                          ),
                                                          title: Text(s.name),
                                                        );
                                                      }
                                                      return ListTile(
                                                        leading: const Icon(
                                                          Icons.person,
                                                        ),
                                                        title: Text(s.name),
                                                        onTap: () =>
                                                            widget.onPick(
                                                              s.guid,
                                                              s.name,
                                                            ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      return ListTile(
                                        leading: const Icon(Icons.person),
                                        title: Text(ch.name),
                                        onTap: () => _attemptPick(ch),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          }
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(a.name),
                            onTap: () => _attemptPick(a),
                          );
                        },
                      ),
                    ),
                    const _BackToFoldersButton(),
                  ],
                );
              }

              // Tree mode with lazy expansion similar to nomenclature
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final a = items[index];
                  if (a.isFolder) {
                    return _AgentFolderNode(
                      title: a.name,
                      guid: a.guid,
                      onPick: widget.onPick,
                      cubit: cubit,
                    );
                  }
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(a.name),
                    onTap: () => _attemptPick(a),
                  );
                },
              );
            },
          ),
        ),
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
          onPressed: () => context.read<AgentsCubit>().loadRoot(),
          child: const Text('Повернутись до папок'),
        ),
      ),
    );
  }
}

class _AgentFolderNode extends StatelessWidget {
  const _AgentFolderNode({
    required this.title,
    required this.guid,
    required this.onPick,
    required this.cubit,
  });
  final String title;
  final String guid;
  final Future<void> Function(String, String) onPick;
  final AgentsCubit cubit;

  @override
  Widget build(BuildContext context) {
    Future<void> _attemptPickLocal(AgentModel agent) async {
      final requiredPassword = (agent.password ?? '').trim();
      if (requiredPassword.isNotEmpty) {
        final controller = TextEditingController();
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Введіть пароль агента'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Пароль'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Скасувати'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    ctx,
                  ).pop(controller.text.trim() == requiredPassword);
                },
                child: const Text('Підтвердити'),
              ),
            ],
          ),
        );
        if (ok != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Невірний пароль агента')),
          );
          return;
        }
      }
      await onPick(agent.guid, agent.name);
    }

    return _LazyExpansionTile(
      title: Text(title),
      leading: const Icon(Icons.folder),
      loadChildren: () => cubit.repository.getChildren(guid),
      itemBuilder: (context, child) {
        if (child.isFolder) {
          return _AgentFolderNode(
            title: child.name,
            guid: child.guid,
            onPick: onPick,
            cubit: cubit,
          );
        }
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(child.name),
          onTap: () => _attemptPickLocal(child),
        );
      },
    );
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
