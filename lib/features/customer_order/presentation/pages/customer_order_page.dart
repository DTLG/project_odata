import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_router.dart';
import '../cubit/customer_order_cubit.dart';
import '../widgets/customer_selection_tab.dart';
import '../widgets/cart_tab.dart';
import '../widgets/product_selection_tab.dart';
import '../widgets/order_confirmation_tab.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/customer_order_entity.dart';
import '../../../kontragenty/domain/entities/kontragent_entity.dart';
import '../../../nomenclature/ui/cubit/nomenclature_cubit.dart';
import '../../../kontragenty/presentation/cubit/kontragent_cubit.dart';

/// Main page for customer order with three tabs
class CustomerOrderPage extends StatelessWidget {
  final CustomerOrderEntity? initialOrder;
  final KontragentEntity? initialCustomer;
  final CustomerOrderCubit? cubit;
  const CustomerOrderPage({
    super.key,
    this.initialOrder,
    this.initialCustomer,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final provided = cubit;
    if (provided != null) {
      return BlocProvider.value(
        value: provided,
        child: _CustomerOrderView(
          initialOrder: initialOrder,
          initialCustomer: initialCustomer,
        ),
      );
    }
    return BlocProvider(
      create: (context) {
        final c = sl<CustomerOrderCubit>();
        // Future.microtask(() => c.initialize());
        return c;
      },
      child: _CustomerOrderView(
        initialOrder: initialOrder,
        initialCustomer: initialCustomer,
      ),
    );
  }
}

class _CustomerOrderView extends StatelessWidget {
  final CustomerOrderEntity? initialOrder;
  final KontragentEntity? initialCustomer;
  const _CustomerOrderView({this.initialOrder, this.initialCustomer});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Замовлення клієнта'),
          bottom: TabBar(
            indicatorColor: AppTheme.accentColor,
            unselectedLabelColor: Colors.white,
            labelColor: AppTheme.accentColor,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Клієнт'),
              Tab(icon: Icon(Icons.list_alt), text: 'Товари'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Кошик'),
              Tab(icon: Icon(Icons.check_circle), text: 'Підтвердження'),
            ],
          ),
        ),
        body: BlocConsumer<CustomerOrderCubit, CustomerOrderState>(
          listener: (context, state) {
            if (state is CustomerOrderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            } else if (state is OrderCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Замовлення ${state.order.number} створено успішно!',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              context.read<CustomerOrderCubit>().reset();
              context.read<CustomerOrderCubit>().initialize();
              DefaultTabController.of(context).animateTo(0);
            } else if (state is CustomerOrderInitialized &&
                initialOrder != null) {
              context.read<CustomerOrderCubit>().loadExistingOrder(
                initialOrder!,
                customer: initialCustomer,
              );
            }
          },
          builder: (context, state) {
            if (state is CustomerOrderLoading ||
                state is CustomerOrderInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CustomerOrderError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<CustomerOrderCubit>().initialize(),
                      child: const Text('Спробувати ще раз'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              children: [
                KeepAliveWrapper(
                  child: BlocProvider(
                    create: (_) => sl<KontragentCubit>()
                      ..loadLocalKontragenty()
                      ..loadRootFolders(),
                    child: CustomerSelectionTab(
                      // prefetched: _prefetchedCustomers,
                      onCustomerSelected: (customer) {
                        context.read<CustomerOrderCubit>().setSelectedCustomer(
                          customer,
                        );
                        DefaultTabController.of(context).animateTo(1);
                      },
                    ),
                  ),
                ),
                KeepAliveWrapper(
                  child: AbsorbPointer(
                    absorbing: false,
                    child: BlocProvider.value(
                      value: sl<NomenclatureCubit>(),
                      child: ProductSelectionTab(
                        onItemAdded: (item) {
                          context.read<CustomerOrderCubit>().addOrderItem(item);
                        },
                      ),
                    ),
                  ),
                ),
                KeepAliveWrapper(
                  child: CartTab(
                    onItemAdded: (item) {
                      context.read<CustomerOrderCubit>().addOrderItem(item);
                    },
                    onItemRemoved: (itemId) {
                      context.read<CustomerOrderCubit>().removeOrderItem(
                        itemId,
                      );
                    },
                    onQuantityChanged: (itemId, quantity) {
                      context.read<CustomerOrderCubit>().updateItemQuantity(
                        itemId,
                        quantity,
                      );
                    },
                  ),
                ),
                KeepAliveWrapper(
                  child: OrderConfirmationTab(
                    onCreateOrder: () async {
                      await context.read<CustomerOrderCubit>().createOrder();
                      AppRouter.goBack(context);
                    },
                    onSaveLocal: () async {
                      await context.read<CustomerOrderCubit>().saveLocalDraft();
                      AppRouter.goBack(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Замовлення збережено локально'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Keeps tab subtree alive to prevent rebuilds (avoids freezes on tab switches)
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
