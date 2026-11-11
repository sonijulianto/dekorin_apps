/// Daftar kategori usaha vendor resmi di Dekorin (mendukung multi-kategori).
class VendorCategoryOption {
  const VendorCategoryOption({
    required this.id,
    required this.label,
    required this.shortLabel,
  });

  final String id;
  final String label;
  final String shortLabel;

  static const List<VendorCategoryOption> all = [
    VendorCategoryOption(id: 'decoration', label: 'Dekorasi & Pelaminan', shortLabel: 'Dekorasi'),
    VendorCategoryOption(id: 'wo', label: 'Wedding Organizer (WO)', shortLabel: 'WO'),
    VendorCategoryOption(id: 'mua', label: 'MUA & Rias Pengantin', shortLabel: 'MUA'),
    VendorCategoryOption(id: 'photo_video', label: 'Fotografi & Videografi', shortLabel: 'Foto & Video'),
    VendorCategoryOption(id: 'catering', label: 'Katering & Konsumsi', shortLabel: 'Catering'),
    VendorCategoryOption(id: 'attire', label: 'Busana & Gaun Pengantin', shortLabel: 'Busana'),
    VendorCategoryOption(id: 'entertainment', label: 'MC, Musik & Hiburan', shortLabel: 'MC & Hiburan'),
    VendorCategoryOption(id: 'venue', label: 'Venue & Gedung Acara', shortLabel: 'Venue'),
    VendorCategoryOption(id: 'other', label: 'Vendor & Kebutuhan Lain', shortLabel: 'Lainnya'),
  ];

  static VendorCategoryOption byId(String id) {
    final normalized = id.trim().toLowerCase();
    return all.firstWhere(
      (item) => item.id == normalized,
      orElse: () => all.last,
    );
  }
}

/// Model domain untuk profil badan usaha vendor.
class CompanyProfile {
  final String id;
  final String name;
  final String category;
  final String city;
  final bool isPublicListed;
  final String address;
  final String phone;
  final String email;
  final String logoUrl;
  final String description;
  final String instagram;
  final String bankInfo;
  final String invoiceTemplate;
  final String updatedBy;
  final String updatedByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyProfile({
    required this.id,
    required this.name,
    this.category = 'decoration',
    this.city = '',
    this.isPublicListed = false,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.logoUrl = '',
    this.description = '',
    this.instagram = '',
    this.bankInfo = '',
    this.invoiceTemplate = 'template_modern_navy',
    this.updatedBy = '',
    this.updatedByName = '',
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    final rawTmpl = (json['invoice_template'] as String? ?? '').trim();
    final rawCategory = (json['category'] as String? ?? '').trim();
    return CompanyProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: rawCategory.isNotEmpty ? rawCategory : 'decoration',
      city: json['city'] as String? ?? '',
      isPublicListed: json['is_public_listed'] as bool? ?? false,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      bankInfo: json['bank_info'] as String? ?? '',
      invoiceTemplate: rawTmpl.isNotEmpty ? rawTmpl : 'template_modern_navy',
      updatedBy: json['updated_by'] as String? ?? '',
      updatedByName: json['updated_by_name'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'city': city,
      'is_public_listed': isPublicListed,
      'address': address,
      'phone': phone,
      'email': email,
      'logo_url': logoUrl,
      'description': description,
      'instagram': instagram,
      'bank_info': bankInfo,
      'invoice_template': invoiceTemplate,
      'updated_by': updatedBy,
      'updated_by_name': updatedByName,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CompanyProfile copyWith({
    String? id,
    String? name,
    String? category,
    String? city,
    bool? isPublicListed,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? description,
    String? instagram,
    String? bankInfo,
    String? invoiceTemplate,
    String? updatedBy,
    String? updatedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      city: city ?? this.city,
      isPublicListed: isPublicListed ?? this.isPublicListed,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      instagram: instagram ?? this.instagram,
      bankInfo: bankInfo ?? this.bankInfo,
      invoiceTemplate: invoiceTemplate ?? this.invoiceTemplate,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model domain untuk Sub-Brand / Multi-Brand di bawah satu badan usaha (Company).
/// Rekening bank & alamat tetap mengikuti Company utama, sedangkan nama, logo,
/// deskripsi, WhatsApp, Instagram, dan template invoice dapat berbeda untuk tiap brand.
class CompanyBrand {
  final String id;
  final String companyId;
  final String name;
  final String logoUrl;
  final String description;
  final String phone;
  final String instagram;
  final String invoiceTemplate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyBrand({
    required this.id,
    this.companyId = '',
    required this.name,
    this.logoUrl = '',
    this.description = '',
    this.phone = '',
    this.instagram = '',
    this.invoiceTemplate = '',
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyBrand.fromJson(Map<String, dynamic> json) {
    return CompanyBrand(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      invoiceTemplate: json['invoice_template'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'logo_url': logoUrl,
      'description': description,
      'phone': phone,
      'instagram': instagram,
      'invoice_template': invoiceTemplate,
    };
  }

  CompanyBrand copyWith({
    String? id,
    String? companyId,
    String? name,
    String? logoUrl,
    String? description,
    String? phone,
    String? instagram,
    String? invoiceTemplate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyBrand(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      instagram: instagram ?? this.instagram,
      invoiceTemplate: invoiceTemplate ?? this.invoiceTemplate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
