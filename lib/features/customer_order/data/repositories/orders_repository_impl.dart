import '../../domain/entities/customer_order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../../kontragenty/data/datasources/kontragent_local_data_source.dart';
import '../datasources/local/orders_local_data_source.dart';
import '../../data/models/customer_order_model.dart';
import '../../../../data/datasources/local/nomenclature_local_datasource.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersLocalDataSource local;
  final NomenclatureLocalDatasource nomenLocal;
  final KontragentLocalDataSource kontrLocal;
  OrdersRepositoryImpl(this.local, this.nomenLocal, this.kontrLocal);

  @override
  Future<void> saveLocalOrder(CustomerOrderEntity order) async {
    await local.saveOrder(CustomerOrderModel.fromEntity(order));
  }

  @override
  Future<List<CustomerOrderEntity>> getLocalOrders() async {
    final models = await local.getOrders();
    // Hydrate items' nomenclature and optionally customer name (if needed elsewhere)
    for (final m in models) {
      for (int i = 0; i < m.items.length; i++) {
        final it = m.items[i];
        final guid = it.nomenclature.guid;
        if (guid.isNotEmpty) {
          final nom = await nomenLocal.getNomenclatureByGuid(guid);
          if (nom != null) {
            m.items[i] = OrderItemModel.fromEntity(
              OrderItemEntity(
                id: it.id,
                nomenclature: nom.toEntity(),
                quantity: it.quantity,
                unitPrice: it.unitPrice,
                totalPrice: it.totalPrice,
                notes: it.notes,
              ),
            );
          }
        }
      }
    }
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> deleteLocalOrder(String id) => local.deleteOrder(id);

  @override
  Future<void> clearLocalOrders() => local.clear();
}
