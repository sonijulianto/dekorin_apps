import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/property_service.dart';
import 'package:dekorin_apps/domain/models/property.dart';

class ManagePropertiesView extends ConsumerStatefulWidget {
  const ManagePropertiesView({super.key});

  @override
  ConsumerState<ManagePropertiesView> createState() => _ManagePropertiesViewState();
}

class _ManagePropertiesViewState extends ConsumerState<ManagePropertiesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({Property? property, String? initialType}) {
    final isEditing = property != null;
    final nameController = TextEditingController(text: property?.name ?? '');
    final categoryController = TextEditingController(text: property?.category ?? '');
    final stockController = TextEditingController(
      text: property != null ? property.totalStock.toString() : '1',
    );
    final unitController = TextEditingController(text: property?.unit ?? 'pcs');
    final notesController = TextEditingController(text: property?.notes ?? '');

    String selectedType = property?.type ?? initialType ?? (_tabController.index == 0 ? 'property' : 'tool');
    bool trackStock = property?.trackStock ?? (selectedType == 'property');

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.goldLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  selectedType == 'tool' ? Icons.build_rounded : Icons.inventory_2_rounded,
                                  color: AppColors.primaryGold,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isEditing
                                    ? 'Ubah ${selectedType == 'tool' ? 'Alat' : 'Properti'}'
                                    : 'Tambah ${selectedType == 'tool' ? 'Alat Kerja' : 'Properti Baru'}',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(bottomSheetCtx),
                            icon: const Icon(Icons.close, color: AppColors.textLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tipe Switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    selectedType = 'property';
                                    trackStock = true;
                                    if (categoryController.text == 'Alat Kerja') {
                                      categoryController.text = 'Rangka / Backdrop';
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedType == 'property' ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: selectedType == 'property'
                                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '📦 Properti Dekorasi',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: selectedType == 'property' ? AppColors.textDark : AppColors.textLight,
                                        fontWeight: selectedType == 'property' ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    selectedType = 'tool';
                                    trackStock = false;
                                    if (categoryController.text.isEmpty || categoryController.text == 'Rangka / Backdrop') {
                                      categoryController.text = 'Alat Kerja';
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedType == 'tool' ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: selectedType == 'tool'
                                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '🛠️ Alat Kerja',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: selectedType == 'tool' ? AppColors.textDark : AppColors.textLight,
                                        fontWeight: selectedType == 'tool' ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Penjelasan singkat tipe
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedType == 'property' ? Colors.amber.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedType == 'property' ? Colors.amber.shade200 : Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: selectedType == 'property' ? Colors.amber.shade900 : Colors.blue.shade900,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedType == 'property'
                                    ? 'Stok dicek per tanggal event (mencegah bentrok di hari yang sama).'
                                    : 'Alat kerja bebas dibawa & tidak membatasi stok per tanggal.',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: selectedType == 'property' ? Colors.amber.shade900 : Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nama Properti / Alat
                      Text('Nama Barang', style: AppTypography.labelMedium),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: selectedType == 'tool'
                              ? 'Contoh: Tangga Lipat 2M, Lem Tembak'
                              : 'Contoh: Lampu 50 Watt, Tiang Besi 3m',
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Kategori & Satuan
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kategori', style: AppTypography.labelMedium),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: categoryController,
                                  decoration: InputDecoration(
                                    hintText: selectedType == 'tool' ? 'Alat Kerja' : 'Rangka / Lighting',
                                    filled: true,
                                    fillColor: AppColors.backgroundLight,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.borderLight),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Satuan', style: AppTypography.labelMedium),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: unitController,
                                  decoration: InputDecoration(
                                    hintText: 'pcs/unit/set',
                                    filled: true,
                                    fillColor: AppColors.backgroundLight,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.borderLight),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Total Stok Fisik di Gudang
                      Text('Total Stok Fisik di Gudang', style: AppTypography.labelMedium),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'Jumlah unit tersedia',
                          suffixText: unitController.text.trim().isNotEmpty ? unitController.text.trim() : 'unit',
                          suffixStyle: AppTypography.bodySmall,
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Total stok wajib diisi';
                          final n = int.tryParse(val.trim());
                          if (n == null || n < 0) return 'Stok tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Catatan
                      Text('Catatan Tambahan (Opsional)', style: AppTypography.labelMedium),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Keterangan kondisi, warna, atau tempat penyimpanan',
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final name = nameController.text.trim();
                            final category = categoryController.text.trim().isNotEmpty
                                ? categoryController.text.trim()
                                : (selectedType == 'tool' ? 'Alat Kerja' : 'Lainnya');
                            final unit = unitController.text.trim().isNotEmpty ? unitController.text.trim() : 'pcs';
                            final totalStock = int.tryParse(stockController.text.trim()) ?? 1;
                            final notes = notesController.text.trim();

                            try {
                              final service = ref.read(propertyServiceProvider);
                              if (isEditing) {
                                await service.updateProperty(
                                  property.id,
                                  name: name,
                                  category: category,
                                  type: selectedType,
                                  trackStock: trackStock,
                                  totalStock: totalStock,
                                  unit: unit,
                                  notes: notes,
                                );
                              } else {
                                await service.createProperty(
                                  name: name,
                                  category: category,
                                  type: selectedType,
                                  trackStock: trackStock,
                                  totalStock: totalStock,
                                  unit: unit,
                                  notes: notes,
                                );
                              }

                              ref.invalidate(propertiesProvider);
                              if (bottomSheetCtx.mounted) {
                                Navigator.pop(bottomSheetCtx);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'Data barang berhasil diperbarui!'
                                          : 'Barang baru berhasil ditambahkan!',
                                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                    ),
                                    backgroundColor: AppColors.primaryGold,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (bottomSheetCtx.mounted) {
                                ScaffoldMessenger.of(bottomSheetCtx).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyimpan: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            isEditing ? 'Simpan Perubahan' : 'Tambah ke Inventaris',
                            style: AppTypography.button,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(Property property) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Hapus Barang?', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${property.name}" dari master inventaris?',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Batal', style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  await ref.read(propertyServiceProvider).deleteProperty(property.id);
                  ref.invalidate(propertiesProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Barang berhasil dihapus', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                        backgroundColor: AppColors.primaryGold,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: Text('Hapus', style: AppTypography.button),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Master Properti & Alat', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          indicatorWeight: 3,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textLight,
          labelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTypography.titleSmall,
          tabs: const [
            Tab(text: '📦 Properti Dekorasi'),
            Tab(text: '🛠️ Alat Kerja'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama properti atau alat kerja...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Tab View Content
          Expanded(
            child: propertiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Gagal memuat data: $err', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(propertiesProvider),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                        child: Text('Coba Lagi', style: AppTypography.button),
                      ),
                    ],
                  ),
                ),
              ),
              data: (items) {
                final properties = items.where((p) => p.isProperty).toList();
                final tools = items.where((p) => p.isTool).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPropertyList(properties, isToolTab: false),
                    _buildPropertyList(tools, isToolTab: true),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(
          initialType: _tabController.index == 0 ? 'property' : 'tool',
        ),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          _tabController.index == 0 ? 'Tambah Properti' : 'Tambah Alat Kerja',
          style: AppTypography.button,
        ),
      ),
    );
  }

  Widget _buildPropertyList(List<Property> items, {required bool isToolTab}) {
    final filtered = items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(_searchQuery) ||
          item.category.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isToolTab ? Icons.build_circle_outlined : Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.textLight.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Tidak ditemukan barang dengan kata kunci "$_searchQuery"'
                    : (isToolTab
                        ? 'Belum ada alat kerja yang ditambahkan'
                        : 'Belum ada properti dekorasi yang ditambahkan'),
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isToolTab ? Colors.blue.shade50 : AppColors.goldLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    isToolTab ? Icons.handyman_rounded : Icons.view_in_ar_rounded,
                    color: isToolTab ? Colors.blue.shade700 : AppColors.primaryGold,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (item.trackStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Cek Stok Tanggal',
                              style: AppTypography.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Bebas Bawa',
                              style: AppTypography.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.name, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.notes, style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('Stok Gudang: ', style: AppTypography.caption),
                        Text(
                          '${item.totalStock} ${item.unit}',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textLight),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showAddEditDialog(property: item);
                  } else if (val == 'delete') {
                    _showDeleteDialog(item);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGold),
                        const SizedBox(width: 8),
                        Text('Ubah Data', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Hapus', style: AppTypography.bodySmall.copyWith(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
