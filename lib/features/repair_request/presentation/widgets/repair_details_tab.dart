import 'package:flutter/material.dart';
// removed unused repair_config import
import '../../../../data/datasources/local/sqflite_nomenclature_datasource.dart';
import '../../../../core/injection/injection_container.dart';
// removed unused NomenclatureModel import
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/repair_request_cubit.dart';

class RepairDetailsTab extends StatefulWidget {
  final List<dynamic>? repairTypes; // List<RepairTypeModel>
  final bool readOnly;
  const RepairDetailsTab({super.key, this.repairTypes, this.readOnly = false});

  @override
  State<RepairDetailsTab> createState() => _RepairDetailsTabState();
}

class _RepairDetailsTabState extends State<RepairDetailsTab> {
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _statusController;
  final Map<String, String> _nomNames = {};

  Future<void> _preloadNomNames() async {
    try {
      final s = context.read<RepairRequestCubit>().state;
      final Set<String> guids = {};
      for (final it in s.zapchastyny) {
        try {
          guids.add((it['nom_guid'] ?? '').toString());
        } catch (_) {}
      }
      for (final it in s.roboty) {
        try {
          guids.add((it['nom_guid'] ?? '').toString());
        } catch (_) {}
      }
      if (s.nomenclatureGuid.isNotEmpty) {
        guids.add(s.nomenclatureGuid);
      }
      guids.removeWhere((g) => g.isEmpty);
      if (guids.isEmpty) return;
      final ds = sl<SqliteNomenclatureDatasource>();
      for (final g in guids) {
        final model = await ds.getNomenclatureByGuid(g);
        if (model != null) {
          _nomNames[g] = model.name;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    final s = context.read<RepairRequestCubit>().state;
    _descController = TextEditingController(text: s.description);
    _priceController = TextEditingController(
      text: s.price == 0.0 ? '' : s.price.toString(),
    );
    _statusController = TextEditingController(text: s.status);
    _descController.addListener(() {
      context.read<RepairRequestCubit>().setDescription(_descController.text);
    });
    _priceController.addListener(() {
      context.read<RepairRequestCubit>().setPriceFromText(
        _priceController.text,
      );
    });
    _statusController.addListener(() {
      context.read<RepairRequestCubit>().setStatus(_statusController.text);
    });
    // Preload nomenclature names once
    _preloadNomNames();
  }

  @override
  void dispose() {
    _descController.dispose();
    _priceController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<RepairRequestCubit, RepairRequestState>(
        buildWhen: (p, n) =>
            p.repairType != n.repairType ||
            p.description != n.description ||
            p.status != n.status ||
            p.price != n.price ||
            p.zapchastyny != n.zapchastyny ||
            p.diagnostyka != n.diagnostyka ||
            p.roboty != n.roboty,
        builder: (context, state) {
          return ListView(
            children: [
              // const SizedBox(height: 6),
              //
              Builder(
                builder: (context) {
                  final List<dynamic> raw = widget.repairTypes ?? const [];
                  final List<Map<String, String>> unique = [];
                  final Set<String> seen = {};
                  for (final e in raw) {
                    try {
                      final guid = (e.guid as String?)?.trim() ?? '';
                      final name = (e.name as String?)?.trim() ?? '';
                      if (guid.isEmpty) continue;
                      if (seen.contains(guid)) continue;
                      seen.add(guid);
                      unique.add({'guid': guid, 'name': name});
                    } catch (_) {
                      // skip invalid item
                    }
                  }

                  final bool hasExactSelected =
                      state.repairType.isNotEmpty &&
                      unique
                              .where((m) => m['guid'] == state.repairType)
                              .length ==
                          1;
                  final String? selectedValue = hasExactSelected
                      ? state.repairType
                      : null;

                  return DropdownButtonFormField<String>(
                    value: selectedValue,
                    decoration: const InputDecoration(
                      labelText: 'Тип ремонту',
                      border: OutlineInputBorder(),
                    ),
                    items: unique
                        .map(
                          (m) => DropdownMenuItem<String>(
                            value: m['guid']!,
                            child: Text(
                              m['name']!.isEmpty ? m['guid']! : m['name']!,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: widget.readOnly
                        ? null
                        : (v) {
                            if (v == null) return;
                            context.read<RepairRequestCubit>().setRepairType(v);
                          },
                  );
                },
              ),
              // const SizedBox(height: 12),
              // TextField(
              //   decoration: const InputDecoration(labelText: 'Статус'),
              //   controller: _statusController,
              // ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Опис несправності',
                ),
                maxLines: 4,
                enabled: !widget.readOnly,
              ),
              // const SizedBox(height: 12),
              // TextField(
              //   controller: _priceController,
              //   keyboardType: TextInputType.number,
              //   decoration: const InputDecoration(labelText: 'Ціна'),
              //   enabled: !widget.readOnly,
              // ),
              const SizedBox(height: 16),
              const Text(
                'Запчастини',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              _ZapchastynyList(items: state.zapchastyny, nomNames: _nomNames),
              const SizedBox(height: 16),
              const Text(
                'Діагностика',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              _DiagnostykaList(items: state.diagnostyka),
              const SizedBox(height: 16),
              const Text(
                'Роботи',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              _RobotyList(items: state.roboty, nomNames: _nomNames),
            ],
          );
        },
      ),
    );
  }
}

// removed unused _RepairTypeOption

class _ZapchastynyList extends StatelessWidget {
  final List<dynamic> items;
  final Map<String, String> nomNames;
  const _ZapchastynyList({required this.items, required this.nomNames});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('—');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = Map<String, dynamic>.from(items[i] as Map);
        final nom = (m['nom_guid'] ?? '').toString();
        final count = (m['count'] ?? '').toString();
        final price = (m['price'] ?? '').toString();
        final sum = (m['sum'] ?? '').toString();
        return ListTile(
          dense: true,
          title: Text(nomNames[nom] ?? nom),
          subtitle: Text('к-сть: $count • ціна: $price • сума: $sum'),
        );
      },
    );
  }
}

class _DiagnostykaList extends StatelessWidget {
  final List<dynamic> items;
  const _DiagnostykaList({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('—');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = Map<String, dynamic>.from(items[i] as Map);
        final description = (m['description'] ?? '').toString();
        final result = (m['result'] ?? '').toString();
        final recommendation = (m['recommendation'] ?? '').toString();
        return ListTile(
          dense: true,
          title: Text(description.isNotEmpty ? description : 'Без опису'),
          subtitle: Text('результат: $result • рекомендація: $recommendation'),
        );
      },
    );
  }
}

class _RobotyList extends StatelessWidget {
  final List<dynamic> items;
  final Map<String, String> nomNames;
  const _RobotyList({required this.items, required this.nomNames});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('—');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = Map<String, dynamic>.from(items[i] as Map);
        final nom = (m['nom_guid'] ?? '').toString();
        final count = (m['count'] ?? '').toString();
        final price = (m['price'] ?? '').toString();
        final sum = (m['sum'] ?? '').toString();
        return ListTile(
          dense: true,
          title: Text(nomNames[nom] ?? nom),
          subtitle: Text('к-сть: $count • ціна: $price • сума: $sum'),
        );
      },
    );
  }
}

// Removed per-item FutureBuilder to avoid reloads on each state change
