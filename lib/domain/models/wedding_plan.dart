/// Domain models untuk fitur Calon Pengantin (Wedding Plan, Multi-Vendor, Checklist, dan Direktori Vendor).
class WeddingPlan {
  const WeddingPlan({
    required this.id,
    this.title = '',
    this.groomName = '',
    this.brideName = '',
    this.weddingDate = '',
    this.akadTime = '',
    this.resepsiTime = '',
    this.city = '',
    this.venueName = '',
    this.venueAddress = '',
    this.mapsUrl = '',
    this.budgetTarget = 0,
    this.joinCode = '',
    this.notes = '',
  });

  final String id;
  final String title;
  final String groomName;
  final String brideName;
  final String weddingDate;
  final String akadTime;
  final String resepsiTime;
  final String city;
  final String venueName;
  final String venueAddress;
  final String mapsUrl;
  final double budgetTarget;
  final String joinCode;
  final String notes;

  factory WeddingPlan.fromJson(Map<String, dynamic> json) {
    return WeddingPlan(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      groomName: json['groom_name']?.toString() ?? '',
      brideName: json['bride_name']?.toString() ?? '',
      weddingDate: json['wedding_date']?.toString() ?? '',
      akadTime: json['akad_time']?.toString() ?? '',
      resepsiTime: json['resepsi_time']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      venueName: json['venue_name']?.toString() ?? '',
      venueAddress: json['venue_address']?.toString() ?? '',
      mapsUrl: json['maps_url']?.toString() ?? '',
      budgetTarget: (json['budget_target'] as num?)?.toDouble() ?? 0.0,
      joinCode: json['join_code']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class WeddingPlanMemberSummary {
  const WeddingPlanMemberSummary({
    required this.userId,
    this.fullName = '',
    this.phone = '',
    this.memberRole = 'partner',
  });

  final String userId;
  final String fullName;
  final String phone;
  final String memberRole;

  factory WeddingPlanMemberSummary.fromJson(Map<String, dynamic> json) {
    return WeddingPlanMemberSummary(
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      memberRole: json['member_role']?.toString() ?? 'partner',
    );
  }
}

class WeddingPlanSummaryStats {
  const WeddingPlanSummaryStats({
    this.daysRemaining,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.totalVendors = 0,
    this.syncedVendors = 0,
    this.totalAgreedCost = 0,
    this.totalDpPaid = 0,
    this.remainingVendorBalance = 0,
    this.linkedInvitationsCount = 0,
    this.totalRsvpHadir = 0,
    this.totalPaxHadir = 0,
  });

  final int? daysRemaining;
  final int totalTasks;
  final int completedTasks;
  final int totalVendors;
  final int syncedVendors;
  final double totalAgreedCost;
  final double totalDpPaid;
  final double remainingVendorBalance;
  final int linkedInvitationsCount;
  final int totalRsvpHadir;
  final int totalPaxHadir;

  double get taskProgress => totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  factory WeddingPlanSummaryStats.fromJson(Map<String, dynamic> json) {
    return WeddingPlanSummaryStats(
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
      totalVendors: (json['total_vendors'] as num?)?.toInt() ?? 0,
      syncedVendors: (json['synced_vendors'] as num?)?.toInt() ?? 0,
      totalAgreedCost: (json['total_agreed_cost'] as num?)?.toDouble() ?? 0.0,
      totalDpPaid: (json['total_dp_paid'] as num?)?.toDouble() ?? 0.0,
      remainingVendorBalance: (json['remaining_vendor_balance'] as num?)?.toDouble() ?? 0.0,
      linkedInvitationsCount: (json['linked_invitations_count'] as num?)?.toInt() ?? 0,
      totalRsvpHadir: (json['total_rsvp_hadir'] as num?)?.toInt() ?? 0,
      totalPaxHadir: (json['total_pax_hadir'] as num?)?.toInt() ?? 0,
    );
  }
}

class WeddingPlanDetail {
  const WeddingPlanDetail({
    required this.plan,
    this.members = const [],
    this.stats = const WeddingPlanSummaryStats(),
  });

  final WeddingPlan plan;
  final List<WeddingPlanMemberSummary> members;
  final WeddingPlanSummaryStats stats;

  factory WeddingPlanDetail.fromJson(Map<String, dynamic> json) {
    final planMap = json['plan'] as Map<String, dynamic>? ?? const {};
    final membersList = json['members'] as List<dynamic>? ?? const [];
    final statsMap = json['stats'] as Map<String, dynamic>? ?? const {};

    return WeddingPlanDetail(
      plan: WeddingPlan.fromJson(planMap),
      members: membersList
          .whereType<Map<String, dynamic>>()
          .map(WeddingPlanMemberSummary.fromJson)
          .toList(),
      stats: WeddingPlanSummaryStats.fromJson(statsMap),
    );
  }
}

class WeddingPlanVendorItem {
  const WeddingPlanVendorItem({
    required this.id,
    this.weddingPlanId = '',
    this.vendorCategory = 'other',
    this.vendorName = '',
    this.vendorPhone = '',
    this.vendorInstagram = '',
    this.companyId = '',
    this.agendaId = '',
    this.packageName = '',
    this.agreedPrice = 0,
    this.dpPaid = 0,
    this.paymentStatus = 'unpaid',
    this.dueDate = '',
    this.notes = '',
    this.sourceType = 'manual',
    this.isSyncedAgenda = false,
    this.companyLogo = '',
    this.agendaStatus = '',
    this.formToken = '',
    this.formStatus = '',
    this.modelName = '',
    this.subtotalDecor = 0,
    this.discountAmount = 0,
    this.transportFee = 0,
    this.remainingBalance = 0,
    this.eventDateTime = '',
  });

  final String id;
  final String weddingPlanId;
  final String vendorCategory;
  final String vendorName;
  final String vendorPhone;
  final String vendorInstagram;
  final String companyId;
  final String agendaId;
  final String packageName;
  final double agreedPrice;
  final double dpPaid;
  final String paymentStatus;
  final String dueDate;
  final String notes;
  final String sourceType;
  final bool isSyncedAgenda;
  final String companyLogo;
  final String agendaStatus;
  final String formToken;
  final String formStatus;
  final String modelName;
  final double subtotalDecor;
  final double discountAmount;
  final double transportFee;
  final double remainingBalance;
  final String eventDateTime;

  factory WeddingPlanVendorItem.fromJson(Map<String, dynamic> json) {
    final agreed = (json['agreed_price'] as num?)?.toDouble() ?? 0.0;
    final dp = (json['dp_paid'] as num?)?.toDouble() ?? 0.0;
    final fallbackRemaining = (agreed - dp) > 0 ? (agreed - dp) : 0.0;

    return WeddingPlanVendorItem(
      id: json['id']?.toString() ?? '',
      weddingPlanId: json['wedding_plan_id']?.toString() ?? '',
      vendorCategory: json['vendor_category']?.toString() ?? 'other',
      vendorName: json['vendor_name']?.toString() ?? '',
      vendorPhone: json['vendor_phone']?.toString() ?? '',
      vendorInstagram: json['vendor_instagram']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      agendaId: json['agenda_id']?.toString() ?? '',
      packageName: json['package_name']?.toString() ?? '',
      agreedPrice: agreed,
      dpPaid: dp,
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      dueDate: json['due_date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      sourceType: json['source_type']?.toString() ?? 'manual',
      isSyncedAgenda: json['is_synced_agenda'] as bool? ?? false,
      companyLogo: json['company_logo']?.toString() ?? '',
      agendaStatus: json['agenda_status']?.toString() ?? '',
      formToken: json['form_token']?.toString() ?? '',
      formStatus: json['form_status']?.toString() ?? '',
      modelName: json['model_name']?.toString() ?? '',
      subtotalDecor: (json['subtotal_decor'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      transportFee: (json['transport_fee'] as num?)?.toDouble() ?? 0.0,
      remainingBalance: (json['remaining_balance'] as num?)?.toDouble() ?? fallbackRemaining,
      eventDateTime: json['event_date_time']?.toString() ?? '',
    );
  }
}

class WeddingTaskItem {
  const WeddingTaskItem({
    required this.id,
    this.weddingPlanId = '',
    this.title = '',
    this.category = 'Lainnya',
    this.phase = 'Persiapan',
    this.dueDate = '',
    this.isCompleted = false,
    this.notes = '',
    this.sortOrder = 0,
  });

  final String id;
  final String weddingPlanId;
  final String title;
  final String category;
  final String phase;
  final String dueDate;
  final bool isCompleted;
  final String notes;
  final int sortOrder;

  WeddingTaskItem copyWith({
    String? title,
    String? category,
    String? phase,
    String? dueDate,
    bool? isCompleted,
    String? notes,
  }) {
    return WeddingTaskItem(
      id: id,
      weddingPlanId: weddingPlanId,
      title: title ?? this.title,
      category: category ?? this.category,
      phase: phase ?? this.phase,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      sortOrder: sortOrder,
    );
  }

  factory WeddingTaskItem.fromJson(Map<String, dynamic> json) {
    return WeddingTaskItem(
      id: json['id']?.toString() ?? '',
      weddingPlanId: json['wedding_plan_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Lainnya',
      phase: json['phase']?.toString() ?? 'Persiapan',
      dueDate: json['due_date']?.toString() ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      notes: json['notes']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class PublicVendorSummary {
  const PublicVendorSummary({
    required this.id,
    this.name = '',
    this.category = 'decoration',
    this.city = '',
    this.address = '',
    this.phone = '',
    this.instagram = '',
    this.logoUrl = '',
    this.description = '',
    this.packageCount = 0,
    this.modelCount = 0,
    this.minPrice = 0,
    this.sampleImages = const [],
  });

  final String id;
  final String name;
  final String category;
  final String city;
  final String address;
  final String phone;
  final String instagram;
  final String logoUrl;
  final String description;
  final int packageCount;
  final int modelCount;
  final double minPrice;
  final List<String> sampleImages;

  factory PublicVendorSummary.fromJson(Map<String, dynamic> json) {
    return PublicVendorSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'decoration',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      instagram: json['instagram']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      packageCount: (json['package_count'] as num?)?.toInt() ?? 0,
      modelCount: (json['model_count'] as num?)?.toInt() ?? 0,
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0.0,
      sampleImages: (json['sample_images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }
}

class PublicVendorPackageItem {
  const PublicVendorPackageItem({
    required this.id,
    this.brandName = '',
    this.name = '',
    this.imageUrl = '',
    this.description = '',
    this.basePrice = 0,
  });

  final String id;
  final String brandName;
  final String name;
  final String imageUrl;
  final String description;
  final double basePrice;

  factory PublicVendorPackageItem.fromJson(Map<String, dynamic> json) {
    return PublicVendorPackageItem(
      id: json['id']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PublicVendorModelItem {
  const PublicVendorModelItem({
    required this.id,
    this.name = '',
    this.imageUrl = '',
    this.width = '',
    this.price = 0,
    this.description = '',
  });

  final String id;
  final String name;
  final String imageUrl;
  final String width;
  final double price;
  final String description;

  factory PublicVendorModelItem.fromJson(Map<String, dynamic> json) {
    return PublicVendorModelItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      width: json['width']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
    );
  }
}

class PublicVendorDetail {
  const PublicVendorDetail({
    required this.summary,
    this.email = '',
    this.packages = const [],
    this.models = const [],
  });

  final PublicVendorSummary summary;
  final String email;
  final List<PublicVendorPackageItem> packages;
  final List<PublicVendorModelItem> models;

  factory PublicVendorDetail.fromJson(Map<String, dynamic> json) {
    final pkgList = json['packages'] as List<dynamic>? ?? const [];
    final modelList = json['models'] as List<dynamic>? ?? const [];

    return PublicVendorDetail(
      summary: PublicVendorSummary.fromJson(json),
      email: json['email']?.toString() ?? '',
      packages: pkgList
          .whereType<Map<String, dynamic>>()
          .map(PublicVendorPackageItem.fromJson)
          .toList(),
      models: modelList
          .whereType<Map<String, dynamic>>()
          .map(PublicVendorModelItem.fromJson)
          .toList(),
    );
  }
}
