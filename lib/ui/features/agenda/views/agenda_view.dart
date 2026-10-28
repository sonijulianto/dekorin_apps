import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_detail_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/create_agenda_sheet.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class AgendaView extends ConsumerWidget {
  const AgendaView({super.key});

  void _openCreateAgenda(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateAgendaSheet(),
    );
  }

  Future<void> _pickCustomDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGold,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      ref
          .read(agendaViewModelProvider.notifier)
          .setFilter(AgendaDateFilterType.customRange, start: pickedRange.start, end: pickedRange.end);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(globalAuthProvider).value;
    final agendaState = ref.watch(agendaViewModelProvider);
    final filterState = ref.watch(agendaFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Agenda Dekorasi',
          style: AppTypography.titleLarge.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: (user?.canCreateAgenda ?? true)
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateAgenda(context),
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task),
              label: Text(
                'Buat Agenda',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter section
          _buildFilterBar(context, ref, filterState),

          // Active filter indicator
          _buildActiveFilterInfo(context, ref, filterState),

          // Content list
          Expanded(
            child: agendaState.when(
              data: (data) {
                if (data.agendas.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(agendaViewModelProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: 80, // Ruang untuk FAB
                    ),
                    itemCount: data.agendas.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = data.agendas[index];
                      return _AgendaCard(item: item);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat agenda:\n$error',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(agendaViewModelProvider.notifier).refresh(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                        child: Text('Coba Lagi', style: AppTypography.button),
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

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, AgendaFilterState filterState) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _FilterChip(
              label: 'Semua',
              icon: Icons.calendar_view_week,
              isSelected: filterState.filterType == AgendaDateFilterType.all,
              onTap: () {
                ref.read(agendaViewModelProvider.notifier).setFilter(AgendaDateFilterType.all);
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Hari Ini',
              icon: Icons.today,
              isSelected: filterState.filterType == AgendaDateFilterType.today,
              onTap: () {
                ref.read(agendaViewModelProvider.notifier).setFilter(AgendaDateFilterType.today);
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Minggu Ini',
              icon: Icons.view_week_outlined,
              isSelected: filterState.filterType == AgendaDateFilterType.thisWeek,
              onTap: () {
                ref.read(agendaViewModelProvider.notifier).setFilter(AgendaDateFilterType.thisWeek);
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Bulan Ini',
              iconWidget: SvgPicture.asset(
                'assets/icons/calendar.svg',
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  filterState.filterType == AgendaDateFilterType.thisMonth ? Colors.white : AppTheme.textDark,
                  BlendMode.srcIn,
                ),
              ),
              isSelected: filterState.filterType == AgendaDateFilterType.thisMonth,
              onTap: () {
                ref.read(agendaViewModelProvider.notifier).setFilter(AgendaDateFilterType.thisMonth);
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: filterState.filterType == AgendaDateFilterType.customRange ? 'Kustom Tanggal ✓' : 'Pilih Tanggal',
              iconWidget: SvgPicture.asset(
                'assets/icons/calendar.svg',
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  filterState.filterType == AgendaDateFilterType.customRange ? Colors.white : AppTheme.textDark,
                  BlendMode.srcIn,
                ),
              ),
              isSelected: filterState.filterType == AgendaDateFilterType.customRange,
              onTap: () => _pickCustomDateRange(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterInfo(BuildContext context, WidgetRef ref, AgendaFilterState filterState) {
    String description = 'Menampilkan seluruh agenda mendatang';
    if (filterState.filterType == AgendaDateFilterType.today) {
      description = 'Agenda hari ini: ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}';
    } else if (filterState.filterType == AgendaDateFilterType.thisWeek) {
      description = 'Agenda dalam 7 hari ke depan';
    } else if (filterState.filterType == AgendaDateFilterType.thisMonth) {
      description = 'Agenda bulan ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}';
    } else if (filterState.filterType == AgendaDateFilterType.customRange &&
        filterState.customStartDate != null &&
        filterState.customEndDate != null) {
      final df = DateFormat('dd MMM yyyy', 'id_ID');
      description = 'Rentang: ${df.format(filterState.customStartDate!)} - ${df.format(filterState.customEndDate!)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.backgroundLight,
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: AppTypography.labelMedium.copyWith(
                fontSize: 12,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (filterState.filterType != AgendaDateFilterType.all)
            GestureDetector(
              onTap: () {
                ref.read(agendaViewModelProvider.notifier).setFilter(AgendaDateFilterType.all);
              },
              child: Text(
                'Reset',
                style: AppTypography.labelMedium.copyWith(
                  fontSize: 12,
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.primaryGold.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: SvgPicture.asset(
                'assets/icons/calendar.svg',
                width: 64,
                height: 64,
                colorFilter: const ColorFilter.mode(AppTheme.primaryGold, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Agenda',
              style: AppTypography.titleLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada agenda pada periode ini.\nKlik tombol "Buat Agenda" untuk menambahkan acara.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: AppTheme.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    this.iconWidget,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGold : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget ?? Icon(icon!, size: 16, color: isSelected ? Colors.white : AppTheme.textDark),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({required this.item});

  final AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaDetailView(item: item)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppTheme.primaryGold, width: 4)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.brandName.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            item.brandName,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryGold,
                            ),
                          ),
                        ),
                      ],
                      // Nama yang booking & Nomor HP di sampingnya
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.clientName,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.clientPhone.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${item.clientPhone}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Tanggal
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/calendar.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(AppTheme.primaryGold, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateFormat.format(item.eventDateTime),
                              style: AppTypography.bodySmall.copyWith(color: AppTheme.textDark),
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textLight,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
