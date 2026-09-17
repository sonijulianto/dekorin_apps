import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_addons_view.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_packages_view.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(globalAuthProvider).value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Profil Admin', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.goldLight,
                    child: const Icon(Icons.person, size: 36, color: AppColors.primaryGold),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Admin Dekorin',
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'admin@dekorin.com',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Administrator',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Master Data Menu Section
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'MASTER DATA DEKORASI',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.inventory_2, color: AppColors.primaryGold, size: 22),
                    ),
                    title: Text('Kelola Paket Dekorasi', style: AppTypography.titleSmall),
                    subtitle: Text('Atur daftar paket, foto, dan harga dasar', style: AppTypography.caption),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManagePackagesView()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.dividerColor),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.primaryGold, size: 22),
                    ),
                    title: Text('Kelola Item Tambahan (Addon)', style: AppTypography.titleSmall),
                    subtitle: Text('Atur item tambahan pilihan client & harga', style: AppTypography.caption),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageAddonsView()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(globalAuthProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout, size: 20),
                label: Text('Keluar Aplikasi', style: AppTypography.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
