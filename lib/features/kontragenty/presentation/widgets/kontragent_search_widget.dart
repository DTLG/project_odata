import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/kontragent_cubit.dart';

/// Widget for searching kontragenty
class KontragentSearchWidget extends StatefulWidget {
  const KontragentSearchWidget({super.key});

  @override
  State<KontragentSearchWidget> createState() => _KontragentSearchWidgetState();
}

class _KontragentSearchWidgetState extends State<KontragentSearchWidget> {
  final _searchController = TextEditingController();
  String _searchMode = 'name';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Пошук контрагентів...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _performSearch,
          ),
          const SizedBox(height: 8),
          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //   child: Row(
          //     children: [
          //       _buildSearchModeChip('name', 'За назвою'),
          //       const SizedBox(width: 8),
          //       _buildSearchModeChip('edrpou', 'За ЄДРПОУ'),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSearchModeChip(String mode, String label) {
    final isSelected = _searchMode == mode;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _searchMode = mode;
          });
          _performSearch(_searchController.text);
        }
      },
    );
  }

  void _performSearch(String query) {
    final cubit = context.read<KontragentCubit>();

    if (query.isEmpty) {
      cubit.loadRootFolders();
      return;
    }

    switch (_searchMode) {
      case 'name':
        cubit.searchByName(query);
        break;
      case 'edrpou':
        cubit.searchByEdrpou(query);
        break;
    }
  }
}
