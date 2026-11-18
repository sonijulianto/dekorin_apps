/// Model domain untuk opsi vendor partner yang dapat diundang ke kolaborasi agenda.
class CollaborationVendorOption {
  const CollaborationVendorOption({
    required this.id,
    required this.name,
    this.category = 'other',
    this.city = '',
    this.phone = '',
    this.logoUrl = '',
  });

  final String id;
  final String name;
  final String category;
  final String city;
  final String phone;
  final String logoUrl;

  factory CollaborationVendorOption.fromJson(Map<String, dynamic> json) {
    return CollaborationVendorOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
    );
  }
}

/// Model domain untuk relasi kolaborasi antar-vendor pada satu agenda.
class AgendaCollaboration {
  const AgendaCollaboration({
    required this.id,
    required this.leadAgendaId,
    required this.leadCompanyId,
    this.leadCompanyName = '',
    required this.partnerCompanyId,
    this.partnerCompanyName = '',
    this.partnerCategory = 'other',
    this.partnerAgendaId = '',
    this.partnerPrice = 0.0,
    this.partnerTransportFee = 0.0,
    this.partnerDpAmount = 0.0,
    this.notes = '',
    this.status = 'pending',
    this.rejectReason = '',
    this.respondedAt,
    this.createdAt,
  });

  final String id;
  final String leadAgendaId;
  final String leadCompanyId;
  final String leadCompanyName;
  final String partnerCompanyId;
  final String partnerCompanyName;
  final String partnerCategory;
  final String partnerAgendaId;
  final double partnerPrice;
  final double partnerTransportFee;
  final double partnerDpAmount;
  final String notes;
  final String status; // pending, accepted, rejected, cancelled
  final String rejectReason;
  final DateTime? respondedAt;
  final DateTime? createdAt;

  double get totalCost => partnerPrice + partnerTransportFee;
  double get remainingAmount => (totalCost - partnerDpAmount).clamp(0.0, double.infinity);
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  factory AgendaCollaboration.fromJson(Map<String, dynamic> json) {
    return AgendaCollaboration(
      id: json['id'] as String? ?? '',
      leadAgendaId: json['lead_agenda_id'] as String? ?? '',
      leadCompanyId: json['lead_company_id'] as String? ?? '',
      leadCompanyName: json['lead_company_name'] as String? ?? '',
      partnerCompanyId: json['partner_company_id'] as String? ?? '',
      partnerCompanyName: json['partner_company_name'] as String? ?? '',
      partnerCategory: json['partner_category'] as String? ?? 'other',
      partnerAgendaId: json['partner_agenda_id'] as String? ?? '',
      partnerPrice: (json['partner_price'] as num?)?.toDouble() ?? 0.0,
      partnerTransportFee: (json['partner_transport_fee'] as num?)?.toDouble() ?? 0.0,
      partnerDpAmount: (json['partner_dp_amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      rejectReason: json['reject_reason'] as String? ?? '',
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

/// Model undangan kolaborasi masuk untuk vendor partner.
class IncomingCollaborationItem {
  const IncomingCollaborationItem({
    required this.collaboration,
    this.clientName = '',
    this.clientPhone = '',
    this.eventType = '',
    this.eventLabel = '',
    this.eventDateTime,
    this.eventAddress = '',
    this.mapsUrl = '',
    this.hasScheduleConflict = false,
  });

  final AgendaCollaboration collaboration;
  final String clientName;
  final String clientPhone;
  final String eventType;
  final String eventLabel;
  final DateTime? eventDateTime;
  final String eventAddress;
  final String mapsUrl;
  final bool hasScheduleConflict;

  factory IncomingCollaborationItem.fromJson(Map<String, dynamic> json) {
    return IncomingCollaborationItem(
      collaboration: AgendaCollaboration.fromJson(json),
      clientName: json['client_name'] as String? ?? '',
      clientPhone: json['client_phone'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      eventLabel: json['event_label'] as String? ?? '',
      eventDateTime: json['event_date_time'] != null
          ? DateTime.tryParse(json['event_date_time'].toString())
          : null,
      eventAddress: json['event_address'] as String? ?? '',
      mapsUrl: json['maps_url'] as String? ?? '',
      hasScheduleConflict: json['has_schedule_conflict'] as bool? ?? false,
    );
  }
}

class AgendaCollaborationsResult {
  const AgendaCollaborationsResult({
    this.collaborations = const [],
    this.acceptedPartnerCost = 0.0,
    this.pendingPartnerCost = 0.0,
  });

  final List<AgendaCollaboration> collaborations;
  final double acceptedPartnerCost;
  final double pendingPartnerCost;
}

class IncomingCollaborationsResult {
  const IncomingCollaborationsResult({
    this.items = const [],
    this.pendingCount = 0,
  });

  final List<IncomingCollaborationItem> items;
  final int pendingCount;
}
