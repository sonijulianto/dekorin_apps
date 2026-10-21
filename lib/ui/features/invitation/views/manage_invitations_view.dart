import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/services/invitation_service.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/ui/features/invitation/views/guest_manager_sheet.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_form_view.dart';

final invitationsProvider = FutureProvider.autoDispose<List<InvitationItem>>((ref) async {
  final service = ref.watch(invitationServiceProvider);
  return service.getInvitations();
});

class ManageInvitationsView extends ConsumerStatefulWidget {
  const ManageInvitationsView({super.key});

  @override
  ConsumerState<ManageInvitationsView> createState() => _ManageInvitationsViewState();
}

class _ManageInvitationsViewState extends ConsumerState<ManageInvitationsView> {
  void _openGuestManager(InvitationItem invitation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => GuestManagerSheet(invitation: invitation),
    );
  }

  void _confirmDelete(InvitationItem invitation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Undangan', style: AppTypography.titleMedium),
        content: Text(
          'Apakah Anda yakin ingin menghapus undangan "${invitation.title}"?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.labelMedium.copyWith(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(invitationServiceProvider).deleteInvitation(invitation.id);
                ref.invalidate(invitationsProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
                }
              }
            },
            child: Text('Hapus', style: AppTypography.labelMedium.copyWith(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invitationsAsync = ref.watch(invitationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Kelola Undangan Digital', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const InvitationFormView()),
          );
          if (res == true) {
            ref.invalidate(invitationsProvider);
          }
        },
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Buat Undangan Baru', style: AppTypography.button.copyWith(fontSize: 14)),
      ),
      body: invitationsAsync.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail_outline, size: 70, color: AppColors.primaryGold.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('Belum Ada Undangan Digital', style: AppTypography.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Buat website undangan pernikahan digital untuk klien dengan mudah dan cepat.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final res = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => const InvitationFormView()),
                        );
                        if (res == true) {
                          ref.invalidate(invitationsProvider);
                        }
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Buat Undangan Sekarang', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(invitationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: invitations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final inv = invitations[index];
                final webUrl = ApiEndpoint.getInvitationWebUrl(inv.slug);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: inv.coverImage.isNotEmpty
                                  ? Image.network(
                                      inv.coverImage,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _buildPlaceholderImage(),
                                    )
                                  : _buildPlaceholderImage(),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.title.isNotEmpty
                                        ? inv.title
                                        : '${inv.groomNickname} & ${inv.brideNickname}',
                                    style: AppTypography.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${inv.groomName} & ${inv.brideName}',
                                    style: AppTypography.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldLight.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '/${inv.slug}',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final res = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(builder: (_) => InvitationFormView(invitation: inv)),
                                  );
                                  if (res == true) {
                                    ref.invalidate(invitationsProvider);
                                  }
                                } else if (value == 'delete') {
                                  _confirmDelete(inv);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Edit Undangan', style: AppTypography.bodyMedium),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete, size: 18, color: AppColors.errorRed),
                                      const SizedBox(width: 8),
                                      Text('Hapus', style: AppTypography.bodyMedium.copyWith(color: AppColors.errorRed)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 22, color: AppColors.dividerColor),

                        // Action Buttons Bar
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryGold,
                                  side: const BorderSide(color: AppColors.primaryGold),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () async {
                                  final uri = Uri.parse(webUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.open_in_browser, size: 16),
                                label: const Text('Buka Web', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGold,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () => _openGuestManager(inv),
                                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                                label: const Text(
                                  'Kelola Tamu & WA',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (e, _) => Center(
          child: Text('Gagal memuat undangan: $e', style: const TextStyle(color: AppColors.errorRed)),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: AppColors.goldLight,
      child: const Icon(Icons.favorite, color: AppColors.primaryGold, size: 28),
    );
  }
}
