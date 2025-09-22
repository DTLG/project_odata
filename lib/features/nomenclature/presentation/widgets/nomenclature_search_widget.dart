import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/nomenclature_cubit.dart';

enum SearchMode { name, article, barcode }

/// Віджет для пошуку номенклатури
class NomenclatureSearchWidget extends StatefulWidget {
  const NomenclatureSearchWidget({super.key});

  @override
  State<NomenclatureSearchWidget> createState() =>
      _NomenclatureSearchWidgetState();
}

class _NomenclatureSearchWidgetState extends State<NomenclatureSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  // Лише один активний режим
  SearchMode _mode = SearchMode.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String value) {
    if (value.isEmpty) {
      context.read<NomenclatureCubit>().clearSearch();
    } else {
      final q = value.trim();
      switch (_mode) {
        case SearchMode.barcode:
          context.read<NomenclatureCubit>().searchNomenclatureByBarcode(q);
          break;
        case SearchMode.name:
          context.read<NomenclatureCubit>().searchNomenclatureByName(q);
          break;
        case SearchMode.article:
          context.read<NomenclatureCubit>().searchNomenclatureByArticle(q);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Перемикач типу пошуку
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _mode == SearchMode.name,
                      onChanged: (checked) {
                        if (checked == true) {
                          setState(() {
                            _mode = SearchMode.name;
                            _searchController.clear();
                            context.read<NomenclatureCubit>().clearSearch();
                          });
                        }
                      },
                    ),
                    const Text('За назвою'),
                  ],
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _mode == SearchMode.article,
                      onChanged: (checked) {
                        if (checked == true) {
                          setState(() {
                            _mode = SearchMode.article;
                            _searchController.clear();
                            context.read<NomenclatureCubit>().clearSearch();
                          });
                        }
                      },
                    ),
                    const Text('За артикулом'),
                  ],
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _mode == SearchMode.barcode,
                      onChanged: (checked) {
                        if (checked == true) {
                          setState(() {
                            _mode = SearchMode.barcode;
                            _searchController.clear();
                            context.read<NomenclatureCubit>().clearSearch();
                          });
                        }
                      },
                    ),
                    const Text('За штрихкодом'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Поле пошуку
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _mode == SearchMode.barcode
                  ? 'Пошук за штрихкодом...'
                  : _mode == SearchMode.name
                  ? 'Пошук за назвою...'
                  : 'Пошук за артикулом...',
              prefixIcon: Icon(
                _mode == SearchMode.barcode
                    ? Icons.qr_code
                    : _mode == SearchMode.name
                    ? Icons.search
                    : Icons.tag,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_mode !=
                      SearchMode.name) // Кнопка "Знайти" для артикула/штрихкоду
                    IconButton(
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                      icon: const Icon(Icons.search),
                      tooltip: 'Знайти',
                    ),
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      context.read<NomenclatureCubit>().clearSearch();
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'Очистити',
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: _mode == SearchMode.name ? _performSearch : null,
            onSubmitted: _mode == SearchMode.name ? null : _performSearch,
          ),
        ],
      ),
    );
  }
}
