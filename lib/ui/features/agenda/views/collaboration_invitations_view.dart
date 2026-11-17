import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/collaboration_service.dart';
import 'package:dekorin_apps/domain/models/collaboration.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/dashboard/view_models/dashboard_view_model.dart';

/// Halaman daftar undangan kolaborasi masuk untuk vendor partner (MUA, FG, MC, dll.).
class CollaborationInvitationsView extends ConsumerStatefulWidget {
  const CollaborationInvitationsView({super.key});

  @override
  ConsumerState<CollaborationInvitationsView> createState() =>
      _CollaborationInvitationsViewState();
}

class _CollaborationInvitationsViewState
    extends ConsumerState<CollaborationInvitationsView> {
  String? _processingId;

  Future<void> _respond(
    IncomingCollaborationItem item,
    String action, {
    String rejectReason = '',
  }) async {
    setState(() => _processingId = item.collaboration.id);
    try {
      await ref.read(collaborationServiceProvider).respondCollaboration(
            collaborationId: item.collaboration.id,
            action: action,
            rejectReason: rejectReason,
          );
      ref.invalidate(incomingCollaborationsProvider);
      ref.invalidate(agendaViewModelProvider);
      ref.invalidate(dashboardViewModelProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'accept'
                  ? 'Undangan diterima! Agenda otomatis ditambahkan.'
                  : 'Undangan kolaborasi ditolak.',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor:
                action == 'accept' ? const Color(0xFF2E7D32) : AppColors.textDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _confirmReject(IncomingCollaborationItem item) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tolak Undangan?', style: AppTypography.titleMedium),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Alasan penolakan (opsional), mis. jadwal bentrok',
            hintStyle: AppTypography.bodySmall,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: Text('Tolak', style: AppTypography.button),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (confirmed == true) {
      await _respond(item, 'reject', rejectReason: reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncInvites = ref.watch(incomingCollaborationsProvider);
    final currencyFmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('EEEE, dd MMM yyyy • HH:mm', 'id_ID');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Undangan Kolaborasi', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: asyncInvites.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Gagal memuat undangan:\n$err',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (result) {
          if (result.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.handshake_outlined, size: 52, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('Belum ada undangan kolaborasi', style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Undangan dari vendor lain akan muncul di sini beserta notifikasi push.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(incomingCollaborationsProvider),
            color: AppColors.primaryGold,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: result.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final item = result.items[idx];
                final col = item.collaboration;
                final isProcessing = _processingId == col.id;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: col.isPending
                          ? AppColors.primaryGold.withValues(alpha: 0.5)
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Dari: ${col.leadCompanyName.isNotEmpty ? col.leadCompanyName : "Vendor Lead"}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondaryGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusBadge(col.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(item.clientName, style: AppTypography.titleMedium),
                      if (item.eventDateTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          dateFmt.format(item.eventDateTime!.toLocal()),
                          style: AppTypography.bodySmall,
                        ),
                      ],
                      if (item.hasScheduleConflict) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 16, color: Colors.amber.shade900),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Perhatian: Anda sudah memiliki agenda lain di tanggal ini.',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (item.eventAddress.isNotEmpty || item.mapsUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/google-maps-icon.webp',
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: item.mapsUrl.isNotEmpty
                                    ? () => launchUrl(Uri.parse(item.mapsUrl),
                                        mode: LaunchMode.externalApplication)
                                    : null,
                                child: Text(
                                  item.eventAddress.isNotEmpty
                                      ? item.eventAddress
                                      : 'Buka Google Maps',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: item.mapsUrl.isNotEmpty
                                        ? AppColors.secondaryGold
                                        : AppColors.textLight,
                                    decoration: item.mapsUrl.isNotEmpty
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Harga Layanan', style: AppTypography.bodySmall),
                                Text(currencyFmt.format(col.partnerPrice),
                                    style: AppTypography.labelLarge),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Biaya Transport', style: AppTypography.bodySmall),
                                Text(currencyFmt.format(col.partnerTransportFee),
                                    style: AppTypography.labelLarge),
                              ],
                            ),
                            const Divider(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Nilai',
                                    style: AppTypography.titleSmall
                                        .copyWith(fontWeight: FontWeight.bold)),
                                Text(
                                  currencyFmt.format(col.totalCost),
                                  style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.secondaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (col.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Catatan: ${col.notes}', style: AppTypography.bodySmall),
                      ],
                      if (col.isPending) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isProcessing ? null : () => _confirmReject(item),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.errorRed),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Tolak',
                                  style: AppTypography.button
                                      .copyWith(color: AppColors.errorRed, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: isProcessing ? null : () => _respond(item, 'accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGold,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: isProcessing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        'Terima & Masuk Agenda',
                                        style: AppTypography.button.copyWith(fontSize: 14),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'accepted':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Diterima';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Ditolak';
        break;
      case 'cancelled':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = 'Dibatalkan';
        break;
      default:
        bg = AppColors.goldLight;
        fg = AppColors.secondaryGold;
        label = 'Menunggu';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}
