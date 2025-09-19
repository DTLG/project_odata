import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../kontragenty/data/models/kontragent_model.dart';
import '../../../kontragenty/data/datasources/kontragent_local_data_source.dart';
import '../../../../core/injection/injection_container.dart';
import '../../domain/entities/repair_request_entity.dart';
import '../../data/datasources/local/sqflite_repair_local_data_source.dart';
import '../../data/models/repair_request_model.dart';
import '../../data/datasources/local/repair_local_data_source.dart';
import '../widgets/repair_customer_selection_tab.dart';
import '../widgets/repair_product_selection_tab.dart';
import '../widgets/repair_details_tab.dart';
import '../widgets/repair_confirmation_tab.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/repair_request_cubit.dart';
import '../../data/datasources/local/sqlite_types_of_repair_datasource.dart';
import '../../data/datasources/remote/supabase_types_of_repair_datasource.dart';
import '../../data/repositories/types_of_repair_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/routes/app_router.dart';
import '../../../nomenclature/ui/cubit/nomenclature_cubit.dart';

class RepairRequestPage extends StatefulWidget {
  final RepairRequestEntity? initial;
  final KontragentModel? initialCustomer;
  final List<dynamic>? prefetchedNomenclature;
  const RepairRequestPage({
    super.key,
    this.initial,
    this.initialCustomer,
    this.prefetchedNomenclature,
  });

  @override
  State<RepairRequestPage> createState() => _RepairRequestPageState();
}

