import 'package:flutter/material.dart';
// import removed: Bloc not used here
import '../../../../core/injection/injection_container.dart';
import '../../domain/entities/customer_order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import 'customer_order_page.dart';
import '../../../kontragenty/data/datasources/kontragent_local_data_source.dart';
import '../../../kontragenty/data/models/kontragent_model.dart';

class CustomerOrdersListPage extends StatefulWidget {
  const CustomerOrdersListPage({super.key});

  @override
  State<CustomerOrdersListPage> createState() => _CustomerOrdersListPageState();
}

class _CustomerOrdersListPageState extends State<CustomerOrdersListPage> {
  late final OrdersRepository _repo;
  late final KontragentLocalDataSource _kontrLocal;
  List<CustomerOrderEntity> _orders = const [];
  final Map<String, String> _customerNameByGuid = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = sl<OrdersRepository>();
    _kontrLocal = sl<KontragentLocalDataSource>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.getLocalOrders();
    // Resolve customer names from local storage
    final uniqueGuids = list
        .map((o) => o.customerGuid)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    if (uniqueGuids.isNotEmpty) {
      for (final guid in uniqueGuids) {
        final model = await _kontrLocal.getKontragentByGuid(guid);
        if (model != null) {
          _customerNameByGuid[guid] = model.name;
        }
      }
    }
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мої замовлення')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text('Немає збережених замовлень'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final o = _orders[index];
                  final customerName =
                      _customerNameByGuid[o.customerGuid] ?? o.customerGuid;
                  final isSent = o.isSent;
                  return ListTile(
                    title: Text(o.number),
                    subtitle: Text(
                      '$customerName • ${o.createdAt.toLocal()} • ${o.items.length} поз.',
                    ),
                    leading: isSent
                        ? const Icon(Icons.cloud_done, color: Colors.green)
                        : const Icon(Icons.cloud_off, color: Colors.grey),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await _repo.deleteLocalOrder(o.id);
                        await _load();
                      },
                    ),
                    onTap: () async {
                      final selected = o;
                      KontragentModel? customer;
                      if (selected.customerGuid.isNotEmpty) {
                        customer = await _kontrLocal.getKontragentByGuid(
                          selected.customerGuid,
                        );
                      }
                      if (!mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerOrderPage(
                            initialOrder: selected,
                            initialCustomer: customer,
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
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CustomerOrderPage()));
          await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Нове замовлення'),
      ),
    );
  }
}
