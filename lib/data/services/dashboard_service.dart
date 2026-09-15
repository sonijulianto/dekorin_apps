import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/domain/models/booking.dart';
import 'package:dekorin_apps/domain/models/dashboard_summary.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

/// Dummy service to mock dashboard data.
class DashboardService {
  Future<DashboardSummary> fetchSummary() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(seconds: 1));

    return const DashboardSummary(
      upcomingBookingsCount: 12,
      totalRevenue: 25000000.0, // 25 Juta
      totalProfit: 8500000.0, // 8.5 Juta
    );
  }

  Future<List<Booking>> fetchThisWeekBookings() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(seconds: 1));

    final now = DateTime.now();

    return [
      Booking(
        id: 'bk_001',
        clientName: 'Budi & Siska',
        eventName: 'Wedding Reception',
        date: now.add(const Duration(days: 2)),
        location: 'Gedung Serbaguna, Jakarta',
        status: BookingStatus.confirmed,
        totalPrice: 15000000.0,
      ),
      Booking(
        id: 'bk_002',
        clientName: 'Keluarga Anang',
        eventName: 'Engagement',
        date: now.add(const Duration(days: 4)),
        location: 'Restoran Sunda, Bandung',
        status: BookingStatus.pending,
        totalPrice: 5000000.0,
      ),
      Booking(
        id: 'bk_003',
        clientName: 'PT. Maju Mundur',
        eventName: 'Corporate Gathering',
        date: now.add(const Duration(days: 6)),
        location: 'Hotel Bintang, Surabaya',
        status: BookingStatus.confirmed,
        totalPrice: 10000000.0,
      ),
    ];
  }
}
