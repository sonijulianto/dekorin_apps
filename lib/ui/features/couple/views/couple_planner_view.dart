import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/couple_service.dart';
import 'package:dekorin_apps/domain/models/wedding_plan.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/couple/view_models/couple_plan_provider.dart';

/// Tab utama Planner untuk Calon Pengantin: Countdown, Info Acara, Ringkasan Budget/RSVP, & Checklist Tugas.
class CouplePlannerView extends ConsumerStatefulWidget {
  const CouplePlannerView({super.key, this.onNavigateToTab});

  final void Function(int tabIndex)? onNavigateToTab;

  @override
  ConsumerState<CouplePlannerView> createState() => _CouplePlannerViewState();
}

class _CouplePlannerViewState extends ConsumerState<CouplePlannerView> {
  String _taskFilter = 'all'; // all, pending, completed

  Future<void> _openMapsUrl(String mapsUrl) async {
    final trimmed = mapsUrl.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showEditPlanSheet(WeddingPlan plan) {
    final titleCtrl = TextEditingController(text: plan.title);
    final groomCtrl = TextEditingController(text: plan.groomName);
    final brideCtrl = TextEditingController(text: plan.brideName);
    final dateCtrl = TextEditingController(text: plan.weddingDate);
    final akadCtrl = TextEditingController(text: plan.akadTime);
    final resepsiCtrl = TextEditingController(text: plan.resepsiTime);
    final cityCtrl = TextEditingController(text: plan.city);
    final venueCtrl = TextEditingController(text: plan.venueName);
    final addressCtrl = TextEditingController(text: plan.venueAddress);
    final mapsCtrl = TextEditingController(text: plan.mapsUrl);
    final budgetCtrl = TextEditingController(
      text: plan.budgetTarget > 0 ? plan.budgetTarget.toInt().toString() : '',
    );
    final notesCtrl = TextEditingController(text: plan.notes);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Atur Rencana Pernikahan', style: AppTypography.titleLarge),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DekorinTextField(controller: titleCtrl, label: 'Judul Acara', hint: 'Pernikahan Bagas & Zulia'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DekorinTextField(controller: groomCtrl, label: 'Mempelai Pria', hint: 'Nama pria'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DekorinTextField(controller: brideCtrl, label: 'Mempelai Wanita', hint: 'Nama wanita'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final initial = DateTime.tryParse(dateCtrl.text) ?? now.add(const Duration(days: 60));
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: initial,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            dateCtrl.text =
                                '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: DekorinTextField(
                          controller: dateCtrl,
                          label: 'Tanggal Acara (YYYY-MM-DD)',
                          hint: 'Pilih tanggal acara',
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DekorinTextField(controller: akadCtrl, label: 'Jam Akad', hint: '08:00 - 10:00 WIB'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DekorinTextField(controller: resepsiCtrl, label: 'Jam Resepsi', hint: '11:00 - 14:00 WIB'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DekorinTextField(controller: cityCtrl, label: 'Kota', hint: 'Jakarta Selatan'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DekorinTextField(
                            controller: budgetCtrl,
                            label: 'Target Budget (Rp)',
                            hint: '50000000',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DekorinTextField(controller: venueCtrl, label: 'Nama Gedung / Venue', hint: 'Gedung Serbaguna Melati'),
                    const SizedBox(height: 12),
                    DekorinTextField(controller: addressCtrl, label: 'Alamat Lengkap Venue', maxLines: 2),
                    const SizedBox(height: 12),
                    DekorinTextField(
                      controller: mapsCtrl,
                      label: 'Link Google Maps Lokasi',
                      hint: 'https://maps.google.com/...',
                      prefixWidget: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset('assets/icons/google-maps-icon.webp', width: 22, height: 22),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DekorinTextField(controller: notesCtrl, label: 'Catatan Konsep / Tema', maxLines: 2),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setSheetState(() => isSaving = true);
                                try {
                                  final budget = double.tryParse(
                                        budgetCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                                      ) ??
                                      0;
                                  await ref.read(coupleServiceProvider).updateMyPlan(
                                        title: titleCtrl.text.trim(),
                                        groomName: groomCtrl.text.trim(),
                                        brideName: brideCtrl.text.trim(),
                                        weddingDate: dateCtrl.text.trim(),
                                        akadTime: akadCtrl.text.trim(),
                                        resepsiTime: resepsiCtrl.text.trim(),
                                        city: cityCtrl.text.trim(),
                                        venueName: venueCtrl.text.trim(),
                                        venueAddress: addressCtrl.text.trim(),
                                        mapsUrl: mapsCtrl.text.trim(),
                                        budgetTarget: budget,
                                        notes: notesCtrl.text.trim(),
                                      );
                                  await ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menyimpan: $e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Text(isSaving ? 'Menyimpan...' : 'Simpan Rencana', style: AppTypography.button),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPartnerShareDialog(WeddingPlan plan, List<WeddingPlanMemberSummary> members) {
    final joinInputCtrl = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Kolaborasi Pasangan', style: AppTypography.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bagikan kode berikut agar pasangan Anda bisa mengakses & mengatur Wedding Plan ini bersama:',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryGold),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan.joinCode,
                        style: AppTypography.h3.copyWith(color: AppColors.primaryDark, letterSpacing: 2),
                      ),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/copy-alt.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: plan.joinCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Kode gabung ${plan.joinCode} disalin',
                                style: AppTypography.bodySmall.copyWith(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (members.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Anggota Terhubung:', style: AppTypography.labelMedium),
                  const SizedBox(height: 6),
                  ...members.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 15, color: AppColors.successGreen),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('${m.fullName} (${m.phone})', style: AppTypography.bodySmall.copyWith(color: AppColors.textDark)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Divider(height: 24),
                Text('Atau gabung ke Wedding Plan pasangan:', style: AppTypography.labelMedium),
                const SizedBox(height: 8),
                DekorinTextField(
                  controller: joinInputCtrl,
                  hint: 'Masukkan 8 karakter kode pasangan',
                  prefixIcon: Icons.vpn_key_outlined,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tutup', style: AppTypography.labelLarge.copyWith(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: isJoining
                  ? null
                  : () async {
                      final code = joinInputCtrl.text.trim();
                      if (code.isEmpty) return;
                      setDlgState(() => isJoining = true);
                      try {
                        await ref.read(coupleServiceProvider).joinPlanByCode(code);
                        await ref.read(coupleWorkspaceProvider.notifier).refreshAll(silent: true);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setDlgState(() => isJoining = false);
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
              child: Text(isJoining ? 'Memproses...' : 'Gabung Plan', style: AppTypography.button),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedCategory = 'Venue & Dekorasi';
    String selectedPhase = 'H-3 Bulan';
    bool isSaving = false;

    const categories = [
      'Administrasi & KUA',
      'Venue & Dekorasi',
      'Busana & MUA',
      'Katering & Suvenir',
      'Dokumentasi',
      'Undangan & Tamu',
      'Lainnya',
    ];
    const phases = ['H-6 Bulan', 'H-3 Bulan', 'H-1 Bulan', 'H-7', 'Hari-H'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tambah Tugas Checklist', style: AppTypography.titleLarge),
              const SizedBox(height: 14),
              DekorinTextField(controller: titleCtrl, label: 'Nama Tugas *', hint: 'Contoh: Fitting kebaya akad'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTypography.bodyMedium)))
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedCategory = v ?? selectedCategory),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPhase,
                decoration: InputDecoration(
                  labelText: 'Tahap / Timeline',
                  labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: phases
                    .map((p) => DropdownMenuItem(value: p, child: Text(p, style: AppTypography.bodyMedium)))
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedPhase = v ?? selectedPhase),
              ),
              const SizedBox(height: 12),
              DekorinTextField(controller: notesCtrl, label: 'Catatan (Opsional)', maxLines: 2),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          setSheetState(() => isSaving = true);
                          try {
                            await ref.read(coupleWorkspaceProvider.notifier).addTask(
                                  title: titleCtrl.text.trim(),
                                  category: selectedCategory,
                                  phase: selectedPhase,
                                  notes: notesCtrl.text.trim(),
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (_) {
                            setSheetState(() => isSaving = false);
                          }
                        },
                  child: Text(isSaving ? 'Menambahkan...' : 'Simpan Tugas', style: AppTypography.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(coupleWorkspaceProvider);
    final detail = workspace.planDetail;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Wedding Planner', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (detail != null)
            IconButton(
              tooltip: 'Bagikan ke Pasangan',
              icon: const Icon(Icons.group_add_outlined, color: AppColors.primaryGold),
              onPressed: () => _showPartnerShareDialog(detail.plan, detail.members),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGold,
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: Text('Tambah Checklist', style: AppTypography.button),
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
                    _buildCountdownHeader(detail),
                    const SizedBox(height: 16),
                    _buildQuickSummaryGrid(detail.stats, detail.plan),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CHECKLIST PERSIAPAN', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.7)),
                      if (detail != null)
                        Text(
                          '${detail.stats.completedTasks}/${detail.stats.totalTasks} selesai',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.primaryGold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildFilterChips(),
                  const SizedBox(height: 10),
                  _buildChecklistSection(workspace.tasks),
                ],
              ),
            ),
    );
  }

  Widget _buildCountdownHeader(WeddingPlanDetail detail) {
    final plan = detail.plan;
    final days = detail.stats.daysRemaining;
    final countdownBadge = days == null
        ? 'Tanggal belum diatur'
        : days > 0
            ? 'H-$days Hari Lagi'
            : days == 0
                ? 'Hari Bahagia Tiba!'
                : 'Acara Selesai (${days.abs()} hari lalu)';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF563B13), Color(0xFF9C7238), Color(0xFFC59563)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4E350E).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  countdownBadge,
                  style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showEditPlanSheet(plan),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/edit.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 4),
                      Text('Atur Acara', style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            plan.title.isNotEmpty ? plan.title : 'Rencana Pernikahan Anda',
            style: AppTypography.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/calendar.svg',
                width: 15,
                height: 15,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  plan.weddingDate.isNotEmpty
                      ? '${plan.weddingDate}${plan.akadTime.isNotEmpty ? ' • Akad ${plan.akadTime}' : ''}'
                      : 'Ketuk "Atur Acara" untuk mengisi tanggal & lokasi',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.92)),
                ),
              ),
            ],
          ),
          if (plan.venueName.isNotEmpty || plan.city.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (plan.mapsUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _openMapsUrl(plan.mapsUrl),
                    child: Image.asset('assets/icons/google-maps-icon.webp', width: 16, height: 16),
                  )
                else
                  SvgPicture.asset(
                    'assets/icons/marker.svg',
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [plan.venueName, plan.city].where((e) => e.isNotEmpty).join(' • '),
                    style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickSummaryGrid(WeddingPlanSummaryStats stats, WeddingPlan plan) {
    return Row(
      children: [
        Expanded(
          child: _SummaryMiniCard(
            title: 'Vendor & Budget',
            value: '${stats.totalVendors} Vendor',
            subtitle: stats.totalAgreedCost > 0 ? formatCoupleRupiah(stats.totalAgreedCost) : 'Belum ada biaya',
            onTap: () => widget.onNavigateToTab?.call(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryMiniCard(
            title: 'Undangan & RSVP',
            value: stats.linkedInvitationsCount > 0 ? '${stats.totalPaxHadir} Pax Hadir' : 'Belum Ditautkan',
            subtitle: stats.linkedInvitationsCount > 0
                ? '${stats.totalRsvpHadir} konfirmasi hadir'
                : 'Klaim undangan vendor',
            onTap: () => widget.onNavigateToTab?.call(2),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final items = [
      ('all', 'Semua'),
      ('pending', 'Belum Selesai'),
      ('completed', 'Selesai'),
    ];
    return Row(
      children: items.map((entry) {
        final selected = _taskFilter == entry.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(
              entry.$2,
              style: AppTypography.labelMedium.copyWith(
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
            selected: selected,
            selectedColor: AppColors.primaryGold,
            backgroundColor: Colors.white,
            onSelected: (_) => setState(() => _taskFilter = entry.$1),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChecklistSection(List<WeddingTaskItem> tasks) {
    final filtered = tasks.where((t) {
      if (_taskFilter == 'pending') return !t.isCompleted;
      if (_taskFilter == 'completed') return t.isCompleted;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            'Belum ada tugas pada filter ini.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < filtered.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.dividerColor),
            ListTile(
              leading: Checkbox(
                value: filtered[i].isCompleted,
                activeColor: AppColors.primaryGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                onChanged: (_) => ref.read(coupleWorkspaceProvider.notifier).toggleTask(filtered[i].id),
              ),
              title: Text(
                filtered[i].title,
                style: AppTypography.titleSmall.copyWith(
                  decoration: filtered[i].isCompleted ? TextDecoration.lineThrough : null,
                  color: filtered[i].isCompleted ? AppColors.textLight : AppColors.textDark,
                ),
              ),
              subtitle: Text(
                '${filtered[i].phase} • ${filtered[i].category}',
                style: AppTypography.caption,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                onPressed: () => ref.read(coupleWorkspaceProvider.notifier).deleteTask(filtered[i].id),
              ),
              onTap: () => ref.read(coupleWorkspaceProvider.notifier).toggleTask(filtered[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMiniCard extends StatelessWidget {
  const _SummaryMiniCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.caption),
              const SizedBox(height: 4),
              Text(value, style: AppTypography.titleMedium.copyWith(color: AppColors.primaryGold)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(color: AppColors.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
