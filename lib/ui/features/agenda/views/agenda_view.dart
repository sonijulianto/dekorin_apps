import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/views/create_agenda_sheet.dart';

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
      ref.read(agendaViewModelProvider.notifier).setFilter(
            AgendaDateFilterType.customRange,
            start: pickedRange.start,
            end: pickedRange.end,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaViewModelProvider);
    final filterState = ref.watch(agendaFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agenda Dekorasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () =>
                ref.read(agendaViewModelProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateAgenda(context),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text(
          'Buat Agenda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
                  onRefresh: () =>
                      ref.read(agendaViewModelProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: 80, // Ruang untuk FAB
                    ),
                    itemCount: data.agendas.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = data.agendas[index];
                      return _AgendaCard(item: item);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGold),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppTheme.errorRed),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat agenda:\n$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(agendaViewModelProvider.notifier)
                            .refresh(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                        ),
                        child: const Text('Coba Lagi'),
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

  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    AgendaFilterState filterState,
  ) {
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
              isSelected:
                  filterState.filterType == AgendaDateFilterType.all,
              onTap: () {
                ref
                    .read(agendaViewModelProvider.notifier)
                    .setFilter(AgendaDateFilterType.all);
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Hari Ini',
              icon: Icons.today,
              isSelected:
                  filterState.filterType == AgendaDateFilterType.today,
              onTap: () {
                ref
                    .read(agendaViewModelProvider.notifier)
                    .setFilter(AgendaDateFilterType.today);
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Minggu Ini',
              icon: Icons.view_week_outlined,
              isSelected:
                  filterState.filterType == AgendaDateFilterType.thisWeek,
              onTap: () {
                ref
                    .read(agendaViewModelProvider.notifier)
                    .setFilter(AgendaDateFilterType.thisWeek);
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Bulan Ini',
              icon: Icons.calendar_month,
              isSelected:
                  filterState.filterType == AgendaDateFilterType.thisMonth,
              onTap: () {
                ref
                    .read(agendaViewModelProvider.notifier)
                    .setFilter(AgendaDateFilterType.thisMonth);
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: filterState.filterType == AgendaDateFilterType.customRange
                  ? 'Kustom Tanggal ✓'
                  : 'Pilih Tanggal',
              icon: Icons.date_range,
              isSelected: filterState.filterType ==
                  AgendaDateFilterType.customRange,
              onTap: () => _pickCustomDateRange(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterInfo(
    BuildContext context,
    WidgetRef ref,
    AgendaFilterState filterState,
  ) {
    String description = 'Menampilkan seluruh agenda mendatang';
    if (filterState.filterType == AgendaDateFilterType.today) {
      description =
          'Agenda hari ini: ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}';
    } else if (filterState.filterType == AgendaDateFilterType.thisWeek) {
      description = 'Agenda dalam 7 hari ke depan';
    } else if (filterState.filterType == AgendaDateFilterType.thisMonth) {
      description =
          'Agenda bulan ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}';
    } else if (filterState.filterType == AgendaDateFilterType.customRange &&
        filterState.customStartDate != null &&
        filterState.customEndDate != null) {
      final df = DateFormat('dd MMM yyyy', 'id_ID');
      description =
          'Rentang: ${df.format(filterState.customStartDate!)} - ${df.format(filterState.customEndDate!)}';
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
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (filterState.filterType != AgendaDateFilterType.all)
            GestureDetector(
              onTap: () {
                ref
                    .read(agendaViewModelProvider.notifier)
                    .setFilter(AgendaDateFilterType.all);
              },
              child: const Text(
                'Reset',
                style: TextStyle(
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
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy,
                size: 64,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Agenda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Belum ada agenda pada periode ini.\nKlik tombol "Buat Agenda" untuk menambahkan acara.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textLight),
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
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
            color: isSelected
                ? AppTheme.primaryGold
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryGold
                  : Colors.grey.shade300,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
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
    final dateFormat = DateFormat('EEEE, dd MMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm', 'id_ID');

    return Container(
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
            border: Border(
              left: BorderSide(
                color: AppTheme.primaryGold,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Client Name & Package Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.backdropTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.packageName.isNotEmpty
                          ? item.packageName
                          : 'Paket Custom',
                      style: const TextStyle(
                        color: AppTheme.primaryGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Date & Time
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 16, color: AppTheme.textLight),
                  const SizedBox(width: 8),
                  Text(
                    '${dateFormat.format(item.eventDateTime)} • ${timeFormat.format(item.eventDateTime)} WIB',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),

              // Maps URL
              if (item.mapsUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.mapsUrl,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Notes if any
              if (item.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes,
                        size: 16, color: AppTheme.textLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.notes,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

