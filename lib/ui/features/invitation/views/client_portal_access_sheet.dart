import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/services/invitation_service.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';

class ClientPortalAccessSheet extends ConsumerStatefulWidget {
  const ClientPortalAccessSheet({
    super.key,
    required this.invitation,
    this.onAccessUpdated,
  });

  final InvitationItem invitation;
  final VoidCallback? onAccessUpdated;

  @override
  ConsumerState<ClientPortalAccessSheet> createState() => _ClientPortalAccessSheetState();
}

class _ClientPortalAccessSheetState extends ConsumerState<ClientPortalAccessSheet> {
  late InvitationItem _inv;
  late TextEditingController _clientWaController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inv = widget.invitation;
    _clientWaController = TextEditingController(text: _inv.waConfirmation);
    if (_inv.editToken.isEmpty || _inv.editPin.isEmpty) {
      _ensureCredentialsFromServer();
    }
  }

  @override
  void dispose() {
    _clientWaController.dispose();
    super.dispose();
  }

  Future<void> _ensureCredentialsFromServer() async {
    setState(() => _isLoading = true);
    final fresh = await ref.read(invitationServiceProvider).getInvitation(_inv.id);
    if (mounted) {
      setState(() {
        if (fresh != null) _inv = fresh;
        _isLoading = false;
      });
      widget.onAccessUpdated?.call();
    }
  }

  String get _portalManageUrl => ApiEndpoint.getInvitationPortalManageUrl(_inv.editToken);
  String get _publicInvitationUrl => ApiEndpoint.getInvitationWebUrl(_inv.slug);
  String get _portalLoginDomain => ApiEndpoint.invitationDomainBaseUrl;

  String _buildWhatsAppAccessMessage() {
    final title = _inv.title.isNotEmpty
        ? _inv.title
        : (_inv.eventType == 'khitan'
            ? 'Tasyakuran Khitanan ${_inv.childName.isNotEmpty ? _inv.childName : _inv.groomName}'
            : '${_inv.groomNickname} & ${_inv.brideNickname}');

    return '''Halo Kak! ✨
Berikut akses mandiri untuk mengelola Website Undangan Digital acara Kakak:

💌 *$title*

🔗 *Link Kelola Langsung (1-Klik Masuk):*
$_portalManageUrl

🔐 *Atau Login Manual di $_portalLoginDomain:*
• Kode Undangan: *${_inv.slug}*
• PIN Akses: *${_inv.editPin}*

🌐 *Link Publik Undangan Tamu:*
$_publicInvitationUrl

Melalui Portal Kelola di atas, Kakak dapat dengan mudah:
1. Mengedit data acara, foto, jadwal, maps & nomor rekening sendiri.
2. Memantau daftar tamu yang sudah konfirmasi kehadiran (RSVP) & download Excel.
3. Membuat nama tamu khusus & sebar undangan ke WhatsApp.

Silakan disimpan ya Kak, terima kasih! 🙏''';
  }

  void _copyText(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin!', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendToClientWhatsApp() async {
    final msg = _buildWhatsAppAccessMessage();
    String phone = _clientWaController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    }

    final uri = phone.isNotEmpty
        ? Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}')
        : Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPortalInBrowser() async {
    final uri = Uri.parse(_portalManageUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmResetAccess() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Link & PIN Klien?', style: AppTypography.titleMedium),
        content: Text(
          'Link kelola lama dan PIN 6 digit sebelumnya tidak akan bisa dipakai lagi dan diganti dengan yang baru.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppTypography.labelMedium.copyWith(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya, Buat Baru', style: AppTypography.labelMedium.copyWith(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final updated = await ref.read(invitationServiceProvider).resetInvitationAccess(_inv.id);
      if (mounted) {
        setState(() {
          _inv = updated;
          _isLoading = false;
        });
        widget.onAccessUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link akses & PIN baru berhasil dibuat!', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal me-reset akses: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
      child: _isLoading
          ? const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/icons/lock.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Akses Web Kelola Pengantin', style: AppTypography.titleMedium),
                            Text(
                              'Bagikan ke klien agar bisa edit undangan, cek RSVP & sebar WA sendiri.',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Card 1: Direct Manage Link
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LINK KELOLA LANGSUNG (1-KLIK TANPA PASSWORD)',
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryGold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _portalManageUrl,
                          style: AppTypography.bodySmall.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: AppColors.primaryGold),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () => _copyText(_portalManageUrl, 'Link kelola pengantin'),
                                icon: SvgPicture.asset(
                                  'assets/icons/copy-alt.svg',
                                  width: 14,
                                  height: 14,
                                  colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                                ),
                                label: Text(
                                  'Salin Link',
                                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: AppColors.borderLight),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: _openPortalInBrowser,
                                icon: SvgPicture.asset(
                                  'assets/icons/mobile-notch.svg',
                                  width: 14,
                                  height: 14,
                                  colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                                ),
                                label: Text(
                                  'Buka Portal',
                                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Card 2: Slug & 6-Digit PIN Manual Login
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Login Manual di $_portalLoginDomain', style: AppTypography.caption),
                              const SizedBox(height: 4),
                              Text(
                                'Kode: ${_inv.slug}   •   PIN: ${_inv.editPin}',
                                style: AppTypography.titleSmall.copyWith(color: AppColors.textDark),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Salin PIN',
                          onPressed: () => _copyText('Kode: ${_inv.slug}\nPIN: ${_inv.editPin}', 'Kode & PIN'),
                          icon: SvgPicture.asset(
                            'assets/icons/copy-alt.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(AppColors.secondaryGold, BlendMode.srcIn),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional Client WhatsApp Number
                  DekorinTextField(
                    controller: _clientWaController,
                    label: 'Nomor WhatsApp Pengantin (Opsional)',
                    hint: 'Contoh: 081234567890',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  // Send via WhatsApp & Copy Full Instructions
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryGold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _copyText(_buildWhatsAppAccessMessage(), 'Pesan panduan akses'),
                            icon: SvgPicture.asset(
                              'assets/icons/share.svg',
                              width: 15,
                              height: 15,
                              colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                            ),
                            label: Text(
                              'Salin Pesan',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _sendToClientWhatsApp,
                            icon: SvgPicture.asset(
                              'assets/icons/wa.svg',
                              width: 17,
                              height: 17,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                            label: Text(
                              'Kirim ke WA Klien',
                              style: AppTypography.labelLarge.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Center(
                    child: TextButton(
                      onPressed: _confirmResetAccess,
                      child: Text(
                        'Reset Link & PIN Akses Baru',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
