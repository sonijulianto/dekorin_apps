import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/couple_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/wedding_plan.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/couple/view_models/couple_plan_provider.dart';
import 'package:dekorin_apps/ui/features/couple/views/vendor_directory_view.dart';

/// Tab Vendor & Budget untuk Calon Pengantin:
/// memantau target budget, tagihan DP/pelunasan, vendor Dekorin tersinkron, dan catatan vendor eksternal.
class CoupleVendorsView extends ConsumerStatefulWidget {
  const CoupleVendorsView({super.key});

  @override
  ConsumerState<CoupleVendorsView> createState() => _CoupleVendorsViewState();
}

class _CoupleVendorsViewState extends ConsumerState<CoupleVendorsView> {
  String _selectedCategory = 'all';

  Future<void> _openWhatsApp(String rawPhone, String vendorName) async {
    var clean = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    }
    final msg = Uri.encodeComponent('Halo $vendorName, kami ingin berkoordinasi mengenai acara pernikahan kami.');
    final uri = Uri.parse('https://wa.me/$clean?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAddOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tambah Vendor ke Wedding Plan', style: AppTypography.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primaryGold),
                ),
                title: Text('Cari di Direktori Vendor Dekorin', style: AppTypography.titleSmall),
                subtitle: Text('Jelajahi vendor Dekorasi, WO, MUA, Foto & Katering', style: AppTypography.caption),
                onTap: () async {
                  Navigator.pop(ctx);
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const VendorDirectoryView()),
                  );
                  if (changed == true) {
                    ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
                  }
                },
              ),
              const Divider(height: 1, color: AppColors.dividerColor),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.link_rounded, color: AppColors.primaryGold),
                ),
                title: Text('Tautkan Booking Vendor Dekorin', style: AppTypography.titleSmall),
                subtitle: Text('Tempel link form / kode booking dari vendor untuk sinkron otomatis', style: AppTypography.caption),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLinkAgendaDialog();
                },
              ),
              const Divider(height: 1, color: AppColors.dividerColor),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(12)),
                  child: SvgPicture.asset(
                    'assets/icons/edit.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                  ),
                ),
                title: Text('Catat Vendor Eksternal Manual', style: AppTypography.titleSmall),
                subtitle: Text('Catat vendor lain (KUA, Mahar, MUA, Katering) & jadwal DP', style: AppTypography.caption),
                onTap: () {
                  Navigator.pop(ctx);
                  _showVendorFormSheet();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLinkAgendaDialog() {
    final tokenCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Tautkan Agenda Dekorin', style: AppTypography.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan link Client Form atau kode booking dari vendor Dekorin Anda agar paket, harga, DP, dan status otomatis tersinkron.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              DekorinTextField(
                controller: tokenCtrl,
                label: 'Link Form / Kode Booking',
                hint: 'https://dekorin.my.id/form/... atau kode token',
                prefixIcon: Icons.link,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (tokenCtrl.text.trim().isEmpty) return;
                      setDlgState(() => isSubmitting = true);
                      try {
                        await ref.read(coupleServiceProvider).linkDekorinAgenda(tokenCtrl.text.trim());
                        await ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
                        if (ctx.mounted) {
                          final messenger = ScaffoldMessenger.of(ctx);
                          Navigator.pop(ctx);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Booking vendor berhasil disinkronkan!',
                                style: AppTypography.bodySmall.copyWith(color: Colors.white),
                              ),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('$e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                        }
                      }
                    },
              child: Text(isSubmitting ? 'Menautkan...' : 'Tautkan', style: AppTypography.button),
            ),
          ],
        ),
      ),
    );
  }

  void _showVendorFormSheet({WeddingPlanVendorItem? existing}) {
    final isSynced = existing?.isSyncedAgenda ?? false;
    final nameCtrl = TextEditingController(text: existing?.vendorName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.vendorPhone ?? '');
    final igCtrl = TextEditingController(text: existing?.vendorInstagram ?? '');
    final pkgCtrl = TextEditingController(text: existing?.packageName ?? '');
    final priceCtrl = TextEditingController(
      text: (existing?.agreedPrice ?? 0) > 0 ? existing!.agreedPrice.toInt().toString() : '',
    );
    final dpCtrl = TextEditingController(
      text: (existing?.dpPaid ?? 0) > 0 ? existing!.dpPaid.toInt().toString() : '',
    );
    final dueCtrl = TextEditingController(text: existing?.dueDate ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    var selectedCat = existing?.vendorCategory ?? 'mua';
    var selectedStatus = existing?.paymentStatus ?? 'unpaid';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(existing == null ? 'Catat Vendor Baru' : 'Edit Catatan Vendor', style: AppTypography.titleLarge),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                if (isSynced) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      'Vendor ini tersinkron langsung dengan Agenda Dekorin. Nominal biaya & status DP mengikuti data resmi vendor.',
                      style: AppTypography.caption.copyWith(color: AppColors.textDark),
                    ),
                  ),
                ],
                if (!isSynced) ...[
                  DropdownButtonFormField<String>(
                    initialValue: VendorCategoryOption.byId(selectedCat).id,
                    decoration: InputDecoration(
                      labelText: 'Kategori Vendor',
                      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: VendorCategoryOption.all
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.label, style: AppTypography.bodyMedium)))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedCat = v ?? selectedCat),
                  ),
                  const SizedBox(height: 12),
                  DekorinTextField(controller: nameCtrl, label: 'Nama Vendor *', hint: 'Contoh: Aura MUA / Berkah Catering'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DekorinTextField(
                          controller: phoneCtrl,
                          label: 'No. WhatsApp',
                          hint: '0812...',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DekorinTextField(controller: igCtrl, label: 'Instagram', hint: '@username'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DekorinTextField(controller: pkgCtrl, label: 'Paket / Layanan', hint: 'Contoh: Paket Akad + Resepsi'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DekorinTextField(
                          controller: priceCtrl,
                          label: 'Total Deal (Rp)',
                          hint: '10000000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DekorinTextField(
                          controller: dpCtrl,
                          label: 'Sudah Dibayar / DP',
                          hint: '2000000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: ['unpaid', 'dp', 'paid', 'inquiry'].contains(selectedStatus) ? selectedStatus : 'unpaid',
                    decoration: InputDecoration(
                      labelText: 'Status Pembayaran',
                      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem(value: 'inquiry', child: Text('Masih Tanya / Wishlist', style: AppTypography.bodyMedium)),
                      DropdownMenuItem(value: 'unpaid', child: Text('Belum Bayar', style: AppTypography.bodyMedium)),
                      DropdownMenuItem(value: 'dp', child: Text('Sudah DP', style: AppTypography.bodyMedium)),
                      DropdownMenuItem(value: 'paid', child: Text('Lunas', style: AppTypography.bodyMedium)),
                    ],
                    onChanged: (v) => setSheetState(() => selectedStatus = v ?? selectedStatus),
                  ),
                  const SizedBox(height: 12),
                ],
                DekorinTextField(controller: dueCtrl, label: 'Jatuh Tempo Pelunasan', hint: 'Contoh: 2026-06-15'),
                const SizedBox(height: 12),
                DekorinTextField(controller: notesCtrl, label: 'Catatan / Kesepakatan', maxLines: 2),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!isSynced && nameCtrl.text.trim().isEmpty) return;
                            setSheetState(() => isSaving = true);
                            try {
                              final price = double.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                              final dp = double.tryParse(dpCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                              final service = ref.read(coupleServiceProvider);
                              if (existing == null) {
                                await service.addManualVendor(
                                  category: selectedCat,
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  instagram: igCtrl.text.trim(),
                                  packageName: pkgCtrl.text.trim(),
                                  agreedPrice: price,
                                  dpPaid: dp,
                                  paymentStatus: selectedStatus,
                                  dueDate: dueCtrl.text.trim(),
                                  notes: notesCtrl.text.trim(),
                                );
                              } else {
                                await service.updateVendor(
                                  existing.id,
                                  category: selectedCat,
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  instagram: igCtrl.text.trim(),
                                  packageName: pkgCtrl.text.trim(),
                                  agreedPrice: price,
                                  dpPaid: dp,
                                  paymentStatus: selectedStatus,
                                  dueDate: dueCtrl.text.trim(),
                                  notes: notesCtrl.text.trim(),
                                );
                              }
                              await ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal: $e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                );
                              }
                            }
                          },
                    child: Text(isSaving ? 'Menyimpan...' : 'Simpan Vendor', style: AppTypography.button),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteVendor(WeddingPlanVendorItem vendor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Vendor?', style: AppTypography.titleLarge),
        content: Text(
          'Hapus "${vendor.vendorName}" dari daftar Wedding Plan Anda?',
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
            child: Text('Hapus', style: AppTypography.button),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(coupleServiceProvider).deleteVendor(vendor.id);
      await ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(coupleWorkspaceProvider);
    final detail = workspace.planDetail;
    final vendors = workspace.vendors;

    final filtered = _selectedCategory == 'all'
        ? vendors
        : vendors.where((v) => v.vendorCategory == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Vendor & Budget', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cari Vendor Publik',
            icon: const Icon(Icons.search_rounded, color: AppColors.primaryGold),
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const VendorDirectoryView()),
              );
              if (changed == true) {
                ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGold,
        onPressed: _showAddOptionsSheet,
        icon: const Icon(Icons.add_business_outlined, color: Colors.white),
        label: Text('Tambah Vendor', style: AppTypography.button),
      ),
      body: workspace.isLoading && detail == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
          : RefreshIndicator(
              color: AppColors.primaryGold,
              onRefresh: () => ref.read(coupleWorkspaceProvider.notifier).refreshAll(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  if (detail != null) ...[
                    _buildBudgetSummaryCard(detail.plan, detail.stats),
                    const SizedBox(height: 14),
                  ],
                  _buildDirectoryBanner(),
                  const SizedBox(height: 16),
                  _buildCategoryFilterRow(),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.store_mall_directory_outlined, size: 42, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          Text('Belum ada vendor terdaftar', style: AppTypography.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Cari vendor di Direktori Dekorin, tautkan link form vendor, atau catat vendor secara manual.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map(_buildVendorCard),
                ],
              ),
            ),
    );
  }

  Widget _buildBudgetSummaryCard(WeddingPlan plan, WeddingPlanSummaryStats stats) {
    final target = plan.budgetTarget;
    final used = stats.totalAgreedCost;
    final ratio = target > 0 ? (used / target).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = target > 0 && used > target;

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RINGKASAN BUDGET PERNIKAHAN', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
              if (target > 0)
                Text(
                  'Target: ${formatCoupleRupiah(target)}',
                  style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCoupleRupiah(used),
            style: AppTypography.h2.copyWith(color: isOverBudget ? AppColors.errorRed : AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            isOverBudget
                ? 'Melebihi target sebesar ${formatCoupleRupiah(used - target)}'
                : target > 0
                    ? 'Sisa alokasi budget: ${formatCoupleRupiah(target - used)}'
                    : 'Atur target budget di tab Planner untuk memantau batas anggaran',
            style: AppTypography.caption.copyWith(color: isOverBudget ? AppColors.errorRed : AppColors.textLight),
          ),
          if (target > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.goldLight,
                valueColor: AlwaysStoppedAnimation<Color>(isOverBudget ? AppColors.errorRed : AppColors.primaryGold),
              ),
            ),
          ],
          const Divider(height: 22, color: AppColors.dividerColor),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sudah Dibayar (DP)', style: AppTypography.caption),
                    const SizedBox(height: 2),
                    Text(
                      formatCoupleRupiah(stats.totalDpPaid),
                      style: AppTypography.titleSmall.copyWith(color: AppColors.successGreen),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sisa Pelunasan', style: AppTypography.caption),
                    const SizedBox(height: 2),
                    Text(
                      formatCoupleRupiah(stats.remainingVendorBalance),
                      style: AppTypography.titleSmall.copyWith(color: AppColors.warningAmber),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryBanner() {
    return Material(
      color: AppColors.goldLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const VendorDirectoryView()),
          );
          if (changed == true) {
            ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.explore_outlined, color: AppColors.primaryGold, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jelajahi Direktori Vendor', style: AppTypography.titleSmall),
                    Text('Temukan vendor Dekorasi, WO, MUA, Foto & Katering', style: AppTypography.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primaryGold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterRow() {
    final options = [
      const MapEntry('all', 'Semua'),
      ...VendorCategoryOption.all.map((c) => MapEntry(c.id, c.shortLabel)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final selected = _selectedCategory == opt.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                opt.value,
                style: AppTypography.labelMedium.copyWith(color: selected ? Colors.white : AppColors.textDark),
              ),
              selected: selected,
              selectedColor: AppColors.primaryGold,
              backgroundColor: Colors.white,
              onSelected: (_) => setState(() => _selectedCategory = opt.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVendorCard(WeddingPlanVendorItem vendor) {
    final catLabel = VendorCategoryOption.byId(vendor.vendorCategory).shortLabel;
    final statusBadge = switch (vendor.paymentStatus) {
      'paid' => ('Lunas', AppColors.successGreen),
      'dp' => ('Sudah DP', AppColors.warningAmber),
      'inquiry' => ('Wishlist / Inquiry', AppColors.infoBlue),
      _ => ('Belum Bayar', AppColors.errorRed),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  catLabel,
                  style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              if (vendor.isSyncedAgenda)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sync Dekorin',
                    style: AppTypography.caption.copyWith(color: AppColors.successGreen, fontWeight: FontWeight.w600),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBadge.$2.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusBadge.$1,
                  style: AppTypography.caption.copyWith(color: statusBadge.$2, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(vendor.vendorName, style: AppTypography.titleMedium),
          if (vendor.packageName.isNotEmpty || vendor.modelName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              [vendor.packageName, vendor.modelName].where((e) => e.isNotEmpty).join(' • '),
              style: AppTypography.bodySmall.copyWith(color: AppColors.textDark),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Biaya', style: AppTypography.caption),
                      Text(formatCoupleRupiah(vendor.agreedPrice), style: AppTypography.titleSmall),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DP Masuk', style: AppTypography.caption),
                      Text(
                        formatCoupleRupiah(vendor.dpPaid),
                        style: AppTypography.titleSmall.copyWith(color: AppColors.successGreen),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sisa', style: AppTypography.caption),
                      Text(
                        formatCoupleRupiah(vendor.remainingBalance),
                        style: AppTypography.titleSmall.copyWith(color: AppColors.warningAmber),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (vendor.notes.isNotEmpty || vendor.dueDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (vendor.dueDate.isNotEmpty) 'Jatuh tempo: ${vendor.dueDate}',
                if (vendor.notes.isNotEmpty) vendor.notes,
              ].join(' • '),
              style: AppTypography.caption,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (vendor.vendorPhone.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _openWhatsApp(vendor.vendorPhone, vendor.vendorName),
                  icon: SvgPicture.asset('assets/icons/wa.svg', width: 16, height: 16),
                  label: Text('Chat WA', style: AppTypography.labelMedium.copyWith(color: AppColors.successGreen)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.successGreen.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Edit',
                icon: SvgPicture.asset(
                  'assets/icons/edit.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                ),
                onPressed: () => _showVendorFormSheet(existing: vendor),
              ),
              IconButton(
                tooltip: 'Hapus',
                icon: const Icon(Icons.delete_outline, color: AppColors.errorRed, size: 20),
                onPressed: () => _confirmDeleteVendor(vendor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
