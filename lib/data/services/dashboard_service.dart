import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/booking.dart';
import 'package:dekorin_apps/domain/models/dashboard_filter.dart';
import 'package:dekorin_apps/domain/models/dashboard_summary.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

/// Service untuk mengambil data dashboard keuangan & booking dari backend.
class DashboardService {
  Future<DashboardSummary> fetchSummary([DashboardFilter? filter]) async {
    try {
      final activeFilter = filter ?? DashboardFilter();
      final queryParams = activeFilter.toQueryParams();
      final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final path = queryString.isNotEmpty ? '${ApiEndpoint.dashboardSummary}?$queryString' : ApiEndpoint.dashboardSummary;

      final responseData = await ApiClient.get(path);
      final data = responseData['data'] as Map<String, dynamic>;
      return DashboardSummary.fromJson(data);
    } catch (e) {
      return const DashboardSummary(
        upcomingBookingsCount: 0,
        totalRevenue: 0.0,
        totalExpense: 0.0,
        totalProfit: 0.0,
        upcomingAgendas: [],
        recentExpenses: [],
      );
    }
  }

  Future<List<Booking>> fetchThisWeekBookings() async {
    try {
      final summary = await fetchSummary();
      return summary.upcomingAgendas.map((agenda) {
        return Booking(
          id: agenda.id,
          clientName: agenda.clientName,
          eventName: agenda.backdropTitle.isNotEmpty
              ? agenda.backdropTitle
              : agenda.packageName,
          date: agenda.eventDateTime,
          location: agenda.displayAddress.isNotEmpty
              ? agenda.displayAddress
              : (agenda.mapsUrl.isNotEmpty ? 'Lokasi via Maps' : 'Lokasi Acara'),
          status: agenda.isEventCompleted
              ? BookingStatus.completed
              : agenda.isCancelled
                  ? BookingStatus.cancelled
                  : BookingStatus.confirmed,
          totalPrice: agenda.calculatedTotalPrice,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
