class AgendaItem {
  const AgendaItem({
    required this.id,
    required this.clientName,
    required this.backdropTitle,
    required this.eventDateTime,
    required this.mapsUrl,
    required this.packageId,
    required this.packageName,
    this.status = 'upcoming',
    this.notes = '',
  });

  final String id;
  final String clientName;
  final String backdropTitle;
  final DateTime eventDateTime;
  final String mapsUrl;
  final String packageId;
  final String packageName;
  final String status;
  final String notes;

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['event_date_time'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AgendaItem(
      id: json['id'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      backdropTitle: json['backdrop_title'] as String? ?? '',
      eventDateTime: parsedDate,
      mapsUrl: json['maps_url'] as String? ?? '',
      packageId: json['package_id'] as String? ?? '',
      packageName: json['package_name'] as String? ?? '',
      status: json['status'] as String? ?? 'upcoming',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_name': clientName,
      'backdrop_title': backdropTitle,
      'event_date_time': eventDateTime.toIso8601String(),
      'maps_url': mapsUrl,
      'package_id': packageId,
      'package_name': packageName,
      'status': status,
      'notes': notes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgendaItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
