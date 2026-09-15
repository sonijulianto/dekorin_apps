import 'package:dekorin_apps/domain/models/booking.dart';
import 'package:dekorin_apps/domain/models/dashboard_summary.dart';

/// Contract for dashboard data operations.
abstract class DashboardRepository {
  /// Fetches the overall summary (revenue, profit, upcoming count).
  Future<DashboardSummary> getSummary();

  /// Fetches bookings specifically scheduled for the current week.
  Future<List<Booking>> getThisWeekBookings();
}