class _RepairRequestPageState extends State<RepairRequestPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final RepairLocalDataSource _repairLocal;
  late final KontragentLocalDataSource _kontrLocal;

  KontragentModel? _customer;
  String? _nomGuid;
  String _repairType = '';
  String _agentGuid = '';
  String _status = '';
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _statusCtrl = TextEditingController();
  List<RepairTypeModel> _repairTypes = const [];
  // no sending flag needed here
  String _localDraftId = '';
  List<KontragentModel> _prefetchedCustomers = const [];
  bool _readOnly = false;
  int? _serverId;

  @override
  void initState() {
    super.initState();
    _repairLocal = RepairLocalDataSourceImpl();
    _kontrLocal = sl<KontragentLocalDataSource>();
    // hydrate initial BEFORE creating tab controller to choose initialIndex
    final i = widget.initial;
    if (i != null) {
      _customer = widget.initialCustomer;
      _nomGuid = i.nomGuid;
      _repairType = i.typeOfRepairGuid;
      _status = i.status;
      _desc.text = i.description;
      // price removed from entity; keep UI-only controller as-is
      _statusCtrl.text = i.status;
      // _agentGuid = i.agentGuid;
      _localDraftId = i.docGuid ?? i.number;
      // read-only if downloaded or already has server id
      _readOnly = i.downloaded || (i.id != null);
      _serverId = i.id;
    }
    _tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: _readOnly ? 2 : 0,
    );
    _desc.addListener(() => setState(() {}));
    _price.addListener(() => setState(() {}));
    _statusCtrl.addListener(() {
      _status = _statusCtrl.text;
      setState(() {});
    });

    // Load types of repair (local, sync if empty)
    _loadRepairTypes();
    // Load agent guid from SharedPreferences
    _loadAgentFromPrefs();
    // Preload customers once
    // _preloadCustomers();
    // Ensure nomenclature tree is available for product tab
    try {
      sl<NomenclatureCubit>().loadRootTree();
    } catch (_) {}
  }

  String _resolveRepairTypeName(String guid) {
    if (guid.isEmpty) return '';
    try {
      final found = _repairTypes.firstWhere(
        (e) => (e.guid as String?)?.trim() == guid,
        orElse: () => _repairTypes.firstWhere((_) => false),
      );
      return (found.name as String?)?.trim() ?? guid;
    } catch (_) {
      return guid;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _desc.dispose();
    _price.dispose();
    _statusCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRepairTypes() async {
    final local = SqliteTypesOfRepairDatasource();
    final count = await local.getCount();
    if (count == 0) {
      final client = Supabase.instance.client;
      final repo = TypesOfRepairRepository(
        local: local,
        remote: SupabaseTypesOfRepairDatasource(client),
      );
      await repo.sync();
    }
    final all = await local.getAll();
    if (mounted) setState(() => _repairTypes = all);
  }

  Future<void> _preloadCustomers() async {
    try {
      final all = await _kontrLocal.getAllKontragenty();
      if (mounted) setState(() => _prefetchedCustomers = all);
    } catch (e) {
      // ignore: avoid_print
      print('Не вдалося завантажити клієнтів: $e');
    }
  }

  Future<void> _loadAgentFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guid = prefs.getString('agent_guid') ?? '';
      if (guid.isNotEmpty && mounted) {
        setState(() => _agentGuid = guid);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Не вдалося зчитати agent_guid з SharedPreferences: $e');
    }
  }

  Future<void> _saveLocal(BuildContext blocContext) async {
    final s = blocContext.read<RepairRequestCubit>().state;
    final selectedNomGuid = s.nomenclatureGuid.isNotEmpty
        ? s.nomenclatureGuid
        : (_nomGuid ?? '');
    final selectedRepairType = s.repairType.isNotEmpty
        ? s.repairType
        : _repairType;
    final description = s.description.isNotEmpty
        ? s.description
        : _desc.text.trim();
    // Ensure stable local draft id
    if (_serverId == null && _localDraftId.isEmpty) {
      _localDraftId = 'Локальний-${DateTime.now().millisecondsSinceEpoch}';
    }
    final model = RepairRequestEntity(
      id: _serverId,
      // id is optional (int?) for server identity; local can omit
      createdAt: DateTime.now(),
      customerGuid: _customer?.guid ?? '',
      status: _status,
      docGuid: _serverId != null ? null : _localDraftId,
      zapchastyny: const [],
      diagnostyka: const [],
      roboty: const [],
      number: '',
      nomGuid: selectedNomGuid,
      nomName: '',
      downloaded: false,
      description: description,
      agentGuid: _agentGuid,
      typeOfRepairGuid: selectedRepairType,
      date: DateTime.now(),
    );
    await _repairLocal.save(RepairRequestModel.fromEntity(model));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Заявку збережено локально')));
  }

  Future<void> _sendToServer(BuildContext blocContext) async {
    final s = blocContext.read<RepairRequestCubit>().state;
    final selectedNomGuid = s.nomenclatureGuid.isNotEmpty
        ? s.nomenclatureGuid
        : (_nomGuid ?? '');
    final selectedRepairType = s.repairType.isNotEmpty
        ? s.repairType
        : _repairType;
    final description = s.description.isNotEmpty
        ? s.description
        : _desc.text.trim();
    if (_customer == null ||
        selectedNomGuid.isEmpty ||
        selectedRepairType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заповніть клієнта, товар і тип ремонту')),
      );
      return;
    }
    // start sending
    try {
      final entity = RepairRequestEntity(
        createdAt: DateTime.now(),
        customerGuid: _customer?.guid ?? '',
        status: _status,
        docGuid: null,
        zapchastyny: const [],
        diagnostyka: const [],
        roboty: const [],
        number: '',
        nomGuid: selectedNomGuid,
        nomName: '',
        downloaded: false,
        description: description,
        agentGuid: _agentGuid,
        typeOfRepairGuid: selectedRepairType,
        date: DateTime.now(),
      );
      final model = RepairRequestModel.fromEntity(entity);
      final client = Supabase.instance.client;
      final schema = SupabaseConfig.schema;
      // ignore: avoid_print
      print('⬆️ Надсилання service_orders до схеми: $schema');
      final inserted = await client
          .schema(schema)
          .from('service_orders')
          .insert(model.toJson())
          .select()
          .single();
      // ignore: avoid_print
      print('✅ Відправлено service_orders id=${inserted['id']}');
      // remember server id to ensure updates on next local save
      try {
        final insertedId = inserted['id'];
        if (insertedId is int) {
          _serverId = insertedId;
        } else if (insertedId != null) {
          _serverId = int.tryParse(insertedId.toString());
        }
      } catch (_) {}
      // After successful send, update local draft key to server id
      try {
        final newId = inserted['id']?.toString();
        if (newId != null && newId.isNotEmpty) {
          // keep previous key to delete draft afterwards
          final previousLocalKey = _localDraftId;
          // Save again locally to replace key and persist new id
          final saved = RepairRequestModel.fromEntity(entity).toJson();
          saved['id'] = inserted['id'];
          await _repairLocal.save(RepairRequestModel.fromJson(saved));
          // update in-memory key to server id
          _localDraftId = newId;
          // delete old draft record if different and non-empty
          if (previousLocalKey.isNotEmpty && previousLocalKey != newId) {
            await _repairLocal.delete(previousLocalKey);
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ Не вдалося оновити локальний id після відправки: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Надіслано на сервер')));
    } catch (e) {
      // ignore: avoid_print
      print('❌ Помилка надсилання service_orders: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка надсилання: $e')));
    } finally {
      // done sending
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RepairRequestCubit()
        ..initialize(
          customer: _customer,
          nomenclatureGuid: _nomGuid,
          repairType: _repairType,
          status: _status,
          description: _desc.text,
          price: double.tryParse(_price.text.trim()) ?? 0.0,
          zapchastyny: widget.initial?.zapchastyny,
          diagnostyka: widget.initial?.diagnostyka,
          roboty: widget.initial?.roboty,
        ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Заявка на ремонт'),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: AppTheme.accentColor,
            labelColor: AppTheme.accentColor,
            unselectedLabelColor: Colors.white,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Клієнт'),
              Tab(icon: Icon(Icons.build), text: 'Товар'),
              Tab(icon: Icon(Icons.description), text: 'Деталі'),
              Tab(icon: Icon(Icons.check_circle), text: 'Підтвердження'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_readOnly)
              Container(
                width: double.infinity,
                color: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Документ неможливо редагувати. Режим лише для перегляду.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Builder(
                builder: (innerCtx) => TabBarView(
                  controller: _tabs,
                  children: [
                    KeepAliveWrapper(
                      child: AbsorbPointer(
                        absorbing: _readOnly,
                        child: RepairCustomerSelectionTab(
                          prefetched: _prefetchedCustomers,
                          onSelected: (c) {
                            innerCtx.read<RepairRequestCubit>().setCustomer(c);
                            setState(() => _customer = c);
                            _tabs.animateTo(1);
                          },
                        ),
                      ),
                    ),
                    KeepAliveWrapper(
                      child: AbsorbPointer(
                        absorbing: _readOnly,
                        child: BlocProvider(
                          create: (_) =>
                              sl<NomenclatureCubit>()..loadRootTree(),
                          child: RepairProductSelectionTab(
                            initialGuid: _nomGuid,
                            onSelected: (guid) {
                              innerCtx
                                  .read<RepairRequestCubit>()
                                  .setNomenclatureGuid(guid);
                              // setState(() => _nomGuid = guid);
                            },
                            prefetched: widget.prefetchedNomenclature,
                          ),
                        ),
                      ),
                    ),
                    KeepAliveWrapper(
                      child: RepairDetailsTab(
                        repairTypes: _repairTypes,
                        readOnly: _readOnly,
                      ),
                    ),
                    KeepAliveWrapper(
                      child:
                          BlocBuilder<RepairRequestCubit, RepairRequestState>(
                            builder: (context, s) {
                              return RepairConfirmationTab(
                                readOnly: _readOnly,
                                onSaveLocal: () {
                                  _saveLocal(innerCtx);
                                  AppRouter.goBack(context);
                                },
                                onSend: () async {
                                  await _saveLocal(innerCtx);
                                  await _sendToServer(innerCtx);
                                  AppRouter.goBack(context);
                                },
                                customer: s.customer ?? _customer,
                                nomenclatureGuid: s.nomenclatureGuid.isNotEmpty
                                    ? s.nomenclatureGuid
                                    : (_nomGuid ?? ''),
                                repairTypeName: _resolveRepairTypeName(
                                  s.repairType.isNotEmpty
                                      ? s.repairType
                                      : _repairType,
                                ),
                                status: s.status.isNotEmpty
                                    ? s.status
                                    : _status,
                                descController: _desc,
                                priceController: _price,
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keeps tab subtree alive to prevent rebuild jank when switching tabs
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
