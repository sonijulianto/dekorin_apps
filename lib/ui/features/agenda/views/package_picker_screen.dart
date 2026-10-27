import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';

/// Screen untuk memilih paket dekorasi dengan tampilan card bergambar.
/// Mengembalikan [DecorationPackage] yang dipilih ke caller via [Navigator.pop].
class PackagePickerScreen extends ConsumerWidget {
  const PackagePickerScreen({super.key, this.selectedPackageId});

  final String? selectedPackageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pilih Paket Dekorasi',
          style: AppTypography.titleLarge.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: packagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat paket: $e',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppTheme.textLight),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(packagesProvider),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.white),
                  child: Text('Coba Lagi', style: AppTypography.button),
                ),
              ],
            ),
          ),
        ),
        data: (packages) {
          if (packages.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(packagesProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada paket dekorasi',
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tambahkan paket di menu Profile > Kelola Paket',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(packagesProvider),
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final pkg = packages[index];
                final isSelected = pkg.id == selectedPackageId;
                return _PackageCard(
                  package: pkg,
                  isSelected: isSelected,
                  currencyFormatter: currencyFormatter,
                  onTap: () => Navigator.of(context).pop(pkg),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.currencyFormatter,
    required this.onTap,
  });

  final DecorationPackage package;
  final bool isSelected;
  final NumberFormat currencyFormatter;
  final VoidCallback onTap;

  static const _cardColors = [Color(0xFFFFF8E7), Color(0xFFF0F7FF), Color(0xFFF5F0FF), Color(0xFFF0FFF5)];

  static const _cardIcons = [Icons.auto_awesome, Icons.diamond_outlined, Icons.workspace_premium, Icons.stars_rounded];

  @override
  Widget build(BuildContext context) {
    final colorIndex = package.id.hashCode.abs() % _cardColors.length;
    final bgColor = _cardColors[colorIndex];
    final icon = _cardIcons[colorIndex];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primaryGold : Colors.transparent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppTheme.primaryGold.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto / Ilustrasi
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: package.imageUrl.isNotEmpty
                  ? Image.network(
                      package.imageUrl,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildIllustration(bgColor, icon),
                    )
                  : _buildIllustration(bgColor, icon),
            ),

            // Info nama, deskripsi, harga
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: AppTypography.labelMedium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      package.description,
                      style: AppTypography.caption.copyWith(fontSize: 10, color: AppTheme.textLight, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currencyFormatter.format(package.basePrice),
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Badge "Dipilih"
            if (isSelected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGold,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Dipilih',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(Color bgColor, IconData icon) {
    return Container(
      height: 110,
      width: double.infinity,
      color: bgColor,
      child: Center(child: Icon(icon, size: 48, color: AppTheme.primaryGold)),
    );
  }
}
