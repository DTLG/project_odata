import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/customer_order_cubit.dart';
import '../../../kontragenty/domain/entities/kontragent_entity.dart';

/// Tab for customer selection
class CustomerSelectionTab extends StatefulWidget {
  final Function(KontragentEntity) onCustomerSelected;

  const CustomerSelectionTab({super.key, required this.onCustomerSelected});

  @override
  State<CustomerSelectionTab> createState() => _CustomerSelectionTabState();
}

class _CustomerSelectionTabState extends State<CustomerSelectionTab> {
  final TextEditingController _searchController = TextEditingController();
  KontragentEntity? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    // Data will be loaded automatically by the main page initialization
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Пошук клієнта',
              hintText: 'Введіть назву клієнта',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<CustomerOrderCubit>()
                            .loadAvailableCustomers();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              context.read<CustomerOrderCubit>().searchCustomers(value);
            },
          ),
        ),

        // Selected customer info
        if (_selectedCustomer != null)
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Обраний клієнт:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedCustomer!.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_selectedCustomer!.edrpou.isNotEmpty)
                  Text('ЄДРПОУ: ${_selectedCustomer!.edrpou}'),
                if (_selectedCustomer!.description.isNotEmpty)
                  Text('Опис: ${_selectedCustomer!.description}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onCustomerSelected(_selectedCustomer!);
                  },
                  child: const Text('Обрати клієнта'),
                ),
              ],
            ),
          ),

        // Customers list
        Expanded(
          child: BlocBuilder<CustomerOrderCubit, CustomerOrderState>(
            builder: (context, state) {
              if (state is CustomerOrderLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CustomerOrderError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<CustomerOrderCubit>().initialize();
                        },
                        child: const Text('Спробувати знову'),
                      ),
                    ],
                  ),
                );
              }

              List<KontragentEntity> customers = [];
              if (state is CustomersLoaded) {
                customers = state.customers;
              } else if (state is CustomerOrderInitialized) {
                customers = state.customers;
              } else if (state is CustomerOrderWithNomenclatureLoaded) {
                customers = state.customers;
              }

              if (customers.isNotEmpty) {
                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final isSelected = _selectedCustomer?.guid == customer.guid;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                        title: Text(customer.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer.edrpou.isNotEmpty)
                              Text('ЄДРПОУ: ${customer.edrpou}'),
                            if (customer.description.isNotEmpty)
                              Text(
                                customer.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const Icon(Icons.radio_button_unchecked),
                        onTap: () {
                          setState(() {
                            _selectedCustomer = customer;
                          });
                        },
                      ),
                    );
                  },
                );
              }

              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 64),
                    SizedBox(height: 16),
                    Text('Клієнти не знайдені'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
