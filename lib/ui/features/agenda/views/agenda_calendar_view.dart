import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_calendar_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_detail_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/create_agenda_sheet.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class AgendaCalendarView extends ConsumerWidget {
  const AgendaCalendarView({super.key});

  void _openCreateAgenda(BuildContext context, WidgetRef ref, DateTime initialDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateAgendaSheet(initialDate: initialDate),
    ).then((_) {
      ref.read(agendaCalendarViewModelProvider.notifier).refresh();
      ref.read(agendaViewModelProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(globalAuthProvider).value;
    final calendarState = ref.watch(agendaCalendarViewModelProvider);
    final calendarNotifier = ref.read(agendaCalendarViewModelProvider.notifier);

    final selectedAgendas = calendarState.selectedDateAgendas;
    final isSelectedToday = _isSameDay(calendarState.selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Kalender Agenda',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => calendarNotifier.goToToday(),
            icon: SvgPicture.asset(
              'assets/icons/calendar.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
            ),
            label: Text(
              'Hari Ini',
              style: AppTypography.button.copyWith(
                color: AppColors.primaryGold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: () => calendarNotifier.refresh(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: (user?.canCreateAgenda ?? true)
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateAgenda(context, ref, calendarState.selectedDate),
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
        children: [
          // Bagian Atas: Kalender Bulanan
          _MonthCalendarSection(
            calendarState: calendarState,
            calendarNotifier: calendarNotifier,
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // Bagian Bawah: Header Tanggal Terpilih & Daftar Agenda
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSelectedToday
                            ? 'Hari Ini'
                            : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(calendarState.selectedDate),
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (isSelectedToday)
                        Text(
                          DateFormat('d MMMM yyyy', 'id_ID').format(calendarState.selectedDate),
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedAgendas.length} Agenda',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Daftar Jadwal Agenda
          Expanded(
            child: calendarState.isLoading && selectedAgendas.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
                : RefreshIndicator(
                    onRefresh: () => calendarNotifier.refresh(),
                    color: AppTheme.primaryGold,
                    child: selectedAgendas.isEmpty
                        ? _buildEmptyState(context, ref, user?.canCreateAgenda ?? true, calendarState.selectedDate)
                        : ListView.separated(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 84),
                            itemCount: selectedAgendas.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = selectedAgendas[index];
                              return _TimelineScheduleCard(
                                item: item,
                                colorIndex: index,
                                onUpdated: () {
                                  calendarNotifier.refresh();
                                  ref.read(agendaViewModelProvider.notifier).refresh();
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool canCreate, DateTime selectedDate) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.08),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/calendar.svg',
                    width: 44,
                    height: 44,
                    colorFilter: const ColorFilter.mode(AppTheme.primaryGold, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Tidak Ada Agenda',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Belum ada acara yang terjadwal pada tanggal ini.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                ),
                if (canCreate) ...[
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => _openCreateAgenda(context, ref, selectedDate),
                    icon: const Icon(Icons.add, size: 18, color: AppColors.primaryGold),
                    label: Text(
                      'Jadwalkan Acara',
                      style: AppTypography.button.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MonthCalendarSection extends StatelessWidget {
  const _MonthCalendarSection({
    required this.calendarState,
    required this.calendarNotifier,
  });

  final AgendaCalendarState calendarState;
  final AgendaCalendarNotifier calendarNotifier;

  @override
  Widget build(BuildContext context) {
    final focusedMonth = calendarState.focusedMonth;
    final monthTitle = DateFormat('MMMM yyyy', 'id_ID').format(focusedMonth);

    // Hitung tanggal-tanggal dalam grid kalender
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final sundayOffset = firstDayOfMonth.weekday % 7; // Sunday = 0, Monday = 1, ...
    final gridStartDate = firstDayOfMonth.subtract(Duration(days: sundayOffset));

    final totalGridCells = (sundayOffset + daysInMonth <= 35) ? 35 : 42;
    final gridDays = List<DateTime>.generate(
      totalGridCells,
      (index) => gridStartDate.add(Duration(days: index)),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Header: Nama Bulan & Tombol Navigasi Prev/Next
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthTitle,
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppColors.textDark, size: 24),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Bulan Sebelumnya',
                    onPressed: () => calendarNotifier.previousMonth(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.textDark, size: 24),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Bulan Berikutnya',
                    onPressed: () => calendarNotifier.nextMonth(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Header Hari: S M T W T F S (Min Sen Sel Rab Kam Jum Sab)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayHeaderCell(label: 'S'),
              _WeekdayHeaderCell(label: 'M'),
              _WeekdayHeaderCell(label: 'T'),
              _WeekdayHeaderCell(label: 'W'),
              _WeekdayHeaderCell(label: 'T'),
              _WeekdayHeaderCell(label: 'F'),
              _WeekdayHeaderCell(label: 'S'),
            ],
          ),
          const SizedBox(height: 6),

          // Grid Tanggal
          Table(
            children: List<TableRow>.generate(
              totalGridCells ~/ 7,
              (rowIndex) {
                return TableRow(
                  children: List<Widget>.generate(7, (colIndex) {
                    final dayIndex = rowIndex * 7 + colIndex;
                    final dayDate = gridDays[dayIndex];
                    final isCurrentMonth = dayDate.month == focusedMonth.month;
                    final isSelected = AgendaCalendarView._isSameDay(dayDate, calendarState.selectedDate);
                    final isToday = AgendaCalendarView._isSameDay(dayDate, DateTime.now());
                    final dayAgendas = calendarState.agendasForDate(dayDate);

                    return _DayCalendarCell(
                      date: dayDate,
                      isCurrentMonth: isCurrentMonth,
                      isSelected: isSelected,
                      isToday: isToday,
                      agendaCount: dayAgendas.length,
                      onTap: () => calendarNotifier.selectDate(dayDate),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeaderCell extends StatelessWidget {
  const _WeekdayHeaderCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DayCalendarCell extends StatelessWidget {
  const _DayCalendarCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.agendaCount,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final int agendaCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (!isCurrentMonth) {
      textColor = Colors.grey.shade400;
    } else if (isToday) {
      textColor = AppColors.primaryGold;
    } else {
      textColor = AppColors.textDark;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lingkaran Tanggal
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.textDark
                    : (isToday && !isSelected ? AppColors.goldLight : Colors.transparent),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primaryGold, width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 2),

            // Penanda & Jumlah Agenda (Jika ada agenda pada tanggal ini)
            if (agendaCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.primaryGold.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 2.5),
                    Text(
                      '$agendaCount',
                      style: AppTypography.caption.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 13), // Ruang tetap agar grid kalender stabil
          ],
        ),
      ),
    );
  }
}

class _TimelineScheduleCard extends StatelessWidget {
  const _TimelineScheduleCard({
    required this.item,
    required this.colorIndex,
    required this.onUpdated,
  });

  final AgendaItem item;
  final int colorIndex;
  final VoidCallback onUpdated;

  // Palet warna estetik seperti pada referensi desain (Soft Blue, Soft Beige, Sage Green, Terracotta, Soft Lavender)
  static const List<_CardColorScheme> _colorPalette = [
    _CardColorScheme(
      background: Color(0xFF7BA8D4),
      textPrimary: Colors.white,
      badgeBackground: Color(0xFF628FB8),
    ),
    _CardColorScheme(
      background: Color(0xFFFBE4BA),
      textPrimary: Color(0xFF2C2C2C),
      badgeBackground: Color(0xFFE2CAA0),
    ),
    _CardColorScheme(
      background: Color(0xFF8EB69B),
      textPrimary: Colors.white,
      badgeBackground: Color(0xFF749C81),
    ),
    _CardColorScheme(
      background: Color(0xFFE5A99C),
      textPrimary: Colors.white,
      badgeBackground: Color(0xFFC98E81),
    ),
    _CardColorScheme(
      background: Color(0xFFA5A4D4),
      textPrimary: Colors.white,
      badgeBackground: Color(0xFF8B8ABA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _colorPalette[colorIndex % _colorPalette.length];
    final timeFormat = DateFormat('HH:mm', 'id_ID');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kolom Jam di sebelah kiri
        SizedBox(
          width: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeFormat.format(item.eventDateTime),
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
              ),
              Text(
                'WIB',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Kartu Agenda di sebelah kanan
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AgendaDetailView(item: item)),
              ).then((_) => onUpdated());
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Header: Waktu Acara & Badge Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.badgeBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${timeFormat.format(item.eventDateTime)} WIB',
                          style: AppTypography.labelMedium.copyWith(
                            color: colors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.badgeBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusText(item.status),
                          style: AppTypography.caption.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Judul Backdrop / Acara
                  Text(
                    item.backdropTitle.isNotEmpty ? item.backdropTitle : item.clientName,
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Nama Klien & Paket Dekorasi
                  Text(
                    '${item.clientName} • ${item.packageName.isNotEmpty ? item.packageName : 'Paket Custom'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textPrimary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Alamat Lokasi Acara jika ada
                  if (item.displayAddress.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/marker.svg',
                          width: 12,
                          height: 12,
                          colorFilter: ColorFilter.mode(
                            colors.textPrimary.withValues(alpha: 0.8),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.displayAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: colors.textPrimary.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Batal';
      case 'upcoming':
      default:
        return 'Mendatang';
    }
  }
}

class _CardColorScheme {
  const _CardColorScheme({
    required this.background,
    required this.textPrimary,
    required this.badgeBackground,
  });

  final Color background;
  final Color textPrimary;
  final Color badgeBackground;
}
