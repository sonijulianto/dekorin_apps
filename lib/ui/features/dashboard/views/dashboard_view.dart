import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/expense_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/dashboard_summary.dart';
import 'package:dekorin_apps/domain/models/expense.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';
import 'package:dekorin_apps/ui/core/widgets/shimmer_loading.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_detail_view.dart' hide ThousandsSeparatorInputFormatter;
import 'package:dekorin_apps/domain/models/dashboard_filter.dart';
import 'package:dekorin_apps/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:dekorin_apps/ui/features/dashboard/views/ai_assistant_view.dart';
import 'package:dekorin_apps/ui/features/dashboard/widgets/expense_detail_bottom_sheet.dart';
import 'package:dekorin_apps/ui/features/dashboard/widgets/month_year_picker_sheet.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  static const Color _bgCream = Color(0xFFF7F4EF);
  static const Color _bronzeDark = Color(0xFF5C3D1E);
  static const Color _bronzeDeep = Color(0xFF4F3317);
  static const Color _goldHighlight = Color(0xFFB3854B);
  static const Color _goldMid = Color(0xFF8F6431);
  static const Color _greetingBrown = Color(0xFF6B4628);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final user = ref.watch(globalAuthProvider).value;

    return Scaffold(
      backgroundColor: _bgCream,
      floatingActionButton: _buildGradientFab(context, ref),
      body: SafeArea(
        child: dashboardState.when(
          data: (data) => RefreshIndicator(
            color: AppColors.primaryGold,
            onRefresh: () => ref.read(dashboardViewModelProvider.notifier).refresh(showNominalsShimmer: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 12, bottom: 96),
              children: [
                // 1. Header Profil & Notifikasi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildHeader(context, ref, user, data.summary.upcomingAgendas),
                ),
                const SizedBox(height: 18),

                // 2. Hero Card Keuntungan, Pendapatan, Pengeluaran & Agenda
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildHeroSummaryCard(
                    context,
                    ref,
                    data.summary,
                    data.filter,
                    isNominalsLoading: data.isNominalsLoading,
                  ),
                ),
                const SizedBox(height: 18),

                // 2b. Banner Asisten Dekorin AI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildAIAssistantBanner(context),
                ),
                const SizedBox(height: 26),

                // 3. Section Booking Mendatang (Horizontal Carousel)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Booking Mendatang',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${data.summary.upcomingBookingsCount} Event',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _goldMid,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildUpcomingAgendasCarousel(context, ref, data.summary.upcomingAgendas),
                const SizedBox(height: 28),

                // 4. Section Pengeluaran Terkini
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pengeluaran Terkini',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${data.summary.recentExpenses.length} transaksi',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xFF4A4A4A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRecentExpensesList(
                    context,
                    ref,
                    data.summary.recentExpenses,
                    isNominalsLoading: data.isNominalsLoading,
                  ),
                ),
              ],
            ),
          ),
          loading: () => const DashboardShimmerLoading(),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan:\n$error',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(dashboardViewModelProvider.notifier).refresh(),
                    child: Text('Coba Lagi', style: AppTypography.button),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    User? user,
    List<AgendaItem> upcomingAgendas,
  ) {
    final displayName = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim()
        : 'Admin';
    final hasNotification = upcomingAgendas.isNotEmpty;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEDE4D9),
            border: Border.all(
              color: const Color(0xFFE0D3C3),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: (user != null && user.companyLogo.trim().isNotEmpty)
                ? Image.network(
                    user.companyLogo,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
                  )
                : _buildFallbackAvatar(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: 'Halo, ',
              style: AppTypography.h3.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: _greetingBrown.withValues(alpha: 0.85),
              ),
              children: [
                TextSpan(
                  text: displayName,
                  style: AppTypography.h3.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _greetingBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: const Color(0xFFEDE4D9),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _showNotificationsSheet(context, ref, upcomingAgendas),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: _greetingBrown,
                    size: 24,
                  ),
                  if (hasNotification)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD84B3A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFEDE4D9),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFFEDE4D9),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/icons/user.svg',
        width: 22,
        height: 22,
        colorFilter: const ColorFilter.mode(_greetingBrown, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildAIAssistantBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIAssistantView()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2E241C),
              Color(0xFF453528),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGold, AppColors.secondaryGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Asisten Dekorin AI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'BARU',
                          style: AppTypography.caption.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cek omset, deteksi jadwal bentrok & insight bisnis',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primaryGold,
                size: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSummaryCard(
    BuildContext context,
    WidgetRef ref,
    DashboardSummary summary,
    DashboardFilter filter, {
    bool isNominalsLoading = false,
  }) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.42, 0.72, 1.0],
          colors: [
            _bronzeDark,
            _goldHighlight,
            _goldMid,
            _bronzeDeep,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _bronzeDark.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Kilau metalik lembut di area atas-tengah seperti pada desain referensi
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.15, -0.65),
                    radius: 1.1,
                    colors: [
                      const Color(0xFFE5B879).withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Segmented Control Tabs (Bulan | Tahun | Semua)
                  _buildFilterSegmentedBar(context, ref, filter),
                  const SizedBox(height: 14),

                  // Header title "Keuntungan"
                  Text(
                    'Keuntungan (Pendapatan - Beban)',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Navigator Periode (e.g. ◀ November 2026 ▶ / ◀ 2026 ▶ / Semua Waktu)
                  _buildPeriodNavigator(context, ref, filter),
                  const SizedBox(height: 6),

                  // Nominal Keuntungan
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isNominalsLoading
                        ? const ShimmerBox(
                            key: ValueKey('hero_profit_shimmer'),
                            width: 170,
                            height: 32,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            baseColor: Color(0x2EFFFFFF),
                            highlightColor: Color(0x66FFFFFF),
                          )
                        : FittedBox(
                            key: const ValueKey('hero_profit_value'),
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currencyFormatter.format(summary.totalProfit),
                              style: AppTypography.h1.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),

                  // 3 Tiles Ringkasan (Pendapatan, Pengeluaran, Agenda)
                  Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: _HeroMetricTile(
                          iconAsset: 'assets/icons/wallet-income.svg',
                          title: 'Pendapatan',
                          value: currencyFormatter.format(summary.totalRevenue),
                          isLoading: isNominalsLoading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 11,
                        child: _HeroMetricTile(
                          iconAsset: 'assets/icons/expense.svg',
                          title: 'Pengeluaran',
                          value: currencyFormatter.format(summary.totalExpense),
                          isLoading: isNominalsLoading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 8,
                        child: _HeroMetricTile(
                          iconAsset: 'assets/icons/calendar.svg',
                          title: 'Agenda',
                          value: '${summary.upcomingBookingsCount} Event',
                          isLoading: isNominalsLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSegmentedBar(
    BuildContext context,
    WidgetRef ref,
    DashboardFilter filter,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildSegmentTab(
            title: 'Bulan',
            isSelected: filter.type == DashboardPeriodType.month,
            onTap: () {
              if (filter.type != DashboardPeriodType.month) {
                ref.read(dashboardViewModelProvider.notifier).setFilter(
                  filter.copyWith(type: DashboardPeriodType.month),
                );
              }
            },
          ),
          _buildSegmentTab(
            title: 'Tahun',
            isSelected: filter.type == DashboardPeriodType.year,
            onTap: () {
              if (filter.type != DashboardPeriodType.year) {
                ref.read(dashboardViewModelProvider.notifier).setFilter(
                  filter.copyWith(type: DashboardPeriodType.year),
                );
              }
            },
          ),
          _buildSegmentTab(
            title: 'Semua',
            isSelected: filter.type == DashboardPeriodType.all,
            onTap: () {
              if (filter.type != DashboardPeriodType.all) {
                ref.read(dashboardViewModelProvider.notifier).setFilter(
                  filter.copyWith(type: DashboardPeriodType.all),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                  color: isSelected ? _bronzeDark : Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodNavigator(
    BuildContext context,
    WidgetRef ref,
    DashboardFilter filter,
  ) {
    if (filter.type == DashboardPeriodType.all) {
      return Text(
        'Periode: Semua Waktu (Akumulasi)',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: Colors.white.withValues(alpha: 0.78),
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Periode: ',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11.5,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (filter.type == DashboardPeriodType.month) {
                  int newMonth = filter.month - 1;
                  int newYear = filter.year;
                  if (newMonth < 1) {
                    newMonth = 12;
                    newYear -= 1;
                  }
                  ref.read(dashboardViewModelProvider.notifier).setFilter(
                    filter.copyWith(month: newMonth, year: newYear),
                  );
                } else if (filter.type == DashboardPeriodType.year) {
                  ref.read(dashboardViewModelProvider.notifier).setFilter(
                    filter.copyWith(year: filter.year - 1),
                  );
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.chevron_left_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
          InkWell(
            onTap: () => MonthYearPickerSheet.show(
              context,
              initialFilter: filter,
              onSelect: (newFilter) {
                ref.read(dashboardViewModelProvider.notifier).setFilter(newFilter);
              },
            ),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter.displayPeriod,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (filter.type == DashboardPeriodType.month) {
                  int newMonth = filter.month + 1;
                  int newYear = filter.year;
                  if (newMonth > 12) {
                    newMonth = 1;
                    newYear += 1;
                  }
                  ref.read(dashboardViewModelProvider.notifier).setFilter(
                    filter.copyWith(month: newMonth, year: newYear),
                  );
                } else if (filter.type == DashboardPeriodType.year) {
                  ref.read(dashboardViewModelProvider.notifier).setFilter(
                    filter.copyWith(year: filter.year + 1),
                  );
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientFab(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.48, 1.0],
          colors: [
            Color(0xFF6B4824),
            Color(0xFFB78A4E),
            Color(0xFF654320),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFD8B580).withValues(alpha: 0.65),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _bronzeDeep.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddExpenseModal(context, ref),
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_shopping_cart_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Text(
                  'Catat Pengeluaran',
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentExpensesList(
    BuildContext context,
    WidgetRef ref,
    List<ExpenseItem> expenses, {
    bool isNominalsLoading = false,
  }) {
    if (expenses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE8E1)),
        ),
        child: Center(
          child: Text(
            'Belum ada catatan pengeluaran.',
            style: AppTypography.bodyMedium.copyWith(color: AppTheme.textLight, fontSize: 13),
          ),
        ),
      );
    }

    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final exp = expenses[index];
        final catStyle = ExpenseCategoryStyle.fromCategory(exp.category);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: isNominalsLoading
                ? null
                : () => ExpenseDetailBottomSheet.show(
                      context,
                      expense: exp,
                      onDelete: () {
                        Navigator.pop(context);
                        _confirmDeleteExpense(context, ref, exp);
                      },
                    ),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEDE8E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: catStyle.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: catStyle.buildIcon(size: 21),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.title,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${exp.category} \u2022 ${dateFormatter.format(exp.date)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF555555),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: isNominalsLoading
                            ? const ShimmerBox(
                                key: ValueKey('expense_item_shimmer'),
                                width: 85,
                                height: 16,
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                baseColor: Color(0xFFEBE6DF),
                                highlightColor: Color(0xFFF9F7F4),
                              )
                            : Text(
                                key: const ValueKey('expense_item_value'),
                                '- ${currencyFormatter.format(exp.amount)}',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: const Color(0xFF9E3329),
                                ),
                              ),
                      ),
                      InkWell(
                        onTap: isNominalsLoading ? null : () => _confirmDeleteExpense(context, ref, exp),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            'Hapus',
                            style: AppTypography.bodySmall.copyWith(
                              color: isNominalsLoading
                                  ? const Color(0xFFAAAAAA)
                                  : const Color(0xFF4A4A4A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteExpense(BuildContext context, WidgetRef ref, ExpenseItem exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Pengeluaran?', style: AppTypography.h3),
        content: Text('Yakin ingin menghapus catatan "${exp.title}"?', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await ref.read(dashboardViewModelProvider.notifier).deleteExpense(exp.id);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pengeluaran berhasil dihapus',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal menghapus: $e',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAgendasCarousel(BuildContext context, WidgetRef ref, List<AgendaItem> agendas) {
    if (agendas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDE8E1)),
          ),
          child: Center(
            child: Text(
              'Tidak ada booking mendatang yang terjadwal.',
              style: AppTypography.bodyMedium.copyWith(color: AppTheme.textLight),
            ),
          ),
        ),
      );
    }

    final dateFormatter = DateFormat('EEEE, dd MMM yyyy', 'id_ID');
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final cardWidth = (MediaQuery.sizeOf(context).width * 0.58).clamp(215.0, 260.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int index = 0; index < agendas.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              SizedBox(
                width: cardWidth,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AgendaDetailView(item: agendas[index])),
                      ).then((_) {
                        ref.read(dashboardViewModelProvider.notifier).refresh();
                      });
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEDE8E1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.045),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  agendas[index].clientName,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.5,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PaymentStatusBadge(
                                isPaid: agendas[index].isPaidOff,
                                dpAmount: agendas[index].dpAmount,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                '\u{1F389}',
                                style: AppTypography.bodySmall.copyWith(fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  agendas[index].backdropTitle.isNotEmpty
                                      ? agendas[index].backdropTitle
                                      : agendas[index].packageName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF3A3A3A),
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/calendar.svg',
                                width: 14,
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF7A7A7A),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  dateFormatter.format(agendas[index].eventDateTime),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF3A3A3A),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const SizedBox(height: 12),
                          Text(
                            currencyFormatter.format(agendas[index].calculatedTotalPrice),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(
    BuildContext context,
    WidgetRef ref,
    List<AgendaItem> upcomingAgendas,
  ) {
    final dateFormatter = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pengingat Event Mendatang',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (upcomingAgendas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Tidak ada notifikasi event mendatang.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: upcomingAgendas.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final agenda = upcomingAgendas[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/calendar.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              _greetingBrown,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        title: Text(
                          agenda.clientName,
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          dateFormatter.format(agenda.eventDateTime),
                          style: AppTypography.caption,
                        ),
                        trailing: _PaymentStatusBadge(
                          isPaid: agenda.isPaidOff,
                          dpAmount: agenda.dpAmount,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AgendaDetailView(item: agenda)),
                          ).then((_) {
                            ref.read(dashboardViewModelProvider.notifier).refresh();
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddExpenseBottomSheet(ref: ref),
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({
    required this.iconAsset,
    required this.title,
    required this.value,
    this.isLoading = false,
  });

  final String iconAsset;
  final String title;
  final String value;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.24),
            Colors.white.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.26),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF5ECE2).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(9),
            ),
            child: SvgPicture.asset(
              iconAsset,
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Color(0xFF634222),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLoading
                ? const ShimmerBox(
                    key: ValueKey('hero_metric_shimmer'),
                    width: 70,
                    height: 16,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    baseColor: Color(0x2EFFFFFF),
                    highlightColor: Color(0x66FFFFFF),
                  )
                : FittedBox(
                    key: const ValueKey('hero_metric_value'),
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.isPaid, required this.dpAmount});

  final bool isPaid;
  final double dpAmount;

  @override
  Widget build(BuildContext context) {
    if (isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F6EE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF82C99B)),
        ),
        child: Text(
          'Lunas',
          style: AppTypography.caption.copyWith(
            color: const Color(0xFF1E7E45),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (dpAmount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF0D7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9BC7C)),
        ),
        child: Text(
          'DP Masuk',
          style: AppTypography.caption.copyWith(
            color: const Color(0xFF7B5B25),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE6A1A1)),
        ),
        child: Text(
          'Belum Bayar',
          style: AppTypography.caption.copyWith(
            color: const Color(0xFFA93226),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}

class _AddExpenseBottomSheet extends StatefulWidget {
  const _AddExpenseBottomSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<_AddExpenseBottomSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Bunga';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isScanning = false;

  final List<String> _categories = ['Bunga', 'Properti Dekor', 'Operasional', 'Transport', 'Honor Crew', 'Lainnya'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAndScanReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto Nota',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.goldLight,
                  child: Icon(Icons.camera_alt, color: AppColors.primaryGold),
                ),
                title: Text('Kamera', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Ambil foto struk langsung', style: AppTypography.caption),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.goldLight,
                  child: Icon(Icons.photo_library, color: AppColors.primaryGold),
                ),
                title: Text('Galeri', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Pilih dari album foto', style: AppTypography.caption),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isScanning = true);

      final result = await widget.ref
          .read(expenseServiceProvider)
          .scanReceiptWithAi(File(pickedFile.path));

      if (!mounted) return;

      setState(() {
        if (result.title.isNotEmpty) {
          _titleController.text = result.title;
        }
        if (result.amount > 0) {
          _amountController.text = NumberFormat('#,###', 'id_ID')
              .format(result.amount.toInt())
              .replaceAll(',', '.');
        }
        if (result.category.isNotEmpty && _categories.contains(result.category)) {
          _selectedCategory = result.category;
        }
        _selectedDate = result.date;
        if (result.notes.isNotEmpty) {
          _notesController.text = result.notes;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nota berhasil dibaca! Silakan periksa rincian sebelum disimpan.',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memindai nota: $e',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan judul/keterangan pengeluaran',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan nominal pengeluaran yang valid',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.ref
          .read(expenseServiceProvider)
          .createExpense(
            title: title,
            amount: amount,
            category: _selectedCategory,
            date: _selectedDate,
            notes: _notesController.text.trim(),
          );

      widget.ref.read(dashboardViewModelProvider.notifier).refresh(showNominalsShimmer: true);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pengeluaran berhasil dicatat!',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mencatat pengeluaran: $e',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryGold, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('Catat Pengeluaran', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),

            // Tombol AI Scan Nota
            InkWell(
              onTap: _isScanning ? null : _pickAndScanReceipt,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGold.withValues(alpha: 0.15),
                      AppColors.goldLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isScanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _isScanning ? 'Menganalisis Nota...' : 'Scan Nota / Struk (AI)',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'BARU',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isScanning
                                ? 'Gemini AI sedang membaca rincian & nominal...'
                                : 'Foto struk belanja untuk mengisi form otomatis',
                            style: AppTypography.caption.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isScanning)
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.primaryGold,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Keterangan / Judul
            Text(
              'Keterangan Pengeluaran *',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Misal: Pembelian Bunga Mawar & Baby Breath',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Nominal Pengeluaran
            Text(
              'Nominal Biaya (Rp) *',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                hintText: '500.000',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Kategori
            Text('Kategori *', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected ? AppTheme.primaryGold : AppTheme.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGold.withValues(alpha: 0.2),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Tanggal Pengeluaran
            Text(
              'Tanggal Transaksi',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateFormatter.format(_selectedDate), style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                    SvgPicture.asset(
                      'assets/icons/calendar.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(AppTheme.primaryGold, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Catatan Tambahan
            Text(
              'Catatan Tambahan (Opsional)',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Toko/vendor, no. nota, dll',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Simpan Pengeluaran',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
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
