import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/expense.dart';

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService();
});

/// Service untuk menangani data pengeluaran operasional dekorasi dari backend.
class ExpenseService {
  /// Mengambil daftar pengeluaran
  Future<List<ExpenseItem>> getExpenses({DateTime? startDate, DateTime? endDate}) async {
    final formatter = DateFormat('yyyy-MM-dd');
    final queryParams = <String>[];
    if (startDate != null) {
      queryParams.add('start_date=${formatter.format(startDate)}');
    }
    if (endDate != null) {
      queryParams.add('end_date=${formatter.format(endDate)}');
    }

    final path = queryParams.isEmpty
        ? ApiEndpoint.expenses
        : '${ApiEndpoint.expenses}?${queryParams.join('&')}';

    final responseData = await ApiClient.get(path);
    final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
    return data.map((item) => ExpenseItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Menambah pengeluaran baru
  Future<ExpenseItem> createExpense({
    required String title,
    required double amount,
    String category = 'Lainnya',
    DateTime? date,
    String notes = '',
  }) async {
    final body = {
      'title': title,
      'amount': amount,
      'category': category,
      'date': (date ?? DateTime.now()).toIso8601String(),
      'notes': notes,
    };

    final responseData = await ApiClient.post(ApiEndpoint.expenses, body: body);
    return ExpenseItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  /// Menghapus pengeluaran berdasarkan ID
  Future<void> deleteExpense(String id) async {
    await ApiClient.delete('${ApiEndpoint.expenses}/$id');
  }
}
