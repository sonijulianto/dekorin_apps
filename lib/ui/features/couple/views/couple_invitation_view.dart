import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/services/couple_service.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/couple/view_models/couple_plan_provider.dart';
import 'package:dekorin_apps/ui/features/invitation/views/guest_manager_sheet.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_generator_view.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_visual_editor_view.dart';

/// Tab Undangan Digital untuk Calon Pengantin:
/// klaim undangan dari vendor via Slug+PIN atau Link Kelola, edit konten, sinkron jadwal plan, & pantau tamu/RSVP.
class CoupleInvitationView extends ConsumerStatefulWidget {
  const CoupleInvitationView({super.key});

  @override
  ConsumerState<CoupleInvitationView> createState() => _CoupleInvitationViewState();
}

class _CoupleInvitationViewState extends ConsumerState<CoupleInvitationView> {
  final _slugCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  bool _claimByLink = false;
  bool _isClaiming = false;
  bool _isSyncing = false;

  @override
  void dispose() {
    _slugCtrl.dispose();
    _pinCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitClaim({VoidCallback? onSuccess}) async {
    setState(() => _isClaiming = true);
    try {
      await ref.read(coupleServiceProvider).claimInvitation(
            slug: _claimByLink ? '' : _slugCtrl.text.trim(),
            pin: _claimByLink ? '' : _pinCtrl.text.trim(),
            editTokenOrUrl: _claimByLink ? _linkCtrl.text.trim() : '',
          );
      _slugCtrl.clear();
      _pinCtrl.clear();
      _linkCtrl.clear();
      await ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
      if (mounted) {
        setState(() => _isClaiming = false);
        onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Undangan digital berhasil diklaim ke Wedding Plan!',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClaiming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _openEditInvitation(InvitationItem inv) async {
    final service = ref.read(coupleServiceProvider);
    InvitationItem target = inv;
    try {
      target = await service.getClaimedInvitationDetail(inv.id);
    } catch (_) {}

    if (!mounted) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InvitationVisualEditorView(
          invitation: target,
          onUpdateOverride: (id, payload) => service.updateClaimedInvitation(id, payload),
        ),
      ),
    );
    if (saved == true) {
      await ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
    }
  }

  Future<void> _syncFromPlan(InvitationItem inv) async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(coupleServiceProvider).syncPlanToInvitation(inv.id);
      await ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tanggal, jam, venue & Google Maps dari Wedding Plan berhasil disinkronkan!',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _unclaimInvitation(InvitationItem inv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Lepas Tautan Undangan?', style: AppTypography.titleLarge),
        content: Text(
          'Undangan "${inv.title}" akan dilepas dari akun Wedding Plan Anda (data undangan di vendor tetap aman).',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Lepas', style: AppTypography.button),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(coupleServiceProvider).unclaimInvitation(inv.id);
      await ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
    }
  }

  void _showClaimDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: _buildClaimCard(
            onSuccess: () {
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openPublicUrl(String slug) async {
    final url = ApiEndpoint.getInvitationWebUrl(slug);
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(coupleWorkspaceProvider);
    final invitations = workspace.invitations;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Undangan Digital', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (invitations.isNotEmpty)
            IconButton(
              tooltip: 'Klaim Undangan Lain',
              icon: const Icon(Icons.add_link_rounded, color: AppColors.primaryGold),
              onPressed: _showClaimDialog,
            ),
        ],
      ),
      body: workspace.isLoading && invitations.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
          : RefreshIndicator(
              color: AppColors.primaryGold,
              onRefresh: () => ref.read(coupleWorkspaceProvider.notifier).refreshAll(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (invitations.isEmpty) ...[
                    _buildEmptyIntroCard(),
                    const SizedBox(height: 16),
                    _buildClaimCard(),
                  ] else
                    ...invitations.map(_buildClaimedInvitationCard),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: SvgPicture.asset(
              'assets/icons/share.svg',
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hubungkan Undangan dari Vendor', style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Klaim undangan digital yang sudah dibuatkan vendor Anda agar bisa edit konten, sebar link WA, dan pantau konfirmasi kehadiran (RSVP) langsung di sini.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textDark.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard({VoidCallback? onSuccess}) {
    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Klaim Undangan Digital', style: AppTypography.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          'Slug & PIN',
                          style: AppTypography.labelMedium.copyWith(
                            color: !_claimByLink ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                      selected: !_claimByLink,
                      selectedColor: AppColors.primaryGold,
                      onSelected: (_) {
                        setState(() => _claimByLink = false);
                        setCardState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          'Link / Token Kelola',
                          style: AppTypography.labelMedium.copyWith(
                            color: _claimByLink ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                      selected: _claimByLink,
                      selectedColor: AppColors.primaryGold,
                      onSelected: (_) {
                        setState(() => _claimByLink = true);
                        setCardState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_claimByLink) ...[
                DekorinTextField(
                  controller: _slugCtrl,
                  label: 'Kode Tautan (Slug) Undangan',
                  hint: 'Contoh: bagas-zulia',
                  prefixIcon: Icons.link,
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _pinCtrl,
                  label: 'PIN Akses (6 Digit)',
                  hint: 'Contoh: 123456',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_outlined,
                ),
              ] else ...[
                DekorinTextField(
                  controller: _linkCtrl,
                  label: 'Link Portal Kelola / Edit Token',
                  hint: 'https://undangan.dekorin.my.id/kelola/inv_sec_...',
                  prefixIcon: Icons.vpn_key_outlined,
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isClaiming ? null : () => _submitClaim(onSuccess: onSuccess),
                  child: Text(
                    _isClaiming ? 'Memverifikasi...' : 'Klaim & Hubungkan Undangan',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClaimedInvitationCard(InvitationItem inv) {
    final publicUrl = ApiEndpoint.getInvitationWebUrl(inv.slug);
    int hadirCount = 0;
    int raguCount = 0;
    int tidakHadirCount = 0;
    int totalPax = 0;

    for (final w in inv.wishes) {
      final att = w.attendance.trim().toLowerCase();
      if (att == 'hadir') {
        hadirCount++;
        totalPax += w.guestCount > 0 ? w.guestCount : 1;
      } else if (att == 'tidak_hadir' || att == 'tidak hadir') {
        tidakHadirCount++;
      } else {
        raguCount++;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Terhubung • ${InvitationTemplate.getById(inv.template)['name']}',
                  style: AppTypography.caption.copyWith(color: AppColors.successGreen, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'unclaim') _unclaimInvitation(inv);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'unclaim',
                    child: Text('Lepas Tautan', style: AppTypography.bodyMedium.copyWith(color: AppColors.errorRed)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(inv.title.isNotEmpty ? inv.title : '${inv.groomName} & ${inv.brideName}', style: AppTypography.h3),
          const SizedBox(height: 6),

          // Public URL Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    publicUrl,
                    style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Salin Link',
                  icon: SvgPicture.asset(
                    'assets/icons/copy-alt.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: publicUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tautan undangan disalin', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Buka Website Undangan',
                  icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primaryGold),
                  onPressed: () => _openPublicUrl(inv.slug),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // RSVP & Estimasi Porsi Katering
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.goldLight.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STATISTIK RSVP & ESTIMASI TAMU', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RsvpStatPill(label: 'Hadir', value: '$hadirCount ($totalPax pax)', color: AppColors.successGreen),
                    const SizedBox(width: 8),
                    _RsvpStatPill(label: 'Ragu', value: '$raguCount', color: AppColors.warningAmber),
                    const SizedBox(width: 8),
                    _RsvpStatPill(label: 'Berhalangan', value: '$tidakHadirCount', color: AppColors.errorRed),
                  ],
                ),
                if (totalPax > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Estimasi katering: ~$totalPax tamu konfirmasi hadir (saran buffer ${totalPax * 2} porsi).',
                    style: AppTypography.caption.copyWith(color: AppColors.textDark),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openEditInvitation(inv),
                  icon: SvgPicture.asset(
                    'assets/icons/edit.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  label: Text('Edit Undangan', style: AppTypography.button),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => InvitationGeneratorView(invitation: inv)),
                    );
                  },
                  icon: SvgPicture.asset('assets/icons/wa.svg', width: 16, height: 16),
                  label: Text('Sebar WA', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: AppColors.primaryGold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSyncing ? null : () => _syncFromPlan(inv),
                  icon: const Icon(Icons.sync_rounded, size: 17, color: AppColors.textDark),
                  label: Text(
                    _isSyncing ? 'Menyinkronkan...' : 'Sinkron dari Wedding Plan',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textDark),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => GuestManagerSheet(invitation: inv),
                    );
                  },
                  icon: const Icon(Icons.menu_book_outlined, size: 17, color: AppColors.primaryGold),
                  label: Text(
                    'Buku Tamu (${inv.wishesCount})',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primaryGold),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RsvpStatPill extends StatelessWidget {
  const _RsvpStatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: AppTypography.titleSmall.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
