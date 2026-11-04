import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/repositories/dashboard_repository_impl.dart';
import 'package:dekorin_apps/data/services/expense_service.dart';
import 'package:dekorin_apps/domain/models/booking.dart';
import 'package:dekorin_apps/domain/models/dashboard_filter.dart';
import 'package:dekorin_apps/domain/models/dashboard_summary.dart';

/// Type alias for the data held by DashboardViewModel.
typedef DashboardData = ({
  DashboardSummary summary,
  List<Booking> thisWeekBookings,
  bool isNominalsLoading,
  DashboardFilter filter,
});

/// Provider for DashboardViewModel (AutoDispose AsyncNotifier)
final dashboardViewModelProvider =
    AutoDisposeAsyncNotifierProvider<DashboardViewModel, DashboardData>(() {
  return DashboardViewModel();
});

class DashboardViewModel extends AutoDisposeAsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    // Default filter adalah bulan berjalan (Bulan Ini)
    final defaultFilter = DashboardFilter();
    final fetched = await _fetchData(defaultFilter);
    return (
      summary: fetched.summary,
      thisWeekBookings: fetched.thisWeekBookings,
      isNominalsLoading: false,
      filter: defaultFilter,
    );
  }

  Future<({DashboardSummary summary, List<Booking> thisWeekBookings})> _fetchData(
    DashboardFilter filter,
  ) async {
    final repository = ref.watch(dashboardRepositoryProvider);

    // Fetch both summary (with period filter) and bookings concurrently
    final results = await Future.wait([
      repository.getSummary(filter),
      repository.getThisWeekBookings(),
    ]);

    return (
      summary: results[0] as DashboardSummary,
      thisWeekBookings: results[1] as List<Booking>,
    );
  }

  /// Ubah filter periode (Bulan Ini, Tahun Ini, Semua, atau bulan/tahun kustom).
  Future<void> setFilter(DashboardFilter newFilter) async {
    final current = state.value;
    if (current == null) return;
    if (current.filter == newFilter && !current.isNominalsLoading) return;

    // Aktifkan shimmer pada nominal agar transisi pergantian filter terasa mulus
    state = AsyncValue.data((
      summary: current.summary,
      thisWeekBookings: current.thisWeekBookings,
      isNominalsLoading: true,
      filter: newFilter,
    ));

    try {
      final repository = ref.read(dashboardRepositoryProvider);
      final updatedSummary = await repository.getSummary(newFilter);

      state = AsyncValue.data((
        summary: updatedSummary,
        thisWeekBookings: current.thisWeekBookings,
        isNominalsLoading: false,
        filter: newFilter,
      ));
    } catch (e) {
      // Revert ke filter sebelumnya jika gagal
      state = AsyncValue.data((
        summary: current.summary,
        thisWeekBookings: current.thisWeekBookings,
        isNominalsLoading: false,
        filter: current.filter,
      ));
    }
  }

  /// Manually trigger a refresh of the dashboard data.
  /// If data already exists, refresh happens smoothly without blanking out the whole screen.
  Future<void> refresh({bool showNominalsShimmer = false}) async {
    final current = state.value;
    final activeFilter = current?.filter ?? DashboardFilter();

    if (current != null) {
      if (showNominalsShimmer) {
        state = AsyncValue.data((
          summary: current.summary,
          thisWeekBookings: current.thisWeekBookings,
          isNominalsLoading: true,
          filter: activeFilter,
        ));
      }
      try {
        final fetched = await _fetchData(activeFilter);
        state = AsyncValue.data((
          summary: fetched.summary,
          thisWeekBookings: fetched.thisWeekBookings,
          isNominalsLoading: false,
          filter: activeFilter,
        ));
      } catch (e) {
        state = AsyncValue.data((
          summary: current.summary,
          thisWeekBookings: current.thisWeekBookings,
          isNominalsLoading: false,
          filter: activeFilter,
        ));
      }
    } else {
      state = const AsyncValue.loading();
      try {
        final fetched = await _fetchData(activeFilter);
        state = AsyncValue.data((
          summary: fetched.summary,
          thisWeekBookings: fetched.thisWeekBookings,
          isNominalsLoading: false,
          filter: activeFilter,
        ));
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Delete an expense optimistically, refreshing only the expenses list and shimmering nominals.
  Future<void> deleteExpense(String expenseId) async {
    final current = state.value;
    if (current == null) {
      await ref.read(expenseServiceProvider).deleteExpense(expenseId);
      return;
    }

    final activeFilter = current.filter;

    // 1. Optimistically remove the expense immediately from recentExpenses
    final updatedExpenses = current.summary.recentExpenses
        .where((e) => e.id != expenseId)
        .toList();

    // Set nominals loading to true so financial amounts shimmer
    state = AsyncValue.data((
      summary: current.summary.copyWith(recentExpenses: updatedExpenses),
      thisWeekBookings: current.thisWeekBookings,
      isNominalsLoading: true,
      filter: activeFilter,
    ));

    try {
      // 2. Perform API delete and wait minimum duration for smooth shimmer perception
      await Future.wait([
        ref.read(expenseServiceProvider).deleteExpense(expenseId),
        Future.delayed(const Duration(milliseconds: 350)),
      ]);

      // 3. Re-fetch summary in background to sync totals with server using current filter
      final repository = ref.read(dashboardRepositoryProvider);
      final updatedSummary = await repository.getSummary(activeFilter);

      state = AsyncValue.data((
        summary: updatedSummary,
        thisWeekBookings: current.thisWeekBookings,
        isNominalsLoading: false,
        filter: activeFilter,
      ));
    } catch (e) {
      // Revert to original state if error occurs
      state = AsyncValue.data((
        summary: current.summary,
        thisWeekBookings: current.thisWeekBookings,
        isNominalsLoading: false,
        filter: activeFilter,
      ));
      rethrow;
    }
  }
}
