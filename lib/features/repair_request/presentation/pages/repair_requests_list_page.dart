import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../kontragenty/data/datasources/kontragent_local_data_source.dart';
import '../../../kontragenty/data/models/kontragent_model.dart';
import '../../data/models/repair_request_model.dart';
import 'repair_request_page.dart';
import '../../../nomenclature/data/datasources/local/nomenclature_local_datasource.dart';
import '../../data/datasources/local/sqflite_repair_local_data_source.dart';
import '../../data/datasources/local/repair_local_data_source.dart';
import '../../../../core/injection/injection_container.dart';

enum RepairStatus {
  approvedRepair,
  diagnostated,
  diagnostic,
  awaitingRepair,
  issued,
  notRepairable,
  ready,
  awaitingApproval,
  accepted,
  unknown,
  rejectedRepair,
}

extension RepairStatusX on RepairStatus {
  static RepairStatus fromString(String? value) {
    switch (value?.trim()) {
      case 'Відхилено ремонт':
        return RepairStatus.rejectedRepair;
      case 'Погоджено ремонт':
        return RepairStatus.approvedRepair;
      case 'Діагностовано':
        return RepairStatus.diagnostated;
      case 'На діагностиці':
        return RepairStatus.diagnostic;
      case 'Очікується ремонту':
        return RepairStatus.awaitingRepair;
      case 'Видано':
        return RepairStatus.issued;
      case 'Не підлягає ремонту':
        return RepairStatus.notRepairable;
      case 'Очікує погодження':
        return RepairStatus.awaitingApproval;
      case 'Готово':
        return RepairStatus.ready;
      case 'Прийнята':
        return RepairStatus.accepted;
      default:
        return RepairStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case RepairStatus.rejectedRepair:
        return 'Відхилено ремонт';
      case RepairStatus.approvedRepair:
        return 'Погоджено ремонт';
      case RepairStatus.diagnostated:
        return 'Діагностовано';
      case RepairStatus.diagnostic:
        return 'На діагностиці';
      case RepairStatus.awaitingRepair:
        return 'Очікується ремонту';
      case RepairStatus.issued:
        return 'Видано';
      case RepairStatus.notRepairable:
        return 'Не підлягає ремонту';
      case RepairStatus.awaitingApproval:
        return 'Очікує погодження';
      case RepairStatus.ready:
        return 'Готово';
      case RepairStatus.accepted:
        return 'Прийнята';
      case RepairStatus.unknown:
        return 'Невідомо';
    }
  }

  Color get color {
    switch (this) {
      case RepairStatus.rejectedRepair:
        return Colors.red;
      case RepairStatus.approvedRepair:
        return Colors.blue;
      case RepairStatus.diagnostic:
        return const Color.fromARGB(255, 80, 231, 186);
      case RepairStatus.diagnostated:
        return const Color.fromARGB(255, 206, 247, 111);
      case RepairStatus.awaitingRepair:
        return Colors.orange;
      case RepairStatus.issued:
        return Colors.green;
      case RepairStatus.notRepairable:
        return Colors.red;
      case RepairStatus.ready:
        return Colors.lightGreen;
      case RepairStatus.awaitingApproval:
        return Colors.orange;
      case RepairStatus.accepted:
        return Colors.indigo;
      case RepairStatus.unknown:
        return Colors.grey;
    }
  }
}

class RepairRequestsListPage extends StatefulWidget {
  const RepairRequestsListPage({super.key});

  @override
  State<RepairRequestsListPage> createState() => _RepairRequestsListPageState();
}

