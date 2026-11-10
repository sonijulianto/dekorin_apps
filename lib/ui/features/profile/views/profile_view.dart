import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/app_update_service.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/core/widgets/app_update_dialog.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/invoice_template_provider.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_template_setting_view.dart';
import 'package:dekorin_apps/ui/features/company/views/edit_company_view.dart';
import 'package:dekorin_apps/ui/features/company/views/manage_brands_view.dart';
import 'package:dekorin_apps/ui/features/invitation/views/manage_invitations_view.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_addons_view.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_decoration_models_view.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_packages_view.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_properties_view.dart';
import 'package:dekorin_apps/ui/features/profile/views/change_password_view.dart';
import 'package:dekorin_apps/ui/features/profile/views/form_config_view.dart';
import 'package:dekorin_apps/ui/features/team/views/manage_team_view.dart';
import 'package:dekorin_apps/ui/features/team/views/role_permissions_view.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(globalAuthProvider).value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Profil', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // VIP Gold Profile & Company Header Card
            _buildProfileHeaderCard(context, user),
            const SizedBox(height: 24),

            // Akun & Keamanan Section (Tampil untuk semua role: Owner, Admin, Crew)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'AKUN & KEAMANAN',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textLight),
              ),
            ),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryGold, size: 22),
                    ),
                    title: Text('Ubah Kata Sandi', style: AppTypography.titleSmall),
                    subtitle: Text('Perbarui kata sandi akun Anda untuk keamanan', style: AppTypography.caption),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordView()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Company Profile Section (Hanya tampil untuk Owner & Admin)
            if (user?.canManageCompany ?? false) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'PENGATURAN USAHA & BISNIS',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textLight),
                ),
              ),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.storefront_rounded, color: AppColors.primaryGold, size: 22),
                      ),
                      title: Text('Profil & Data Usaha Dekorasi', style: AppTypography.titleSmall),
                      subtitle: Text('Atur nama usaha, logo resmi, kontak, alamat, dan data invoice', style: AppTypography.caption),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditCompanyView()));
                      },
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.dividerColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.layers_outlined, color: AppColors.primaryGold, size: 22),
                      ),
                      title: Text('Kelola Multi-Brand / Sub-Brand', style: AppTypography.titleSmall),
                      subtitle: Text('Atur nama & logo brand berbeda untuk market dekorasi lain', style: AppTypography.caption),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBrandsView()));
                      },
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.dividerColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                        child: SvgPicture.asset(
                          'assets/icons/file-invoice-dollar.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                        ),
                      ),
                      title: Text('Template Desain Invoice', style: AppTypography.titleSmall),
                      subtitle: Consumer(
                        builder: (context, ref, _) {
                          final templateState = ref.watch(invoiceTemplateProvider);
                          final brands = ref.watch(companyBrandsProvider).valueOrNull ?? const <CompanyBrand>[];
                          final subtitleText = brands.isEmpty
                              ? '${templateState.defaultTemplate.name} (Aktif)'
                              : 'Utama: ${templateState.defaultTemplate.name} • Atur per Brand';
                          return Text(
                            subtitleText,
                            style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceTemplateSettingView()));
                      },
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.dividerColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                        child: SvgPicture.asset(
                          'assets/icons/edit.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                        ),
                      ),
                      title: Text('Pengaturan Form Link Client', style: AppTypography.titleSmall),
                      subtitle: Text('Atur daftar isian wajib/opsional & urutan per Sub-Brand', style: AppTypography.caption),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FormConfigView()));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Team Management Section (Hanya tampil untuk Owner & Admin)
            if (user?.canManageTeam ?? false) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'MANAJEMEN TIM & KARYAWAN',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textLight),
                ),
              ),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.people_alt_outlined, color: Colors.purple, size: 22),
                      ),
                      title: Text('Kelola Tim & Karyawan', style: AppTypography.titleSmall),
                      subtitle: Text(
                        user?.isOwner == true ? 'Atur akun Owner, Admin, dan Staf Lapangan' : 'Atur akun Crew / Staf Lapangan',
                        style: AppTypography.caption,
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageTeamView()));
                      },
                    ),
                    if (user?.isOwner == true) ...[
                      const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.dividerColor),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.security_outlined, color: Colors.indigo, size: 22),
                        ),
                        title: Text('Hak Akses & Izin Role', style: AppTypography.titleSmall),
                        subtitle: Text(
                          'Atur batas akses menu & fitur untuk Admin dan Crew lapangan',
                          style: AppTypography.caption,
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RolePermissionsView()));
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Master Data Menu Section (Hanya tampil untuk Owner & Admin, disembunyikan untuk Crew)
            if (user?.canManageMasterData ?? false) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'MASTER DATA DEKORASI',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textLight),
                ),
              ),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.inventory_2, color: AppColors.primaryGold, size: 22),
                      ),
                      title: Text('Kelola Paket Dekorasi', style: AppTypography.titleSmall),
                      subtitle: Text('Atur daftar paket, foto, dan harga dasar', style: AppTypography.caption),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePackagesView()));
                      },
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.dividerColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.view_carousel, color: AppColors.primaryGold, size: 22),
                      ),
                      title: Text('Kelola Model Dekorasi', style: AppTypography.titleSmall),
                      subtitle: Text('Atur katalog model dekorasi, foto, lebar, & harga', style: AppTypography.caption),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageDecorationModelsView()));
                      },
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.dividerColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.category_rounded, color: AppColors.primaryGold, size: 22),
                      ),
                      title: Text('Kelola Properti & Alat Kerja', style: AppTypography.titleSmall),
                      subtitle: Text('Inventaris barang dekorasi & toolkit operasional lapangan', style: AppTypography.caption),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePropertiesView()));
                      },
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.dividerColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.auto_awesome, color: AppColors.primaryGold, size: 22),
                      ),
                      title: Text('Kelola Item Tambahan (Addon)', style: AppTypography.titleSmall),
                      subtitle: Text('Atur item tambahan pilihan client & harga', style: AppTypography.caption),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAddonsView()));
                      },
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20, color: AppColors.dividerColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primaryGold, size: 22),
                      ),
                      title: Text('Kelola Undangan Digital', style: AppTypography.titleSmall),
                      subtitle: Text('Buat website undangan pernikahan & link tamu', style: AppTypography.caption),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageInvitationsView()));
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
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textLight),
              ),
            ),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder<String>(
                future: AppUpdateService.getCurrentVersionName(),
                builder: (context, snapshot) {
                  final versionStr = snapshot.data ?? '1.0.0';
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.system_update_rounded, color: AppColors.primaryGold, size: 22),
                    ),
                    title: Text('Periksa Pembaruan', style: AppTypography.titleSmall),
                    subtitle: Text('Versi $versionStr (Ketuk untuk cek pembaruan)', style: AppTypography.caption),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
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
                onPressed: () => _confirmLogout(context, ref),
                icon: const Icon(Icons.logout, size: 20, color: Colors.white),
                label: Text('Keluar Aplikasi', style: AppTypography.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar Aplikasi?', style: AppTypography.h3),
        content: Text('Apakah Anda yakin ingin keluar dari akun ini?', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(globalAuthProvider.notifier).logout();
            },
            child: Text('Keluar', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context, User? user) {
    final companyName = (user?.companyName.isNotEmpty ?? false) ? user!.companyName : 'Nama Usaha Belum Diatur';
    final companyAddress = (user?.companyAddress.isNotEmpty ?? false)
        ? user!.companyAddress
        : 'Alamat usaha belum diatur';
    final userName = (user?.name.isNotEmpty ?? false) ? user!.name : 'Pengguna Dekorin';
    final userPhone = (user?.phone.isNotEmpty ?? false)
        ? user!.phone
        : ((user?.email.isNotEmpty ?? false) ? user!.email : '-');
    final roleName = user?.roleDisplayName ?? 'Superadmin';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF563B13),
            Color(0xFF88632E),
            Color(0xFFA57D3E),
            Color(0xFF85632A),
            Color(0xFF4E350E),
          ],
          stops: [0.0, 0.28, 0.52, 0.78, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5B56D).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4E350E).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient soft radial light highlight on top-right
          Positioned(
            top: -40,
            right: 10,
            child: Container(
              width: 220,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFDEB57B).withValues(alpha: 0.28),
                    const Color(0xFFDEB57B).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (user?.canManageCompany ?? false)
                  ? () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditCompanyView()));
                    }
                  : null,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Section: Store Logo + Name + Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Logo Container (white rounded square)
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          padding: const EdgeInsets.all(6),
                          child: (user?.companyLogo.isNotEmpty ?? false)
                              ? Image.network(
                                  user!.companyLogo,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => _buildFallbackStoreLogo(),
                                )
                              : _buildFallbackStoreLogo(),
                        ),
                        const SizedBox(width: 14),
                        // Store Name & Address
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companyName,
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 1.5),
                                    child: Icon(
                                      Icons.location_on,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      companyAddress,
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white.withValues(alpha: 0.92),
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bottom Section: Frosted Card with User Name, Phone & Role Badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/mobile-notch.svg',
                                      width: 14,
                                      height: 14,
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        userPhone,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Gold Metallic Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFAF2E6),
                                  Color(0xFFE9D7BC),
                                  Color(0xFFD3B284),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.75),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              roleName,
                              style: AppTypography.labelMedium.copyWith(
                                color: const Color(0xFF2C1E0A),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackStoreLogo() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Image.asset(
          'assets/images/logo_icon.png',
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront, color: AppColors.primaryGold, size: 28),
        ),
      ),
    );
  }
}
