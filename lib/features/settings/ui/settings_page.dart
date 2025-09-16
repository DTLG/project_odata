import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../features/agents/data/datasources/local/sqlite_agents_datasource.dart';
import '../../../features/agents/data/datasources/remote/supabase_agents_datasource.dart';
import '../cubit/settings_cubit.dart';
import '../models/price_type.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../features/agents/data/repositories/agents_repository_impl.dart';
import '../../../features/agents/presentation/pages/agent_selection_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Налаштування')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state.status.isInitial) {
              context.read<SettingsCubit>().getAgent();
              context.read<SettingsCubit>().getPrinterData();
              context.read<SettingsCubit>().getApiData();
              context.read<SettingsCubit>().getStorage();
              context.read<SettingsCubit>().getPiceType();
              context.read<SettingsCubit>().loadHomeIcons();
            }

            if (state.status.isFailure && state.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              });

              // WidgetsBinding.instance.addPostFrameCallback((_) {
              //   showDialog(
              //     context: context,
              //     builder: (ctx) => AlertDialog(
              //       title: const Text('Помилка'),
              //       content: SingleChildScrollView(
              //         child: Text(state.errorMessage!),
              //       ),
              //       actions: [
              //         TextButton(
              //           onPressed: () {
              //             Navigator.of(ctx).pop();
              //             context.read<SettingsCubit>().clearError();
              //           },
              //           child: const Text('OK'),
              //         ),
              //       ],
              //     ),
              //   );
              // });
            }

            if (state.status.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              children: const [
                _SupabaseSettingsCard(),
                SizedBox(height: 8),
                _ThemeModeCard(),
                SizedBox(height: 8),
                _HomePageIconsCard(),
                _DataBasePathWidget(),
                _PrinterSettingsWidget(),
                _StorageCard(),
                _ParamsCard(),
                _AgentsCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SupabaseSettingsCard extends StatefulWidget {
  const _SupabaseSettingsCard();

  @override
  State<_SupabaseSettingsCard> createState() => _SupabaseSettingsCardState();
}

class _SupabaseSettingsCardState extends State<_SupabaseSettingsCard> {
  final urlController = TextEditingController(text: SupabaseConfig.supabaseUrl);
  final keyController = TextEditingController(
    text: SupabaseConfig.supabaseAnonKey,
  );
  final schemaController = TextEditingController(text: SupabaseConfig.schema);

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    await SupabaseConfig.loadFromPrefs();
    if (!mounted) return;
    setState(() {
      urlController.text = SupabaseConfig.supabaseUrl;
      keyController.text = SupabaseConfig.supabaseAnonKey;
      schemaController.text = SupabaseConfig.schema;
    });
  }

  @override
  void dispose() {
    urlController.dispose();
    keyController.dispose();
    schemaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: ExpansionTile(
        title: const Text('Supabase конфігурація'),
        subtitle: Text('Схема: ${SupabaseConfig.schema}'),
        shape: Border.all(color: Colors.transparent),
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextField(
              controller: urlController,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(hintText: 'Supabase URL'),
              onChanged: (v) => SupabaseConfig.saveToPrefs(url: v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextField(
              controller: keyController,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(hintText: 'Supabase anon key'),
              onChanged: (v) => SupabaseConfig.saveToPrefs(anonKey: v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextField(
              controller: schemaController,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Schema (наприклад, public)',
              ),
              onChanged: (v) => SupabaseConfig.saveToPrefs(newSchema: v),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DataBasePathWidget extends StatefulWidget {
  const _DataBasePathWidget();

  @override
  State<_DataBasePathWidget> createState() => _DataBasePathWidgetState();
}

class _DataBasePathWidgetState extends State<_DataBasePathWidget> {
  final hostController = TextEditingController();
  final dbController = TextEditingController();

  final passController = TextEditingController();
  final userController = TextEditingController();

  void _maybeFetchPriceType(BuildContext context) {
    final host = hostController.text.trim();
    final db = dbController.text.trim();
    final user = userController.text.trim();
    final pass = passController.text.trim();
    if (host.isNotEmpty &&
        db.isNotEmpty &&
        user.isNotEmpty &&
        pass.isNotEmpty) {
      context.read<SettingsCubit>().getPiceType();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final state = context.select((SettingsCubit cubit) => cubit.state);
    hostController.text = state.host;
    dbController.text = state.dbName;
    userController.text = state.user;
    passController.text = state.pass;
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SettingsCard(
          child: ExpansionTile(
            title: const Text('Шлях до бази даних'),
            shape: Border.all(color: Colors.transparent),
            children: [
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: TextField(
                  style: const TextStyle(fontSize: 12),
                  textAlignVertical: TextAlignVertical.center,
                  controller: hostController,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    cubit.writeSp('host', value);
                    cubit.gethost();
                    _maybeFetchPriceType(context);
                  },
                  decoration: const InputDecoration(hintText: 'host'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: TextField(
                  style: const TextStyle(fontSize: 12),
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.next,
                  controller: dbController,
                  onChanged: (value) {
                    cubit.writeSp('db_name', value);
                    cubit.getDbName();
                    _maybeFetchPriceType(context);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Назва бази даних',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: TextField(
                  style: const TextStyle(fontSize: 14),
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.next,
                  controller: userController,
                  onChanged: (value) {
                    cubit.writeSp('user', value);
                    cubit.getUser();
                    _maybeFetchPriceType(context);
                  },
                  decoration: const InputDecoration(labelText: 'Користувач'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: TextField(
                  style: const TextStyle(fontSize: 14),
                  textInputAction: TextInputAction.next,
                  controller: passController,
                  onChanged: (value) async {
                    cubit.writeSp('pass', value);
                    cubit.getPass();
                    _maybeFetchPriceType(context);
                  },
                  decoration: const InputDecoration(labelText: 'Пароль'),
                ),
              ),
              const SizedBox(height: 3),
            ],
          ),
        );
      },
    );
  }
}

class _PrinterSettingsWidget extends StatefulWidget {
  const _PrinterSettingsWidget();

  @override
  State<_PrinterSettingsWidget> createState() => _PrinterSettingsWidgetState();
}

class _PrinterSettingsWidgetState extends State<_PrinterSettingsWidget> {
  final hostController = TextEditingController();
  final portController = TextEditingController();
  final focusNode = FocusNode();

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(top: true, child: child),
      ),
    );
  }

  final double _kItemExtent = 32.0;
  final _value = List.generate(3, (index) => index + 1);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        hostController.text = state.printerHost;
        portController.text = state.printerPort;
        return SettingsCard(
          child: ExpansionTile(
            title: const Text('Налаштування принтера'),
            shape: Border.all(color: Colors.transparent),
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: TextField(
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 12),
                  controller: hostController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    cubit.writeSp('printer_host', value);
                    cubit.getPrinterData();
                  },
                  onSubmitted: (value) {
                    focusNode.nextFocus();
                  },
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () {
                        hostController.clear();
                        focusNode.requestFocus();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                    hintText: 'host',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                child: TextField(
                  style: const TextStyle(fontSize: 12),
                  controller: portController,
                  onChanged: (value) {
                    cubit.writeSp('printer_port', value);
                    cubit.getPrinterData();
                  },
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () {
                        portController.clear();
                        focusNode.requestFocus();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                    hintText: 'port',
                  ),
                ),
              ),
              ListTile(
                onTap: () {
                  _showDialog(
                    CupertinoPicker(
                      magnification: 1.22,
                      squeeze: 1.2,
                      useMagnifier: true,
                      itemExtent: _kItemExtent,
                      scrollController: FixedExtentScrollController(
                        initialItem: _value.indexOf(state.darknees),
                      ),
                      onSelectedItemChanged: (int selectedItem) {
                        cubit.writeSp('darkness', selectedItem + 1);
                        cubit.getPrinterDarkness();
                      },
                      children: List<Widget>.generate(_value.length, (
                        int index,
                      ) {
                        return Center(child: Text(_value[index].toString()));
                      }),
                    ),
                  );
                },
                title: const Text('Насиченість'),
                contentPadding: const EdgeInsets.only(left: 20),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return Text(state.darknees.toString());
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      color: theme.cardColor,
      shape: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _HomePageIconsCard extends StatelessWidget {
  const _HomePageIconsCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SettingsCard(
          child: ExpansionTile(
            title: const Text('Налаштування головної сторінки'),
            children: [
              _IconToggle(
                title: 'Друк етикеток',
                value: state.showLabelPrint,
                onChanged: (v) => context.read<SettingsCubit>().setHomeIcon(
                  'home_show_label_print',
                  v,
                ),
              ),
              _IconToggle(
                title: 'Перевірка номенклатури',
                value: state.showNomenclature,
                onChanged: (v) => context.read<SettingsCubit>().setHomeIcon(
                  'home_show_nomenclature',
                  v,
                ),
              ),
              _IconToggle(
                title: 'Замовлення клієнта',
                value: state.showCustomerOrders,
                onChanged: (v) => context.read<SettingsCubit>().setHomeIcon(
                  'home_show_customer_orders',
                  v,
                ),
              ),
              _IconToggle(
                title: 'Інвентаризація',
                value: state.showInventoryCheck,
                onChanged: (v) => context.read<SettingsCubit>().setHomeIcon(
                  'home_show_inventory_check',
                  v,
                ),
              ),
              _IconToggle(
                title: 'Контрагенти',
                value: state.showKontragenty,
                onChanged: (v) => context.read<SettingsCubit>().setHomeIcon(
                  'home_show_kontragenty',
                  v,
                ),
              ),
              _IconToggle(
                title: 'Заявка на ремонт',
                value: state.showRepairRequests,
                onChanged: (v) => context.read<SettingsCubit>().setHomeIcon(
                  'home_show_repair_requests',
                  v,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconToggle extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _IconToggle({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final storage = state.storage;
        return SettingsCard(
          child: ListTile(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<SettingsCubit>(),
                  child: const _ListStorageCard(),
                ),
              );
            },
            title: const Text('Склад'),
            trailing: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                if (state.status.isSuccess) {
                  return SizedBox(
                    width: 200,
                    child: Text(storage.name ?? '', textAlign: TextAlign.end),
                  );
                }
                return SizedBox(
                  width: 200,
                  child: Text(storage.name ?? '', textAlign: TextAlign.end),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ListStorageCard extends StatefulWidget {
  const _ListStorageCard();

  @override
  State<_ListStorageCard> createState() => _ListStorageCardState();
}

class _ListStorageCardState extends State<_ListStorageCard> {
  @override
  void initState() {
    context.read<SettingsCubit>().getStorageList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      iconPadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 30),
          Text('Склад', style: theme.textTheme.titleLarge),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.status.isFailure) {
            return SizedBox(
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Базу даних не знайдено!!!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall!.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Перевірте параметри бази даних, або підключення до інтернету.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall!.copyWith(fontSize: 15),
                  ),
                ],
              ),
            );
          }
          if (state.status.isLoading) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return SizedBox(
            height: state.storages.storages.length * 60,
            width: 600,
            child: ListView.separated(
              itemCount: state.storages.storages.length,
              itemBuilder: (context, index) => ListTile(
                onTap: () {
                  context.read<SettingsCubit>().writeStorageSettings(
                    state.storages.storages[index],
                  );
                  context.read<SettingsCubit>().getStorage();
                  Navigator.pop(context);
                },
                title: Text(state.storages.storages[index].name ?? ''),
              ),
              separatorBuilder: (context, index) =>
                  const Divider(endIndent: 15, indent: 15, height: 1),
            ),
          );
        },
      ),
    );
  }
}

class _ParamsCard extends StatefulWidget {
  const _ParamsCard();
  @override
  State<_ParamsCard> createState() => _ParamsCardState();
}

class _ParamsCardState extends State<_ParamsCard> {
  bool isDownload = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SettingsCard(
          child: ExpansionTile(
            title: Text.rich(
              TextSpan(
                text: 'Тип ціни: ',
                style: DefaultTextStyle.of(
                  context,
                ).style, // або задай свій стиль
                children: [
                  TextSpan(
                    text: state.priceType.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            children: state.allPriceType.map<Widget>((PriceType priceType) {
              return ListTile(
                title: Text(priceType.description),
                trailing: (state.priceType.id == (priceType.id))
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  context.read<SettingsCubit>().selectPriceType(priceType);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _AgentsCard extends StatefulWidget {
  const _AgentsCard();
  @override
  State<_AgentsCard> createState() => _AgentsCardState();
}

class _AgentsCardState extends State<_AgentsCard> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SettingsCard(
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AgentSelectionPage(
                    repository: AgentsRepositoryImpl(
                      local: SqliteAgentsDatasourceImpl(),
                      remote: SupabaseAgentsDatasourceImpl(
                        Supabase.instance.client,
                      ),
                    ),
                  ),
                ),
              ).then((value) {
                context.read<SettingsCubit>().getAgent();
              });
            },
            title: const Text('Агент'),
            trailing: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                if (state.status.isSuccess) {
                  return SizedBox(
                    width: 200,
                    child: Text(state.agentName, textAlign: TextAlign.end),
                  );
                }
                return SizedBox(
                  width: 200,
                  child: Text(state.agentName, textAlign: TextAlign.end),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: ExpansionTile(
        title: const Text('Тема додатка'),
        subtitle: const Text('Світла / Темна / Системна'),
        shape: Border.all(color: Colors.transparent),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.instance.themeModeNotifier,
              builder: (context, mode, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: mode,
                      title: const Text('Системна'),
                      onChanged: (val) {
                        if (val != null)
                          ThemeController.instance.setThemeMode(val);
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: mode,
                      title: const Text('Світла'),
                      onChanged: (val) {
                        if (val != null)
                          ThemeController.instance.setThemeMode(val);
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: mode,
                      title: const Text('Темна'),
                      onChanged: (val) {
                        if (val != null)
                          ThemeController.instance.setThemeMode(val);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
