/// Tipe periode filter untuk ringkasan keuangan dashboard.
enum DashboardPeriodType {
  month,
  year,
  all;

  String get label {
    switch (this) {
      case DashboardPeriodType.month:
        return 'Bulan';
      case DashboardPeriodType.year:
        return 'Tahun';
      case DashboardPeriodType.all:
        return 'Semua';
    }
  }
}

/// Model filter periode dashboard (Bulan, Tahun, Semua Waktu).
class DashboardFilter {
  DashboardFilter({
    this.type = DashboardPeriodType.month,
    int? month,
    int? year,
  })  : month = month ?? DateTime.now().month,
        year = year ?? DateTime.now().year;

  final DashboardPeriodType type;
  final int month; // 1-12
  final int year;  // Contoh: 2026

  DashboardFilter copyWith({
    DashboardPeriodType? type,
    int? month,
    int? year,
  }) {
    return DashboardFilter(
      type: type ?? this.type,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  /// Label teks periode untuk ditampilkan di kartu (mis: "November 2026", "Tahun 2026", "Semua Waktu")
  String get displayPeriod {
    switch (type) {
      case DashboardPeriodType.month:
        const months = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];
        final monthName = (month >= 1 && month <= 12) ? months[month - 1] : 'Bulan $month';
        return '$monthName $year';
      case DashboardPeriodType.year:
        return 'Tahun $year';
      case DashboardPeriodType.all:
        return 'Semua Waktu';
    }
  }

  /// Mengonversi filter menjadi query params URL untuk backend API
  Map<String, String> toQueryParams() {
    switch (type) {
      case DashboardPeriodType.month:
        return {
          'filter': 'month',
          'month': month.toString(),
          'year': year.toString(),
        };
      case DashboardPeriodType.year:
        return {
          'filter': 'year',
          'year': year.toString(),
        };
      case DashboardPeriodType.all:
        return {
          'filter': 'all',
        };
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => type.hashCode ^ month.hashCode ^ year.hashCode;
}
