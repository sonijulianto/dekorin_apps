import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/domain/models/decoration_addon.dart';

/// Model pembungkus untuk item tambahan beserta jumlah (kuantitas) yang dipesan.
class SelectedAddonItem {
  SelectedAddonItem({
    required this.addon,
    this.quantity = 1,
  });

  final DecorationAddon addon;
  int quantity;

  double get totalPrice => addon.price * quantity;
}

/// Screen untuk memilih item tambahan (addon) dengan kuantitas (qty) dan fitur pencarian.
/// Mengembalikan `List<SelectedAddonItem>` ke caller via [Navigator.pop].
class AddonPickerScreen extends ConsumerStatefulWidget {
  const AddonPickerScreen({
    super.key,
    required this.initiallySelectedAddons,
  });

  final List<SelectedAddonItem> initiallySelectedAddons;

  @override
  ConsumerState<AddonPickerScreen> createState() => _AddonPickerScreenState();
}

class _AddonPickerScreenState extends ConsumerState<AddonPickerScreen> {
  // Map menyimpan key: addon.id -> SelectedAddonItem
  late final Map<String, SelectedAddonItem> _selectedMap;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedMap = {
      for (final item in widget.initiallySelectedAddons)
        item.addon.id: SelectedAddonItem(
          addon: item.addon,
          quantity: item.quantity,
        ),
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _incrementQty(DecorationAddon addon) {
    setState(() {
      if (_selectedMap.containsKey(addon.id)) {
        _selectedMap[addon.id]!.quantity += 1;
      } else {
        _selectedMap[addon.id] = SelectedAddonItem(addon: addon, quantity: 1);
      }
    });
  }

  void _decrementQty(DecorationAddon addon) {
    setState(() {
      if (_selectedMap.containsKey(addon.id)) {
        if (_selectedMap[addon.id]!.quantity > 1) {
          _selectedMap[addon.id]!.quantity -= 1;
        } else {
          _selectedMap.remove(addon.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final addonsAsync = ref.watch(addonsProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final totalSelectedPrice = _selectedMap.values.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    final totalItemsCount = _selectedMap.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pilih Item Tambahan (Addon)',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── Search Field Bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama item addon...',
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textLight),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppTheme.textLight),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppTheme.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Grid & Content Area ──
          Expanded(
            child: addonsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGold),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat item addon: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textLight),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(addonsProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
              data: (addons) {
                if (addons.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.extension_off_outlined, size: 56, color: AppTheme.primaryGold),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum Ada Item Tambahan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Anda belum menambahkan item tambahan di menu Kelola Addon (Profile).',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Filter berdasarkan query pencarian
                final filteredAddons = _searchQuery.isEmpty
                    ? addons
                    : addons.where((item) {
                        return item.name.toLowerCase().contains(_searchQuery) ||
                            item.description.toLowerCase().contains(_searchQuery);
                      }).toList();

                if (filteredAddons.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 56, color: AppTheme.textLight),
                          const SizedBox(height: 14),
                          Text(
                            'Tidak Ditemukan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tidak ada addon yang sesuai kata kunci "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredAddons.length,
                  itemBuilder: (context, index) {
                    final addon = filteredAddons[index];
                    final currentSelected = _selectedMap[addon.id];
                    final qty = currentSelected?.quantity ?? 0;

                    return _AddonCardWithQty(
                      addon: addon,
                      quantity: qty,
                      currencyFormatter: currencyFormatter,
                      onAdd: () => _incrementQty(addon),
                      onRemove: () => _decrementQty(addon),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedMap.length} Jenis ($totalItemsCount Item)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(totalSelectedPrice),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_selectedMap.values.toList());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Terapkan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddonCardWithQty extends StatelessWidget {
  const _AddonCardWithQty({
    required this.addon,
    required this.quantity,
    required this.currencyFormatter,
    required this.onAdd,
    required this.onRemove,
  });

  final DecorationAddon addon;
  final int quantity;
  final NumberFormat currencyFormatter;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  static const _cardColors = [
    Color(0xFFFFF8E7),
    Color(0xFFF0F7FF),
    Color(0xFFF5F0FF),
    Color(0xFFF0FFF5),
    Color(0xFFFFF0F5),
  ];

  static const _cardIcons = [
    Icons.add_shopping_cart,
    Icons.flare_rounded,
    Icons.lightbulb_outline,
    Icons.filter_vintage_outlined,
    Icons.chair_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final isSelected = quantity > 0;
    final colorIndex = addon.id.hashCode.abs() % _cardColors.length;
    final bgColor = _cardColors[colorIndex];
    final icon = _cardIcons[colorIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryGold : Colors.grey.shade200,
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppTheme.primaryGold.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar / Ilustrasi + Badge Qty jika terpilih
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: addon.imageUrl.isNotEmpty
                    ? Image.network(
                        addon.imageUrl,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildIllustration(bgColor, icon),
                      )
                    : _buildIllustration(bgColor, icon),
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${quantity}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Detail Addon (Nama, Deskripsi, Harga Satuan)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addon.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${currencyFormatter.format(addon.price)} / unit',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                  const Spacer(),

                  // Counter Qty ( - 0 + ) atau tombol Tambah
                  if (!isSelected)
                    InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryGold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 14, color: AppTheme.primaryGold),
                            SizedBox(width: 4),
                            Text(
                              'Tambah',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: onRemove,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: const Icon(Icons.remove, size: 16, color: AppTheme.textDark),
                            ),
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          InkWell(
                            onTap: onAdd,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: const Icon(Icons.add, size: 16, color: AppTheme.primaryGold),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(Color bgColor, IconData icon) {
    return Container(
      height: 100,
      width: double.infinity,
      color: bgColor,
      child: Center(
        child: Icon(icon, size: 40, color: AppTheme.primaryGold),
      ),
    );
  }
}
