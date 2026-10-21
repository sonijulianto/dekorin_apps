import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/expense.dart';

/// Domain model representing the dashboard financial and booking summary.
class DashboardSummary {
  const DashboardSummary({
    required this.upcomingBookingsCount,
    required this.totalRevenue,
    required this.totalExpense,
    required this.totalProfit,
    this.upcomingAgendas = const [],
    this.recentExpenses = const [],
  });

  final int upcomingBookingsCount;
  final double totalRevenue;
  final double totalExpense;
  final double totalProfit;
  final List<AgendaItem> upcomingAgendas;
  final List<ExpenseItem> recentExpenses;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final upcomingRaw = json['upcoming_agendas'] as List<dynamic>? ?? [];
    final upcomingList = upcomingRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => AgendaItem.fromJson(e))
        .toList();

    final expenseRaw = json['recent_expenses'] as List<dynamic>? ?? [];
    final expenseList = expenseRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => ExpenseItem.fromJson(e))
        .toList();

    return DashboardSummary(
      upcomingBookingsCount: (json['upcoming_bookings_count'] as num?)?.toInt() ?? 0,
      totalRevenue: parseDouble(json['total_revenue']),
      totalExpense: parseDouble(json['total_expense']),
      totalProfit: parseDouble(json['total_profit']),
      upcomingAgendas: upcomingList,
      recentExpenses: expenseList,
    );
  }
}
