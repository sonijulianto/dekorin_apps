import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/models/role_permission_model.dart';
import 'package:dekorin_apps/ui/features/team/view_models/role_permissions_view_model.dart';

class RolePermissionsView extends ConsumerStatefulWidget {
  const RolePermissionsView({super.key});

  @override
  ConsumerState<RolePermissionsView> createState() => _RolePermissionsViewState();
}

class _RolePermissionsViewState extends ConsumerState<RolePermissionsView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rolePermissionsViewModelProvider);
    final vm = ref.read(rolePermissionsViewModelProvider.notifier);

    // Tampilkan snackbar jika ada pesan
    ref.listen<RolePermissionsState>(rolePermissionsViewModelProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!, style: AppTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!, style: AppTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final selectedRole = state.selectedRole;
    final currentRolePerms = state.rolePermissions[selectedRole] ?? <String>{};

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Hak Akses & Izin Role', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            tooltip: 'Kembalikan ke Default',
            icon: const Icon(Icons.restart_alt_rounded, color: AppColors.textLight),
            onPressed: state.isLoading || state.isSaving
                ? null
                : () => _confirmResetDialog(context, vm, selectedRole),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
          : Column(
              children: [
                // Role Selector Tabs (Admin vs Crew)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _RoleTabButton(
                          title: 'Administrator',
                          subtitle: 'Admin Operasional',
                          icon: Icons.admin_panel_settings_rounded,
                          accentColor: AppColors.primaryGold,
                          isSelected: selectedRole == 'admin',
                          onTap: () => vm.selectRole('admin'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleTabButton(
                          title: 'Crew Lapangan',
                          subtitle: 'Staf Bongkar Muat',
                          icon: Icons.engineering_rounded,
                          accentColor: Colors.blue.shade600,
                          isSelected: selectedRole == 'crew',
                          onTap: () => vm.selectRole('crew'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      // Owner Full Access Info Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: AppColors.primaryGold, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Akses Penuh Pemilik Usaha (Owner)',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sebagai Owner, Anda selalu memiliki hak akses penuh ke seluruh fitur. Matriks di bawah mengatur fitur yang dapat diakses oleh akun ${selectedRole == 'admin' ? 'Administrator' : 'Crew Lapangan'}.',
                                    style: AppTypography.caption.copyWith(color: AppColors.textDark, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // List of Permission Categories
                      if (state.matrix != null)
                        ...state.matrix!.definitions.map((cat) {
                          return _buildCategoryCard(
                            context: context,
                            category: cat,
                            selectedRole: selectedRole,
                            currentRolePerms: currentRolePerms,
                            onToggleSingle: (permKey, val) {
                              vm.togglePermission(selectedRole, permKey, val);
                            },
                            onToggleCategory: (permKeys, val) {
                              vm.toggleCategory(selectedRole, permKeys, val);
                            },
                          );
                        }),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // Bottom Save Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: state.isSaving
                            ? null
                            : () async {
                                final ok = await vm.savePermissions();
                                if (ok && context.mounted) {
                                  // Berhasil disimpan
                                }
                              },
                        child: state.isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Simpan Izin ${selectedRole == 'admin' ? 'Administrator' : 'Crew Lapangan'}',
                                    style: AppTypography.button.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required PermissionCategoryModel category,
    required String selectedRole,
    required Set<String> currentRolePerms,
    required Function(String permKey, bool val) onToggleSingle,
    required Function(List<String> permKeys, bool val) onToggleCategory,
  }) {
    final catKeys = category.permissions.map((e) => e.id).toList();
    final enabledCount = catKeys.where((k) => currentRolePerms.contains(k)).length;
    final isAllEnabled = enabledCount == catKeys.length && catKeys.isNotEmpty;

    // Menentukan icon SVG berdasarkan nama kategori
    final String svgPath;
    if (category.category.toLowerCase().contains('keuangan')) {
      svgPath = 'assets/icons/wallet-income.svg';
    } else if (category.category.toLowerCase().contains('agenda')) {
      svgPath = 'assets/icons/calendar.svg';
    } else if (category.category.toLowerCase().contains('inventaris') ||
        category.category.toLowerCase().contains('pick list')) {
      svgPath = 'assets/icons/shipping-fast.svg';
    } else if (category.category.toLowerCase().contains('katalog') ||
        category.category.toLowerCase().contains('brand')) {
      svgPath = 'assets/icons/file-invoice-dollar.svg';
    } else {
      svgPath = 'assets/icons/ai-magic.svg';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    svgPath,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.category,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$enabledCount dari ${catKeys.length} izin aktif',
                        style: AppTypography.caption.copyWith(color: AppColors.textLight, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    onToggleCategory(catKeys, !isAllEnabled);
                  },
                  child: Text(
                    isAllEnabled ? 'Matikan Semua' : 'Pilih Semua',
                    style: AppTypography.caption.copyWith(
                      color: isAllEnabled ? Colors.red.shade600 : AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.dividerColor),

          // Items List
          ...category.permissions.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isChecked = currentRolePerms.contains(item.id);
            final isLast = idx == category.permissions.length - 1;

            return Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    item.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isChecked ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.description,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textLight,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                  value: isChecked,
                  activeThumbColor: AppColors.primaryGold,
                  activeTrackColor: AppColors.primaryGold.withValues(alpha: 0.35),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade200,
                  onChanged: (val) {
                    onToggleSingle(item.id, val);
                  },
                ),
                if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.dividerColor),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _confirmResetDialog(BuildContext context, RolePermissionsViewModel vm, String selectedRole) {
    final roleName = selectedRole == 'admin' ? 'Administrator' : 'Crew Lapangan';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Kembalikan ke Default?', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        content: Text(
          'Hak akses untuk role $roleName akan dikembalikan ke setelan standar bawaan sistem Dekorin.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              vm.resetToDefault();
            },
            child: Text('Ya, Reset', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _RoleTabButton extends StatelessWidget {
  const _RoleTabButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? accentColor : AppColors.textLight, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.textDark : AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? accentColor : AppColors.textLight,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
}
