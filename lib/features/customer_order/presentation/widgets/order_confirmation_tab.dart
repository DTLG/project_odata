import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/customer_order_cubit.dart';

/// Tab for order confirmation
class OrderConfirmationTab extends StatelessWidget {
  final VoidCallback onCreateOrder;
  final VoidCallback onSaveLocal;

  const OrderConfirmationTab({
    super.key,
    required this.onCreateOrder,
    required this.onSaveLocal,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerOrderCubit, CustomerOrderState>(
      builder: (context, state) {
        if (state is CustomerOrderLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Створення замовлення...'),
              ],
            ),
          );
        }

        CustomerOrderLoaded? orderState;

        if (state is CustomerOrderLoaded) {
          orderState = state;
        } else if (state is CustomerOrderWithNomenclatureLoaded) {
          final currentState = state;
          orderState = CustomerOrderLoaded(
            selectedCustomer: currentState.selectedCustomer,
            orderItems: currentState.orderItems,
            totalAmount: currentState.totalAmount,
          );
        } else {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64),
                SizedBox(height: 16),
                Text('Спочатку оберіть клієнта та додайте товари'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Клієнт',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (orderState.selectedCustomer != null) ...[
                        Text(
                          orderState.selectedCustomer!.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (orderState.selectedCustomer!.edrpou.isNotEmpty)
                          Text(
                            'ЄДРПОУ: ${orderState.selectedCustomer!.edrpou}',
                          ),
                        if (orderState.selectedCustomer!.description.isNotEmpty)
                          Text(
                            'Опис: ${orderState.selectedCustomer!.description}',
                          ),
                      ] else
                        Text(
                          'Клієнт не обраний',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Order items
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Товари (${orderState.orderItems.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (orderState.orderItems.isEmpty)
                        Text(
                          'Товари не додані',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      else
                        ...orderState.orderItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nomenclature.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      if (item.nomenclature.article.isNotEmpty)
                                        Text(
                                          'Артикул: ${item.nomenclature.article}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.quantity.toStringAsFixed(0)} × ${item.unitPrice.toStringAsFixed(2)} грн',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Text(
                                      '${item.totalPrice.toStringAsFixed(2)} грн',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Total amount (fixed height to match button)
              SizedBox(
                height: 56,
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Загальна сума:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        Text(
                          '${orderState.totalAmount.toStringAsFixed(2)} грн',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Actions row: send to server and save locally
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canCreateOrder(orderState)
                          ? onCreateOrder
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: state is CustomerOrderLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Створення...',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            )
                          : const Text(
                              'Надіслати',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _canCreateOrder(orderState)
                          ? onSaveLocal
                          : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: const Text(
                        'Зберегти',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Validation messages
              if (!_canCreateOrder(orderState))
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Для створення замовлення потрібно:',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (orderState.selectedCustomer == null)
                        Text(
                          '• Обрати клієнта',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      if (orderState.orderItems.isEmpty)
                        Text(
                          '• Додати товари до кошика',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _canCreateOrder(CustomerOrderLoaded state) {
    return state.selectedCustomer != null && state.orderItems.isNotEmpty;
  }
}
