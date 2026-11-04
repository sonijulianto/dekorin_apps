import 'package:flutter/material.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/domain/models/dashboard_filter.dart';

/// Modal bottom sheet untuk memilih bulan dan tahun pada filter dashboard.
class MonthYearPickerSheet extends StatefulWidget {
  const MonthYearPickerSheet({
    super.key,
    required this.initialFilter,
    required this.onSelect,
  });

  final DashboardFilter initialFilter;
  final ValueChanged<DashboardFilter> onSelect;

  static Future<void> show(
    BuildContext context, {
    required DashboardFilter initialFilter,
    required ValueChanged<DashboardFilter> onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MonthYearPickerSheet(
        initialFilter: initialFilter,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<MonthYearPickerSheet> {
  late int _selectedYear;
  late int _selectedMonth;

  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialFilter.year;
    _selectedMonth = widget.initialFilter.month;
  }

  @override
  Widget build(BuildContext context) {
    final isMonthFilter = widget.initialFilter.type == DashboardPeriodType.month;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDD7CE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMonthFilter ? 'Pilih Bulan & Tahun' : 'Pilih Tahun',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Material(
                    color: const Color(0xFFF4ECE2),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF5D4A3A)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (isMonthFilter) ...[
                // Year Selector Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F5F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEFE8DE)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textDark),
                        onPressed: () => setState(() => _selectedYear--),
                      ),
                      Text(
                        'Tahun $_selectedYear',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textDark),
                        onPressed: () => setState(() => _selectedYear++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 12 Months Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    final monthNumber = index + 1;
                    final isCurrent = monthNumber == _selectedMonth && _selectedYear == widget.initialFilter.year;

                    return Material(
                      color: isCurrent ? AppColors.primaryGold : const Color(0xFFF7F4EF),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          widget.onSelect(
                            widget.initialFilter.copyWith(
                              month: monthNumber,
                              year: _selectedYear,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Text(
                            _shortMonths[index],
                            style: AppTypography.caption.copyWith(
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                              color: isCurrent ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                // Years Grid (7 years range)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 8,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final year = DateTime.now().year - 3 + index;
                    final isCurrent = year == _selectedYear;

                    return Material(
                      color: isCurrent ? AppColors.primaryGold : const Color(0xFFF7F4EF),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          widget.onSelect(
                            widget.initialFilter.copyWith(year: year),
                          );
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Text(
                            year.toString(),
                            style: AppTypography.caption.copyWith(
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                              color: isCurrent ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
