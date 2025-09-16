import 'package:flutter/material.dart';

enum SearchParam { name, barcode, article }

class SearchModeSwitch extends StatelessWidget {
  final SearchParam value;
  final ValueChanged<SearchParam> onChanged;
  final EdgeInsetsGeometry padding;

  const SearchModeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final items = [
      (SearchParam.name, Icons.text_fields, 'Назва'),
      (SearchParam.barcode, Icons.qr_code, 'Штрихкод'),
      (SearchParam.article, Icons.tag, 'Артикул'),
    ];

    int selectedIndex = items.indexWhere((e) => e.$1 == value);

    return Padding(
      padding: padding,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: scheme.surface, // фон білий/світлий
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Stack(
          children: [
            // Перемикач
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: _alignmentForIndex(selectedIndex, items.length),
              child: FractionallySizedBox(
                widthFactor: 1 / items.length,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final (param, icon, label) in items)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onChanged(param),
                      child: Center(
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: value == param
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Обчислює положення перемикача
  Alignment _alignmentForIndex(int index, int length) {
    if (length == 1) return Alignment.center;
    final step = 2 / (length - 1); // від -1 до 1
    return Alignment(-1 + step * index, 0);
  }
}
