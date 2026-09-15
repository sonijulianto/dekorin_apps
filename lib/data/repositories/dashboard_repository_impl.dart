import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/services/dashboard_service.dart';
import 'package:dekorin_apps/domain/models/booking.dart';
import 'package:dekorin_apps/domain/models/dashboard_summary.dart';
import 'package:dekorin_apps/domain/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final service = ref.watch(dashboardServiceProvider);
  return DashboardRepositoryImpl(dashboardService: service);
});

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required DashboardService dashboardService})
      : _dashboardService = dashboardService;

  final DashboardService _dashboardService;

  @override
  Future<DashboardSummary> getSummary() {
    return _dashboardService.fetchSummary();
  }

  @override
  Future<List<Booking>> getThisWeekBookings() {
    return _dashboardService.fetchThisWeekBookings();
  }
}
