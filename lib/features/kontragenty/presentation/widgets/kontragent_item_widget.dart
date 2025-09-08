import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/kontragent_entity.dart';

/// Widget for displaying a single kontragent item
class KontragentItemWidget extends StatelessWidget {
  final KontragentEntity kontragent;

  const KontragentItemWidget({super.key, required this.kontragent});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          kontragent.isFolder ? Icons.folder : Icons.business,
          color: kontragent.isFolder
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          kontragent.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: kontragent.edrpou.isNotEmpty
            ? Text(
                'ЄДРПОУ: ${kontragent.edrpou}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kontragent.description.isNotEmpty) ...[
                  _buildInfoRow(context, 'Опис:', kontragent.description),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow(
                  context,
                  'Тип:',
                  kontragent.isFolder ? 'Папка' : 'Контрагент',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(context, 'GUID:', kontragent.guid),
                const SizedBox(height: 8),
                if (kontragent.parentGuid.isNotEmpty) ...[
                  _buildInfoRow(
                    context,
                    'Батьківський GUID:',
                    kontragent.parentGuid,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow(
                  context,
                  'Дата створення:',
                  DateFormat('dd.MM.yyyy HH:mm').format(kontragent.createdAt),
                ),
              ],
            ),
          ),
        ],
      ),
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
