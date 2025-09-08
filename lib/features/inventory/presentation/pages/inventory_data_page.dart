import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/inventory_cubit.dart';
import '../widgets/error_dialog.dart';
import '../../domain/entities/inventory_document.dart';
import '../../../../core/injection/injection_container.dart';
import '../../domain/entities/inventory_item.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

/// Page for displaying inventory data (items) for a specific document
class InventoryDataPage extends StatelessWidget {
  final InventoryDocument document;

  const InventoryDataPage({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<InventoryCubit>(),
      child: _InventoryDataView(document: document),
    );
  }
}

class _InventoryDataView extends StatelessWidget {
  final InventoryDocument document;

  const _InventoryDataView({required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(document.number),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                await context.read<InventoryCubit>().closeInventoryDocument(
                  document.id,
                );
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Завершити'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<InventoryCubit>().loadDocumentItems(document.id),
        child: BlocConsumer<InventoryCubit, InventoryState>(
          listener: (context, state) {
            if (state is InventoryError) {
              ErrorDialog.show(
                context,
                message: state.message,
                onRetry: () {
                  context.read<InventoryCubit>().loadDocumentItems(document.id);
                },
              );
            }
          },
          builder: (context, state) {
            if (state is InventoryInitial || state is InventoryLoading) {
              if (state is InventoryInitial) {
                context.read<InventoryCubit>().loadDocumentItems(document.id);
              }
              return const Center(child: CircularProgressIndicator());
            }

            if (state is InventoryItemsLoaded) {
              return _buildItemsList(context, state.items);
            }

            return const Center(child: Text('Немає даних для відображення'));
          },
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<InventoryItem> items) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BarcodeInput(documentId: document.id),
          const SizedBox(height: 8),
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final InventoryItem item = items[index];
                return _buildItemRow(context, item, index);
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
            flex: 1,
            child: Text('№', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 6,
            child: Text('Назва', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Артикул',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('Од.', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('К-ть', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, InventoryItem item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Text((index + 1).toString()),
        title: Text(item.name),
        subtitle: Text(item.article),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.unit),
            const SizedBox(width: 8),
            Text(item.count.toString()),
          ],
        ),
        onTap: () {
          _showManualCountDialog(context, item);
        },
      ),
    );
  }

  void _showManualCountDialog(BuildContext context, InventoryItem item) {
    final cubit = context.read<InventoryCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ManualCountDialog(
        item: item,
        onCountSubmitted: (count) {
          cubit.addOrUpdateInventoryItem(
            documentId: document.id,
            nomenclatureId: item.id,
            count: count,
          );
        },
      ),
    );
  }
}

class _BarcodeInput extends StatefulWidget {
  final String documentId;

  const _BarcodeInput({required this.documentId});

  @override
  State<_BarcodeInput> createState() => _BarcodeInputState();
}

class _BarcodeInputState extends State<_BarcodeInput> {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      onSubmitted: (value) {
        final barcode = value.trim();
        if (barcode.isEmpty) return;
        context.read<InventoryCubit>().scanBarcode(
          documentId: widget.documentId,
          barcode: barcode,
        );
        controller.clear();
        focusNode.requestFocus();
      },
      decoration: InputDecoration(
        hintText: 'Відскануйте штрихкод',
        hintMaxLines: 2,
        contentPadding: const EdgeInsets.fromLTRB(3, 14, 0, 14),
        hintStyle: const TextStyle(fontSize: 14),
        suffixIcon: IconButton(
          tooltip: 'Сканувати камерою',
          icon: const Icon(Icons.camera_alt_outlined),
          onPressed: () async {
            final result = await BarcodeScanner.scan();
            if (result.type == ResultType.Barcode &&
                result.rawContent.isNotEmpty) {
              final barcode = result.rawContent.trim();
              context.read<InventoryCubit>().scanBarcode(
                documentId: widget.documentId,
                barcode: barcode,
              );
            }
          },
        ),
      ),
    );
  }
}

class _ManualCountDialog extends StatefulWidget {
  final dynamic item;
  final Function(double) onCountSubmitted;

  const _ManualCountDialog({
    required this.item,
    required this.onCountSubmitted,
  });

  @override
  State<_ManualCountDialog> createState() => _ManualCountDialogState();
}

class _ManualCountDialogState extends State<_ManualCountDialog> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Введіть кількість'),
          const SizedBox(height: 16),
          SizedBox(
            width: 80,
            child: TextField(
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              controller: controller,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              final count = double.tryParse(controller.text) ?? 0.0;
              widget.onCountSubmitted(count);
              Navigator.pop(context);
            }
          },
          child: const Text('Додати'),
        ),
      ],
    );
  }
}
