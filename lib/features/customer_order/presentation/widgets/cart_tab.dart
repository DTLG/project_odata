import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/customer_order_cubit.dart';
import '../../domain/entities/customer_order_entity.dart';

/// Tab for cart management
class CartTab extends StatefulWidget {
  final Function(OrderItemEntity) onItemAdded;
  final Function(String) onItemRemoved;
  final Function(String, double) onQuantityChanged;

  const CartTab({
    super.key,
    required this.onItemAdded,
    required this.onItemRemoved,
    required this.onQuantityChanged,
  });

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cart items only
        Expanded(
          child: BlocBuilder<CustomerOrderCubit, CustomerOrderState>(
            builder: (context, state) {
              if (state is CustomerOrderLoaded ||
                  state is CustomerOrderWithNomenclatureLoaded) {
                CustomerOrderLoaded orderState;
                if (state is CustomerOrderLoaded) {
                  orderState = state;
                } else {
                  final currentState =
                      state as CustomerOrderWithNomenclatureLoaded;
                  orderState = CustomerOrderLoaded(
                    selectedCustomer: currentState.selectedCustomer,
                    orderItems: currentState.orderItems,
                    totalAmount: currentState.totalAmount,
                  );
                }
                return Column(
                  children: [
                    // Cart summary
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Товарів: ${orderState.orderItems.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Сума: ${orderState.totalAmount.toStringAsFixed(2)} грн',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // Cart items list
                    Expanded(
                      child: orderState.orderItems.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 64),
                                  SizedBox(height: 16),
                                  Text('Кошик порожній'),
                                  Text('Додайте товари зі списку нижче'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: orderState.orderItems.length,
                              itemBuilder: (context, index) {
                                final item = orderState.orderItems[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  child: ListTile(
                                    title: Text(item.nomenclature.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (item
                                            .nomenclature
                                            .article
                                            .isNotEmpty)
                                          Text(
                                            'Артикул: ${item.nomenclature.article}',
                                          ),
                                        Text(
                                          'Ціна: ${item.unitPrice.toStringAsFixed(2)} грн',
                                        ),
                                        Text(
                                          'Сума: ${item.totalPrice.toStringAsFixed(2)} грн',
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Quantity controls
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            if (item.quantity > 1) {
                                              widget.onQuantityChanged(
                                                item.id,
                                                item.quantity - 1,
                                              );
                                            }
                                          },
                                        ),
                                        Text(
                                          item.quantity.toStringAsFixed(0),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            widget.onQuantityChanged(
                                              item.id,
                                              item.quantity + 1,
                                            );
                                          },
                                        ),
                                        // Remove button
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            widget.onItemRemoved(item.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              }

              return const Center(child: Text('Завантаження...'));
            },
          ),
        ),
      ],
    );
  }
}
