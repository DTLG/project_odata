import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/nomenclature_entity.dart';
import '../../../../common/shared_preferiences/sp_func.dart';
import '../../../../common/printer/connect_printer.dart';

/// Віджет для відображення одного елементу номенклатури
class NomenclatureItemWidget extends StatelessWidget {
  final NomenclatureEntity nomenclature;

  const NomenclatureItemWidget({super.key, required this.nomenclature});

  Future<String> lableEAN13(
    String barcode,
    String article,
    String name,
    dynamic price,
  ) async {
    final darknees = await getPrinterDarkness();
    return '''
^XA
^PQ1
^PW399
^CI28
^MD$darknees


 ^FO220,25
 ^FB350,4,3
 ^A0, 14, 19,
 ^FD${DateFormat('dd.MM.yyyy').format(DateTime.now())}^FS

 ^FO10,40
 ^FB300,4,3
 ^A0, 15, 18,
 ^FD${name.replaceAll(RegExp('[\'"]'), '')}^FS

 ^FO10,130
 ^FB350,4,3
 ^A0, 20, 22,
 ^FDАрт: $article^FS


 ^FO25,160
^BY2^BEN,60,Y,N
^FD$barcode^FS

 ^FO180,130
 ^FB350,4,3
 ^A0, 20, 22,
q ^FD${price.toStringAsFixed(2)}грн.^FS


^XZ
''';
  }

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat.currency(
      locale: 'uk_UA',
      symbol: '₴',
      decimalDigits: 2,
    );

    final barcodes = nomenclature.barcodes;
    final prices = nomenclature.prices;
    final double displayPrice = prices.isNotEmpty
        ? prices.last.price
        : nomenclature.price;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        title: Text(
          nomenclature.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          nomenclature.isFolder ? '' : priceFormatter.format(displayPrice),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: nomenclature.isFolder
            ? null
            : IconButton(
                tooltip: 'Друк етикетки',
                icon: const Icon(Icons.print),
                onPressed: () async {
                  String barcodeToPrint = barcodes.isNotEmpty
                      ? barcodes.first.barcode
                      : nomenclature.article;
                  if (barcodes.length > 1) {
                    final selected = await _selectBarcode(
                      context,
                      barcodes.map((e) => e.barcode).toList(),
                      barcodeToPrint,
                    );
                    if (selected != null) {
                      barcodeToPrint = selected;
                    }
                  }
                  final String article = nomenclature.article;
                  final String name = nomenclature.name;
                  final double price = displayPrice;
                  final zpl = await lableEAN13(
                    barcodeToPrint,
                    article,
                    name,
                    price,
                  );
                  PrinterConnect().connectToPrinter(zpl);
                },
              ),
        children: nomenclature.isFolder
            ? []
            : [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(context, 'Артикул:', nomenclature.article),
                      // const SizedBox(height: 8),
                      // _buildInfoRow(context, 'GUID:', nomenclature.guid),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        'Одиниця виміру:',
                        nomenclature.unitName,
                      ),
                      // const SizedBox(height: 8),
                      // _buildInfoRow(context, 'GUID одиниці:', nomenclature.unitGuid),
                      const SizedBox(height: 8),
                      if (barcodes.isNotEmpty)
                        _buildInfoRow(
                          context,
                          'ШК:',
                          barcodes.map((e) => e.barcode).join(', '),
                        ),
                      if (barcodes.isNotEmpty) const SizedBox(height: 8),
                      if (prices.isNotEmpty)
                        _buildInfoRow(
                          context,
                          'Ціни (всього ${prices.length}):',
                          prices
                              .map((p) => priceFormatter.format(p.price))
                              .join(', '),
                        ),
                      if (prices.isNotEmpty) const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        'Дата створення:',
                        DateFormat(
                          'dd.MM.yyyy HH:mm',
                        ).format(nomenclature.createdAt),
                      ),
                      const SizedBox(height: 8),
                      // _buildInfoRow(context, 'ID:', nomenclature.id),
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  Future<String?> _selectBarcode(
    BuildContext context,
    List<String> barcodes,
    String current,
  ) async {
    String? selected = current;
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Оберіть штрихкод'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: barcodes
                      .map(
                        (b) => RadioListTile<String>(
                          title: Text(b),
                          value: b,
                          groupValue: selected,
                          onChanged: (val) => setState(() => selected = val),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Скасувати'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: const Text('Друкувати'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