class _RepairRequestsListPageState extends State<RepairRequestsListPage> {
  late final RepairLocalDataSource _local;
  late final KontragentLocalDataSource _kontrLocal;
  late final NomenclatureLocalDatasource _nomLocal;
  List<RepairRequestModel> _items = const [];
  final Map<String, String> _customerNameByGuid = {};
  bool _loading = true;
  List<dynamic> _prefetchedNomenclature = const [];
  String? _errorMessage;
  bool _showRemote = true; // true: Supabase, false: Local
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _local = RepairLocalDataSourceImpl();
    _kontrLocal = sl<KontragentLocalDataSource>();
    _nomLocal = sl<NomenclatureLocalDatasource>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      // _prefetchNomenclature();
      _subscribeRealtime();
    });
  }

  Future<void> _load() async {
    if (_showRemote) {
      await _loadRemote();
    } else {
      await _loadLocal();
    }
  }

  Future<void> _loadLocal() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      // ignore: avoid_print
      print('📦 Завантаження локальних заявок');
      final list = await _local.getAll();

      _customerNameByGuid.clear();
      final guids = list
          .map((e) => e.customerGuid)
          .where((g) => g.isNotEmpty)
          .toSet();
      await Future.wait(
        guids.map((g) async {
          final c = await _kontrLocal.getKontragentByGuid(g);
          if (c != null) _customerNameByGuid[g] = c.name;
        }),
      );

      setState(() {
        _items = list;
        _loading = false;
      });
      // ignore: avoid_print
      print('✅ Локальних записів: ${list.length}');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Помилка завантаження локальних заявок: $e');
      setState(() {
        _errorMessage = 'Не вдалося завантажити локальні заявки: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadRemote() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final client = Supabase.instance.client;
      final schema = SupabaseConfig.schema;
      // ignore: avoid_print
      print('🔄 Завантаження service_orders зі схеми: $schema');
      final resp = await client
          .schema(schema)
          .from('service_orders')
          .select('*')
          .order('created_at', ascending: false);

      final list = (resp as List)
          .map((e) => RepairRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // resolve customer names once
      _customerNameByGuid.clear();
      final guids = list
          .map((e) => e.customerGuid)
          .where((g) => g.isNotEmpty)
          .toSet();
      await Future.wait(
        guids.map((g) async {
          final c = await _kontrLocal.getKontragentByGuid(g);
          if (c != null) _customerNameByGuid[g] = c.name;
        }),
      );

      setState(() {
        _items = list;
        _loading = false;
      });
      // ignore: avoid_print
      print('✅ Завантажено записів: ${list.length}');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Помилка завантаження service_orders: $e');
      setState(() {
        _errorMessage = 'Не вдалося завантажити заявки: $e';
        _loading = false;
      });
    }
  }

  void _subscribeRealtime() {
    try {
      final client = Supabase.instance.client;
      final schema = SupabaseConfig.schema;
      // Clean previous
      _channel?.unsubscribe();
      _channel = client
          .channel('service_orders-changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: schema,
            table: 'service_orders',
            callback: (payload) async {
              // ignore: avoid_print
              print(
                '📥 RT insert service_orders id=${payload.newRecord['id']}',
              );
              if (!_showRemote) return; // only reflect in remote mode
              final map = Map<String, dynamic>.from(payload.newRecord);
              final model = RepairRequestModel.fromJson(map);
              // Resolve customer name if needed
              if (model.customerGuid.isNotEmpty &&
                  !_customerNameByGuid.containsKey(model.customerGuid)) {
                final c = await _kontrLocal.getKontragentByGuid(
                  model.customerGuid,
                );
                if (c != null) _customerNameByGuid[model.customerGuid] = c.name;
              }
              if (!mounted) return;
              setState(() {
                final existsIndex = _items.indexWhere((e) => e.id == model.id);
                if (existsIndex >= 0) {
                  _items = List.of(_items)..[existsIndex] = model;
                } else {
                  _items = [model, ..._items];
                }
              });
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: schema,
            table: 'service_orders',
            callback: (payload) async {
              // ignore: avoid_print
              print(
                '♻️ RT update service_orders id=${payload.newRecord['id']}',
              );
              if (!_showRemote) return;
              final map = Map<String, dynamic>.from(payload.newRecord);
              final model = RepairRequestModel.fromJson(map);
              if (model.customerGuid.isNotEmpty &&
                  !_customerNameByGuid.containsKey(model.customerGuid)) {
                final c = await _kontrLocal.getKontragentByGuid(
                  model.customerGuid,
                );
                if (c != null) _customerNameByGuid[model.customerGuid] = c.name;
              }
              if (!mounted) return;
              setState(() {
                final idx = _items.indexWhere((e) => e.id == model.id);
                if (idx >= 0) {
                  _items = List.of(_items)..[idx] = model;
                }
              });
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: schema,
            table: 'service_orders',
            callback: (payload) {
              // ignore: avoid_print
              print(
                '🗑️ RT delete service_orders id=${payload.oldRecord['id']}',
              );
              if (!_showRemote) return;
              final id = payload.oldRecord['id'];
              if (!mounted) return;
              setState(() {
                _items = _items.where((e) => e.id != id).toList();
              });
            },
          )
          .subscribe();
      // ignore: avoid_print
      print('📡 Підписка на realtime service_orders активна');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Помилка підписки на realtime: $e');
    }
  }

  void _unsubscribeRealtime() {
    try {
      _channel?.unsubscribe();
      _channel = null;
      // ignore: avoid_print
      print('🔕 Відписано від realtime service_orders');
    } catch (_) {}
  }

  Future<void> _prefetchNomenclature() async {
    try {
      final all = await _nomLocal.getAllNomenclature();
      setState(() => _prefetchedNomenclature = all);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки на ремонт'),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            _unsubscribeRealtime();
          },
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Локально'),
              ),
              Switch(
                value: _showRemote,
                onChanged: (v) async {
                  setState(() => _showRemote = v);
                  if (v) {
                    _subscribeRealtime();
                  } else {
                    _unsubscribeRealtime();
                  }
                  await _load();
                },
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('БД'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(_errorMessage!, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _load,
                    child: const Text('Спробувати знову'),
                  ),
                ],
              ),
            )
          : _items.isEmpty
          ? const Center(child: Text('Немає заявок'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final order = _items[index];
                  final customerName = _customerNameByGuid[order.customerGuid];
                  final created = order.createdAt?.toLocal().toString() ?? '';
                  final status = RepairStatusX.fromString(order.status);
                  return ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(
                      '$customerName',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      // r.number.isNotEmpty ? r.number : 'Заявка ${r.id ?? ''}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.number.isNotEmpty ? order.number : 'Заявка ${order.id ?? ''}'}• $created',
                        ),
                        // Text('$customerName • $created'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: status.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.label,
                                style: TextStyle(
                                  color: status.color,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: !_showRemote
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              try {
                                // compute storage key used by local save
                                String key;
                                if (order.id != null) {
                                  key = order.id.toString();
                                } else if (order.docGuid != null &&
                                    order.docGuid!.isNotEmpty) {
                                  key = order.docGuid!;
                                } else if (order.number.isNotEmpty) {
                                  key = order.number;
                                } else {
                                  // try embedded local_id inside json payload
                                  key = order.id?.toString() ?? '';
                                }
                                if (key.isEmpty) {
                                  throw Exception('Порожній id для видалення');
                                }
                                await _local.delete(key);
                                await _load();
                              } catch (e) {
                                // ignore: avoid_print
                                print('Не вдалося видалити локально: $e');
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Помилка видалення: $e'),
                                  ),
                                );
                              }
                            },
                          )
                        : null,
                    onTap: () async {
                      KontragentModel? customer;
                      if (order.customerGuid.isNotEmpty) {
                        customer = await _kontrLocal.getKontragentByGuid(
                          order.customerGuid,
                        );
                      }
                      if (!mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RepairRequestPage(
                            initial: order.toEntity(),
                            initialCustomer: customer,
                            prefetchedNomenclature: _prefetchedNomenclature,
                          ),
                        ),
                      );
                      await _load();
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RepairRequestPage(
                prefetchedNomenclature: _prefetchedNomenclature,
              ),
            ),
          );
          // await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Нова заявка'),
      ),
    );
  }
}
