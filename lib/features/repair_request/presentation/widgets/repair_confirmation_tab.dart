import 'package:flutter/material.dart';
import '../../../nomenclature/data/datasources/local/nomenclature_local_datasource.dart';
import '../../../../core/injection/injection_container.dart';

class RepairConfirmationTab extends StatelessWidget {
  final bool readOnly;
  final VoidCallback onSaveLocal;
  final VoidCallback onSend;
  final dynamic customer; // KontragentModel? without import here
  final String nomenclatureGuid; // used only to resolve human name
  final String repairTypeName; // human readable name
  final String status;
  final TextEditingController descController;
  final TextEditingController priceController;
  const RepairConfirmationTab({
    super.key,
    this.readOnly = false,
    required this.onSaveLocal,
    required this.onSend,
    required this.customer,
    required this.nomenclatureGuid,
    required this.repairTypeName,
    required this.status,
    required this.descController,
    required this.priceController,
  });

  @override
  Widget build(BuildContext context) {
    // Using only valueStyle per tile; section headers are embedded in tiles
    final TextStyle valueStyle = Theme.of(
      context,
    ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600);

    // Keep for potential future UI extension (currently unused)

    final bool hasCustomer = customer != null;
    final bool hasProduct = nomenclatureGuid.trim().isNotEmpty;
    final bool hasRepairType = repairTypeName.trim().isNotEmpty;
    final bool canProceed = hasCustomer && hasProduct && hasRepairType;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final bool twoCols = constraints.maxWidth >= 640;
                final tiles = [
                  _SummaryTile(
                    icon: Icons.person,
                    title: 'Клієнт',
                    child: Text(customer?.name ?? '-', style: valueStyle),
                  ),
                  _SummaryTile(
                    icon: Icons.build,
                    title: 'Товар',
                    child: _NomenclatureNameLine(
                      guid: nomenclatureGuid,
                      valueStyle: valueStyle,
                    ),
                  ),
                  _SummaryTile(
                    icon: Icons.handyman,
                    title: 'Тип ремонту',
                    child: Text(
                      repairTypeName.isNotEmpty ? repairTypeName : '-',
                      style: valueStyle,
                    ),
                  ),
                  _SummaryTile(
                    icon: Icons.flag,
                    title: 'Статус',
                    child: Text(
                      status.isNotEmpty ? status : '-',
                      style: valueStyle,
                    ),
                  ),
                  // _SummaryTile(
                  //   icon: Icons.description,
                  //   title: 'Опис',
                  //   child: Text(
                  //     descController.text.isNotEmpty
                  //         ? descController.text
                  //         : '-',
                  //     style: valueStyle,
                  //   ),
                  // ),
                  // _SummaryTile(
                  //   icon: Icons.attach_money,
                  //   title: 'Ціна',
                  //   child: Text(priceText, style: valueStyle),
                  // ),
                ];

                if (twoCols) {
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: tiles,
                  );
                }

                return Column(
                  children: [
                    for (final t in tiles) ...[t, const SizedBox(height: 12)],
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            if (!readOnly) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canProceed ? onSaveLocal : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_alt),
                          SizedBox(width: 8),
                          Text('Зберегти', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canProceed ? onSend : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload),
                          SizedBox(width: 8),
                          Text('Надіслати', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NomenclatureNameLine extends StatelessWidget {
  final String guid;
  final TextStyle valueStyle;
  const _NomenclatureNameLine({required this.guid, required this.valueStyle});

  @override
  Widget build(BuildContext context) {
    if (guid.isEmpty) return Text('-', style: valueStyle);
    final ds = sl<NomenclatureLocalDatasource>();
    return FutureBuilder(
      future: ds.getNomenclatureByGuid(guid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 16,
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        final name = snapshot.data?.name ?? '-';
        return Text(name, style: valueStyle);
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
