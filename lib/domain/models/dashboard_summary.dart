/// Domain model representing the dashboard financial and booking summary.
class DashboardSummary {
  const DashboardSummary({
    required this.upcomingBookingsCount,
    required this.totalRevenue,
    required this.totalProfit,
  });

  final int upcomingBookingsCount;
  final double totalRevenue;
  final double totalProfit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardSummary &&
          runtimeType == other.runtimeType &&
          upcomingBookingsCount == other.upcomingBookingsCount &&
          totalRevenue == other.totalRevenue &&
          totalProfit == other.totalProfit;

  @override
  int get hashCode => Object.hash(
        upcomingBookingsCount,
        totalRevenue,
        totalProfit,
      );
}
