import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/repositories/dashboard_repository_impl.dart';
import 'package:dekorin_apps/domain/models/booking.dart';
import 'package:dekorin_apps/domain/models/dashboard_summary.dart';

/// Type alias for the data held by DashboardViewModel.
typedef DashboardData = ({
  DashboardSummary summary,
  List<Booking> thisWeekBookings,
});

/// Provider for DashboardViewModel (AutoDispose AsyncNotifier)
final dashboardViewModelProvider =
    AutoDisposeAsyncNotifierProvider<DashboardViewModel, DashboardData>(() {
  return DashboardViewModel();
});

class DashboardViewModel extends AutoDisposeAsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    return _fetchData();
  }

  Future<DashboardData> _fetchData() async {
    final repository = ref.watch(dashboardRepositoryProvider);
    
    // Fetch both summary and bookings concurrently
    final results = await Future.wait([
      repository.getSummary(),
      repository.getThisWeekBookings(),
    ]);

    return (
      summary: results[0] as DashboardSummary,
      thisWeekBookings: results[1] as List<Booking>,
    );
  }

  /// Manually trigger a refresh of the dashboard data.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _fetchData();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
