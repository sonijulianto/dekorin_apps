class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    this.category = 'Lainnya',
    required this.date,
    this.notes = '',
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String notes;

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ExpenseItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: parseDouble(json['amount']),
      category: json['category'] as String? ?? 'Lainnya',
      date: parsedDate,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}
