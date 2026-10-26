import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';

/// Hasil pemilihan model dekorasi beserta harga tambahan
class SelectedModelResult {
  final DecorationModel? model;
  final double additionalPrice;
  final bool isCleared;

  const SelectedModelResult({
    this.model,
    this.additionalPrice = 0.0,
    this.isCleared = false,
  });

  factory SelectedModelResult.clear() => const SelectedModelResult(isCleared: true);
}

/// Screen untuk memilih model dekorasi yang terhubung dengan paket dekorasi
class ModelPickerScreen extends ConsumerStatefulWidget {
  const ModelPickerScreen({
    super.key,
    this.package,
    this.selectedModelId,
    this.canClearModel = false,
  });

  final DecorationPackage? package;
  final String? selectedModelId;
  final bool canClearModel;

  @override
  ConsumerState<ModelPickerScreen> createState() => _ModelPickerScreenState();
}

class _ModelPickerScreenState extends ConsumerState<ModelPickerScreen> with SingleTickerProviderStateMixin {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  TabController? _tabController;
  bool _hasPackageModels = false;

  @override
  void initState() {
    super.initState();
    _hasPackageModels = widget.package != null && widget.package!.packageModels.isNotEmpty;
    if (_hasPackageModels) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _selectModel(DecorationModel model, double additionalPrice) {
    Navigator.of(context).pop(
      SelectedModelResult(
        model: model,
        additionalPrice: additionalPrice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allModelsAsync = ref.watch(decorationModelsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Model Dekorasi',
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            if (widget.package != null)
              Text(
                'Paket: ${widget.package!.name}',
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (widget.canClearModel || (widget.selectedModelId != null && widget.selectedModelId!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(SelectedModelResult.clear());
                },
                icon: const Icon(Icons.close, size: 16, color: AppColors.errorRed),
                label: const Text(
                  'Kosongkan',
                  style: TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
        bottom: _hasPackageModels
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryGold,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.textLight,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Model Paket (${widget.package!.packageModels.length})'),
                  const Tab(text: 'Semua Model'),
                ],
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: Colors.grey.shade100, height: 1),
              ),
      ),
      body: allModelsAsync.when(
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
                Text('Gagal memuat model: $e', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textLight)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(decorationModelsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (allModels) {
          if (allModels.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_carousel_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Belum ada master data model dekorasi', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Silakan buat model dekorasi di menu Profil > Kelola Model Dekorasi', textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final allModelsMap = {for (final m in allModels) m.id: m};

          if (_hasPackageModels) {
            // Tab 1: Model yang termasuk dalam paket ini
            final packageModelsView = ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.package!.packageModels.length,
              itemBuilder: (ctx, idx) {
                final pm = widget.package!.packageModels[idx];
                final model = pm.decorationModel ?? allModelsMap[pm.decorationModelId];
                if (model == null) return const SizedBox.shrink();

                final isSelected = widget.selectedModelId == model.id;
                final additionalPrice = pm.additionalPrice;

                return _buildModelCard(
                  model: model,
                  additionalPrice: additionalPrice,
                  isSelected: isSelected,
                  isFromPackage: true,
                );
              },
            );

            // Tab 2: Semua model master
            final allModelsView = ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allModels.length,
              itemBuilder: (ctx, idx) {
                final model = allModels[idx];
                final isSelected = widget.selectedModelId == model.id;

                // Cek apakah model ini ada di paket untuk dapat additionalPrice-nya
                final matchingPm = widget.package!.packageModels
                    .where((pm) => pm.decorationModelId == model.id)
                    .firstOrNull;
                final additionalPrice = matchingPm?.additionalPrice ?? 0.0;

                return _buildModelCard(
                  model: model,
                  additionalPrice: additionalPrice,
                  isSelected: isSelected,
                  isFromPackage: matchingPm != null,
                );
              },
            );

            return TabBarView(
              controller: _tabController,
              children: [
                packageModelsView,
                allModelsView,
              ],
            );
          }

          // Jika paket belum memiliki model terhubung, tampilkan semua model master
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allModels.length,
            itemBuilder: (ctx, idx) {
              final model = allModels[idx];
              final isSelected = widget.selectedModelId == model.id;

              return _buildModelCard(
                model: model,
                additionalPrice: 0.0,
                isSelected: isSelected,
                isFromPackage: false,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModelCard({
    required DecorationModel model,
    required double additionalPrice,
    required bool isSelected,
    required bool isFromPackage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryGold : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectModel(model, additionalPrice),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar: Foto + Info Utama
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar Model Dekorasi
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: model.imageUrl.isNotEmpty
                          ? Image.network(
                              model.imageUrl,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 90,
                                height: 90,
                                color: AppColors.goldLight,
                                child: const Icon(Icons.view_carousel, color: AppTheme.primaryGold, size: 36),
                              ),
                            )
                          : Container(
                              width: 90,
                              height: 90,
                              color: AppColors.goldLight,
                              child: const Icon(Icons.view_carousel, color: AppTheme.primaryGold, size: 36),
                            ),
                    ),
                    const SizedBox(width: 14),

                    // Teks Nama, Ukuran Lebar, Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  model.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGold,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, size: 12, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Terpilih',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Badge Lebar Dekorasi
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.goldLight.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.straighten, size: 14, color: AppColors.primaryGold),
                                const SizedBox(width: 4),
                                Text(
                                  model.width.isNotEmpty ? 'Lebar: ${model.width}' : 'Lebar Standar',
                                  style: const TextStyle(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Label Biaya Tambahan
                          if (additionalPrice > 0)
                            Row(
                              children: [
                                const Icon(Icons.add_circle, size: 14, color: AppColors.primaryGold),
                                const SizedBox(width: 4),
                                Text(
                                  'Tambahan Biaya: +${currencyFormatter.format(additionalPrice)}',
                                  style: const TextStyle(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          else if (isFromPackage)
                            const Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 14, color: AppTheme.successGreen),
                                SizedBox(width: 4),
                                Text(
                                  'Termasuk Paket (Tanpa Biaya Tambahan)',
                                  style: TextStyle(
                                    color: AppTheme.successGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Harga Model: ${currencyFormatter.format(model.price)}',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (model.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    model.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.grey.shade200 : AppTheme.primaryGold,
                      foregroundColor: isSelected ? AppTheme.textDark : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _selectModel(model, additionalPrice),
                    child: Text(
                      isSelected ? '✓ Model Ini Dipilih' : 'Pilih Model Ini',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppTheme.textDark : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
