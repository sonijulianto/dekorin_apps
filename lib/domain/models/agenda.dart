class ClientFormModel {
  const ClientFormModel({
    required this.id,
    required this.agendaId,
    required this.eventAddress,
    required this.decorationTheme,
    required this.colorPreference,
    required this.specialRequests,
    required this.referencePhotoUrl,
    this.submittedAt,
  });

  final String id;
  final String agendaId;
  final String eventAddress;
  final String decorationTheme;
  final String colorPreference;
  final String specialRequests;
  final String referencePhotoUrl;
  final DateTime? submittedAt;

  factory ClientFormModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedSubmitted;
    if (json['submitted_at'] != null) {
      try {
        parsedSubmitted = DateTime.parse(json['submitted_at'] as String);
      } catch (_) {}
    }

    return ClientFormModel(
      id: json['id'] as String? ?? '',
      agendaId: json['agenda_id'] as String? ?? '',
      eventAddress: json['event_address'] as String? ?? '',
      decorationTheme: json['decoration_theme'] as String? ?? '',
      colorPreference: json['color_preference'] as String? ?? '',
      specialRequests: json['special_requests'] as String? ?? '',
      referencePhotoUrl: json['reference_photo_url'] as String? ?? '',
      submittedAt: parsedSubmitted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agenda_id': agendaId,
      'event_address': eventAddress,
      'decoration_theme': decorationTheme,
      'color_preference': colorPreference,
      'special_requests': specialRequests,
      'reference_photo_url': referencePhotoUrl,
      'submitted_at': submittedAt?.toIso8601String(),
    };
  }
}

class AgendaItem {
  const AgendaItem({
    required this.id,
    required this.clientName,
    this.clientPhone = '',
    required this.backdropTitle,
    required this.eventDateTime,
    required this.mapsUrl,
    required this.packageId,
    required this.packageName,
    this.status = 'upcoming',
    this.formToken = '',
    this.formStatus = 'pending',
    this.notes = '',
    this.clientForm,
  });

  final String id;
  final String clientName;
  final String clientPhone;
  final String backdropTitle;
  final DateTime eventDateTime;
  final String mapsUrl;
  final String packageId;
  final String packageName;
  final String status;
  final String formToken;
  final String formStatus; // 'pending', 'filled'
  final String notes;
  final ClientFormModel? clientForm;

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['event_date_time'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    ClientFormModel? parsedForm;
    if (json['client_form'] != null && json['client_form'] is Map<String, dynamic>) {
      parsedForm = ClientFormModel.fromJson(json['client_form'] as Map<String, dynamic>);
    }

    return AgendaItem(
      id: json['id'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      clientPhone: json['client_phone'] as String? ?? '',
      backdropTitle: json['backdrop_title'] as String? ?? '',
      eventDateTime: parsedDate,
      mapsUrl: json['maps_url'] as String? ?? '',
      packageId: json['package_id'] as String? ?? '',
      packageName: json['package_name'] as String? ?? '',
      status: json['status'] as String? ?? 'upcoming',
      formToken: json['form_token'] as String? ?? '',
      formStatus: json['form_status'] as String? ?? 'pending',
      notes: json['notes'] as String? ?? '',
      clientForm: parsedForm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_name': clientName,
      'client_phone': clientPhone,
      'backdrop_title': backdropTitle,
      'event_date_time': eventDateTime.toIso8601String(),
      'maps_url': mapsUrl,
      'package_id': packageId,
      'package_name': packageName,
      'status': status,
      'form_token': formToken,
      'form_status': formStatus,
      'notes': notes,
      if (clientForm != null) 'client_form': clientForm!.toJson(),
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
