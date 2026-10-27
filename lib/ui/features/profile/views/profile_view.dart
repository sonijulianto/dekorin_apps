import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/app_update_service.dart';
import 'package:dekorin_apps/ui/core/widgets/app_update_dialog.dart';
import 'package:dekorin_apps/ui/features/invitation/views/manage_invitations_view.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_addons_view.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_decoration_models_view.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_packages_view.dart';
import 'package:dekorin_apps/ui/features/team/views/manage_team_view.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(globalAuthProvider).value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Profil & Usaha', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Info Banner (Multi-Company Identity)
            if (user?.companyName.isNotEmpty ?? false) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront, color: AppColors.primaryGold, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'BADAN USAHA DEKORASI',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user!.companyName,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.companyAddress.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              user.companyAddress,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                    backgroundColor: user?.isOwner == true
                        ? Colors.purple.withValues(alpha: 0.15)
                        : (user?.isCrew == true
                            ? Colors.blue.withValues(alpha: 0.15)
                            : AppColors.goldLight),
                    child: Icon(
                      user?.isOwner == true
                          ? Icons.workspace_premium
                          : (user?.isCrew == true ? Icons.engineering : Icons.person),
                      size: 32,
                      color: user?.isOwner == true
                          ? Colors.purple
                          : (user?.isCrew == true ? Colors.blue : AppColors.primaryGold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Pengguna Dekorin',
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_android, size: 14, color: AppColors.textLight),
                            const SizedBox(width: 4),
                            Text(
                              user?.phone.isNotEmpty == true ? user!.phone : (user?.email ?? '-'),
                              style: AppTypography.bodySmall.copyWith(fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: user?.isOwner == true
                                ? Colors.purple.withValues(alpha: 0.15)
                                : (user?.isCrew == true
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : AppColors.goldLight),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user?.roleDisplayName ?? 'Administrator',
                            style: AppTypography.caption.copyWith(
                              color: user?.isOwner == true
                                  ? Colors.purple
                                  : (user?.isCrew == true
                                      ? Colors.blue
                                      : AppColors.primaryGold),
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

            // Team Management Section (Hanya tampil untuk Owner & Admin)
            if (user?.canManageTeam ?? false) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'MANAJEMEN TIM & KARYAWAN',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textLight,
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
                          color: Colors.purple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.people_alt_outlined, color: Colors.purple, size: 22),
                      ),
                      title: Text('Kelola Tim & Karyawan', style: AppTypography.titleSmall),
                      subtitle: Text(
                        user?.isOwner == true
                            ? 'Atur akun Owner, Admin, dan Staf Lapangan'
                            : 'Atur akun Crew / Staf Lapangan',
                        style: AppTypography.caption,
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManageTeamView()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Master Data Menu Section (Hanya tampil untuk Owner & Admin, disembunyikan untuk Crew)
            if (user?.canManageMasterData ?? true) ...[
              Padding(
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
                        child: const Icon(Icons.view_carousel, color: AppColors.primaryGold, size: 22),
                      ),
                      title: Text('Kelola Model Dekorasi', style: AppTypography.titleSmall),
                      subtitle: Text('Atur katalog model dekorasi, foto, lebar, & harga', style: AppTypography.caption),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManageDecorationModelsView()),
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
                    const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.dividerColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primaryGold, size: 22),
                      ),
                      title: Text('Kelola Undangan Digital', style: AppTypography.titleSmall),
                      subtitle: Text('Buat website undangan pernikahan & link tamu', style: AppTypography.caption),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManageInvitationsView()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // App Information & Update Section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'INFORMASI APLIKASI',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.textLight,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: FutureBuilder<String>(
                future: AppUpdateService.getCurrentVersionName(),
                builder: (context, snapshot) {
                  final versionStr = snapshot.data ?? '1.0.0';
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: AppColors.primaryGold,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Periksa Pembaruan',
                      style: AppTypography.titleSmall,
                    ),
                    subtitle: Text(
                      'Versi $versionStr (Ketuk untuk cek pembaruan)',
                      style: AppTypography.caption,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textLight,
                    ),
                    onTap: () {
                      AppUpdateChecker.check(context, showToastIfLatest: true);
                    },
                  );
                },
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
