import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/domain/models/property.dart';

class SelectedPropertyItem {
  final Property property;
  int qty;

  SelectedPropertyItem({
    required this.property,
    this.qty = 1,
  });
}

/// Bottom Sheet untuk memilih banyak properti & alat kerja sekaligus (Multi-Select)
class MultiSelectPropertySheet extends StatefulWidget {
  const MultiSelectPropertySheet({
    super.key,
    required this.allProperties,
    this.initiallySelectedPropertyIds = const {},
    this.initialQuantities = const {},
  });

  final List<Property> allProperties;
  final Set<String> initiallySelectedPropertyIds;
  final Map<String, int> initialQuantities;

  static Future<List<SelectedPropertyItem>?> show(
    BuildContext context, {
    required List<Property> allProperties,
    Set<String> initiallySelectedPropertyIds = const {},
    Map<String, int> initialQuantities = const {},
  }) {
    return showModalBottomSheet<List<SelectedPropertyItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiSelectPropertySheet(
        allProperties: allProperties,
        initiallySelectedPropertyIds: initiallySelectedPropertyIds,
        initialQuantities: initialQuantities,
      ),
    );
  }

  @override
  State<MultiSelectPropertySheet> createState() => _MultiSelectPropertySheetState();
}

class _MultiSelectPropertySheetState extends State<MultiSelectPropertySheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'property', 'tool'

  // Map property ID -> SelectedPropertyItem
  late Map<String, SelectedPropertyItem> _selectedMap;

  @override
  void initState() {
    super.initState();
    _selectedMap = {};
    for (final p in widget.allProperties) {
      if (widget.initiallySelectedPropertyIds.contains(p.id)) {
        final qty = widget.initialQuantities[p.id] ?? 1;
        _selectedMap[p.id] = SelectedPropertyItem(property: p, qty: qty > 0 ? qty : 1);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(Property p) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedMap.containsKey(p.id)) {
        _selectedMap.remove(p.id);
      } else {
        _selectedMap[p.id] = SelectedPropertyItem(property: p, qty: 1);
      }
    });
  }

  void _updateQty(Property p, int newQty) {
    if (newQty < 1) return;
    setState(() {
      if (_selectedMap.containsKey(p.id)) {
        _selectedMap[p.id]!.qty = newQty;
      } else {
        _selectedMap[p.id] = SelectedPropertyItem(property: p, qty: newQty);
      }
    });
  }

  void _selectAllFiltered(List<Property> filtered) {
    setState(() {
      for (final p in filtered) {
        if (!_selectedMap.containsKey(p.id)) {
          _selectedMap[p.id] = SelectedPropertyItem(property: p, qty: 1);
        }
      }
    });
  }

  void _deselectAllFiltered(List<Property> filtered) {
    setState(() {
      for (final p in filtered) {
        _selectedMap.remove(p.id);
      }
    });
  }

  Widget _buildFilterChip({required String value, required String label}) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: isSelected ? AppColors.primaryGold : AppColors.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.goldLight,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allProperties.where((p) {
      if (_selectedFilter == 'property' && !p.isProperty) return false;
      if (_selectedFilter == 'tool' && !p.isTool) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(query);
        final matchCategory = p.category.toLowerCase().contains(query);
        return matchName || matchCategory;
      }
      return true;
    }).toList();

    final selectedCount = _selectedMap.length;
    final isAllFilteredSelected = filtered.isNotEmpty && filtered.every((p) => _selectedMap.containsKey(p.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pilih Barang Sekaligus', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Centang cepat semua barang & alat yang dibawa', style: AppTypography.caption),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari barang, rangka, lampu, atau alat...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textLight),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Filter Chips & Quick Select All
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(value: 'all', label: 'Semua (${widget.allProperties.length})'),
                            const SizedBox(width: 6),
                            _buildFilterChip(value: 'property', label: '📦 Properti'),
                            const SizedBox(width: 6),
                            _buildFilterChip(value: 'tool', label: '🛠️ Alat'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (isAllFilteredSelected) {
                          _deselectAllFiltered(filtered);
                        } else {
                          _selectAllFiltered(filtered);
                        }
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        isAllFilteredSelected ? 'Batal Semua' : 'Pilih Semua',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List Items
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada barang yang cocok dengan pencarian.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = _selectedMap.containsKey(item.id);
                      final selectedItem = _selectedMap[item.id];
                      final qty = selectedItem?.qty ?? 1;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.goldLight.withValues(alpha: 0.4) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGold : AppColors.borderLight,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              activeColor: AppColors.primaryGold,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (_) => _toggleSelection(item),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: item.isTool ? Colors.blue.shade50 : AppColors.goldLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(item.isTool ? '🛠️' : '📦', style: AppTypography.bodyMedium),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => _toggleSelection(item),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.category,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.caption.copyWith(color: AppColors.textLight, fontSize: 11),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('•', style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Stok: ${item.totalStock} ${item.unit}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.caption.copyWith(color: AppColors.textLight, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => _updateQty(item, qty - 1),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.remove, size: 14, color: AppColors.primaryGold),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '$qty',
                                        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _updateQty(item, qty + 1),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.add, size: 14, color: AppColors.primaryGold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$selectedCount Barang Dipilih',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        selectedCount > 0 ? 'Siap dimasukkan ke daftar bawaan' : 'Centang barang di atas',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final selectedList = _selectedMap.values.toList();
                    Navigator.pop(context, selectedList);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    selectedCount > 0 ? 'Terapkan ($selectedCount Barang)' : 'Selesai',
                    style: AppTypography.button,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
