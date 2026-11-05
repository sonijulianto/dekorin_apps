import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';

class SelectedCatalogPhoto {
  const SelectedCatalogPhoto({
    required this.name,
    required this.imageUrl,
    this.subtitle = '',
  });

  final String name;
  final String imageUrl;
  final String subtitle;
}

class CatalogPhotoPickerSheet extends ConsumerStatefulWidget {
  const CatalogPhotoPickerSheet({super.key});

  @override
  ConsumerState<CatalogPhotoPickerSheet> createState() => _CatalogPhotoPickerSheetState();
}

class _CatalogPhotoPickerSheetState extends ConsumerState<CatalogPhotoPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(decorationModelsProvider);
    final packagesAsync = ref.watch(packagesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pilih dari Katalog Dekorin', style: AppTypography.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Pilih foto model atau paket dekorasi yang sudah tersimpan',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textDark),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: AppTypography.bodyMedium,
              onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama model atau paket dekorasi...',
                hintStyle: AppTypography.bodySmall,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textLight),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryGold,
              labelColor: AppColors.primaryGold,
              unselectedLabelColor: AppColors.textLight,
              labelStyle: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold),
              unselectedLabelStyle: AppTypography.labelMedium.copyWith(color: AppColors.textLight),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Model Dekorasi'),
                Tab(text: 'Paket Dekorasi'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Model Dekorasi
                modelsAsync.when(
                  data: (models) {
                    final withPhoto = models
                        .where((m) =>
                            m.imageUrl.trim().isNotEmpty &&
                            (_query.isEmpty ||
                                m.name.toLowerCase().contains(_query) ||
                                m.description.toLowerCase().contains(_query)))
                        .toList();
                    if (withPhoto.isEmpty) {
                      return _buildEmptyInfo(
                        'Belum ada foto pada Katalog Model Dekorasi yang cocok.',
                      );
                    }
                    return _buildPhotoGrid(
                      items: withPhoto
                          .map((DecorationModel m) => SelectedCatalogPhoto(
                                name: m.name,
                                imageUrl: m.imageUrl,
                                subtitle: m.width.isNotEmpty ? 'Lebar ${m.width}' : m.brandName,
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGold),
                  ),
                  error: (err, _) => _buildEmptyInfo('Gagal memuat katalog model: $err'),
                ),

                // Tab 2: Paket Dekorasi
                packagesAsync.when(
                  data: (packages) {
                    final withPhoto = packages
                        .where((p) =>
                            p.imageUrl.trim().isNotEmpty &&
                            (_query.isEmpty ||
                                p.name.toLowerCase().contains(_query) ||
                                p.description.toLowerCase().contains(_query)))
                        .toList();
                    if (withPhoto.isEmpty) {
                      return _buildEmptyInfo(
                        'Belum ada foto pada Katalog Paket Dekorasi yang cocok.',
                      );
                    }
                    return _buildPhotoGrid(
                      items: withPhoto
                          .map((DecorationPackage p) => SelectedCatalogPhoto(
                                name: p.name,
                                imageUrl: p.imageUrl,
                                subtitle: p.brandName,
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGold),
                  ),
                  error: (err, _) => _buildEmptyInfo('Gagal memuat katalog paket: $err'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInfo(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, size: 42, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid({required List<SelectedCatalogPhoto> items}) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.pop(context, item),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.goldLight,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined, color: AppColors.primaryGold),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(fontSize: 13),
                        ),
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
