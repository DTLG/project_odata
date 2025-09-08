import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/inventory_cubit.dart';
import '../widgets/error_dialog.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/injection/injection_container.dart';

/// Page for displaying inventory documents
class InventoryDocumentsPage extends StatelessWidget {
  const InventoryDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<InventoryCubit>(),
      child: const _InventoryDocumentsView(),
    );
  }
}

class _InventoryDocumentsView extends StatelessWidget {
  const _InventoryDocumentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Інвентаризація'),
        actions: [
          BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              if (state is InventoryLoading) {
                return IconButton(
                  onPressed: () {
                    // context.read<InventoryCubit>().createDocument();
                  },
                  icon: const Icon(Icons.add),
                );
              }
              return IconButton(
                onPressed: () {
                  context.read<InventoryCubit>().createDocument();
                },
                icon: const Icon(Icons.add),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<InventoryCubit>().loadDocuments(),
        child: BlocConsumer<InventoryCubit, InventoryState>(
          listener: (context, state) {
            if (state is InventoryError) {
              ErrorDialog.show(
                context,
                message: state.message,
                onRetry: () {
                  context.read<InventoryCubit>().loadDocuments();
                },
              );
            }
          },
          builder: (context, state) {
            if (state is InventoryInitial || state is InventoryLoading) {
              if (state is InventoryInitial) {
                context.read<InventoryCubit>().loadDocuments();
              }
              return const Center(child: CircularProgressIndicator());
            }

            if (state is InventoryDocumentsLoaded) {
              return _buildDocumentsList(context, state.documents);
            }

            return const Center(child: Text('Немає даних для відображення'));
          },
        ),
      ),
    );
  }

  Widget _buildDocumentsList(BuildContext context, List<dynamic> documents) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return _buildDocumentRow(context, doc, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 6,
            child: Text('№', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 4,
            child: Text('Дата', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, dynamic doc, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        title: Text(doc.number),
        subtitle: Text(doc.date),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.inventoryData,
            arguments: {'document': doc},
          ).then((result) {
            if (result == true) {
              context.read<InventoryCubit>().loadDocuments();
            }
          });
        },
      ),
    );
  }
}
