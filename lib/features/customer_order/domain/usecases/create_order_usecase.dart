import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/order_creation_service.dart';
import '../entities/customer_order_entity.dart';
import '../../../../common/shared_preferiences/sp_func.dart';

/// Use case for creating a new customer order
class CreateOrderUseCase
    implements UseCase<CustomerOrderEntity, CustomerOrderEntity> {
  final OrderCreationService orderCreationService;

  CreateOrderUseCase(this.orderCreationService);

  @override
  Future<Either<Failure, CustomerOrderEntity>> call(
    CustomerOrderEntity order,
  ) async {
    try {
      final List<Map<String, dynamic>> resultList = [];
      final priceType = await getPriceType();
      // Convert order items to goods list format
      // final goodsList = order.items
      //     .map(
      //       (item) => {
      //         'Номенклатура_Key': item.nomenclature.guid,
      //         'Количество': item.quantity,
      //         'Цена': item.unitPrice,
      //         'Сумма': item.totalPrice,
      //         'ЕдиницаИзмерения_Key': item.nomenclature.unitGuid,
      //         'СтавкаНДС_Key': '', // Add VAT rate if needed
      //         'СуммаНДС': 0.0, // Calculate VAT if needed
      //         'СуммаВсего': item.totalPrice,
      //       },
      // )
      // .toList();
      int lineNumper = 1;
      for (var nom in order.items) {
        resultList.add({
          "LineNumber": "$lineNumper",
          "Номенклатура_Key": nom.nomenclature.guid,
          "Склад_Key": await getStorage(),
          // "Упаковка_Key": nom.packId,
          "КоличествоУпаковок": nom.quantity,
          "Количество": nom.quantity,
          "Цена": nom.unitPrice,
          "СтавкаНДС": "НДС20",
          "ВидЦены_Key": priceType,
          "ВариантОбеспечения": "Отгрузить",
        });
        lineNumper++;
      }

      await orderCreationService.createOrder(order.customer.guid, resultList);

      // Return the created order
      return Right(order);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
