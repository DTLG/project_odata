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

/// Main page for customer order with three tabs
class CustomerOrderPage extends StatelessWidget {
  final CustomerOrderEntity? initialOrder;
  final KontragentEntity? initialCustomer;
  const CustomerOrderPage({super.key, this.initialOrder, this.initialCustomer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CustomerOrderCubit>(),
      child: _CustomerOrderView(
        initialOrder: initialOrder,
        initialCustomer: initialCustomer,
      ),
    );
  }
}

class _CustomerOrderView extends StatefulWidget {
  final CustomerOrderEntity? initialOrder;
  final KontragentEntity? initialCustomer;
  const _CustomerOrderView({this.initialOrder, this.initialCustomer});

  @override
  State<_CustomerOrderView> createState() => _CustomerOrderViewState();
}

class _CustomerOrderViewState extends State<_CustomerOrderView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Initialize the cubit to load all data once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<CustomerOrderCubit>();
      cubit.initialize().then((_) {
        if (widget.initialOrder != null) {
          cubit.loadExistingOrder(
            widget.initialOrder!,
            customer: widget.initialCustomer,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Замовлення клієнта'),
        bottom: TabBar(
          indicatorColor: AppTheme.accentColor,
          unselectedLabelColor: Colors.white,
          labelColor: AppTheme.accentColor,
          controller: _tabController,
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
            // Reset to initial state and reinitialize
            context.read<CustomerOrderCubit>().reset();
            context.read<CustomerOrderCubit>().initialize();
            _tabController.animateTo(0);
          }
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              CustomerSelectionTab(
                onCustomerSelected: (customer) {
                  context.read<CustomerOrderCubit>().setSelectedCustomer(
                    customer,
                  );
                  _tabController.animateTo(1);
                },
              ),
              ProductSelectionTab(
                onItemAdded: (item) {
                  context.read<CustomerOrderCubit>().addOrderItem(item);
                },
              ),
              CartTab(
                onItemAdded: (item) {
                  context.read<CustomerOrderCubit>().addOrderItem(item);
                },
                onItemRemoved: (itemId) {
                  context.read<CustomerOrderCubit>().removeOrderItem(itemId);
                },
                onQuantityChanged: (itemId, quantity) {
                  context.read<CustomerOrderCubit>().updateItemQuantity(
                    itemId,
                    quantity,
                  );
                },
              ),
              OrderConfirmationTab(
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
            ],
          );
        },
      ),
    );
  }
}
