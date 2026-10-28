/// Model domain untuk profil badan usaha vendor dekorasi.
class CompanyProfile {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String logoUrl;
  final String description;
  final String instagram;
  final String bankInfo;
  final String updatedBy;
  final String updatedByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyProfile({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.logoUrl = '',
    this.description = '',
    this.instagram = '',
    this.bankInfo = '',
    this.updatedBy = '',
    this.updatedByName = '',
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      bankInfo: json['bank_info'] as String? ?? '',
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
      'address': address,
      'phone': phone,
      'email': email,
      'logo_url': logoUrl,
      'description': description,
      'instagram': instagram,
      'bank_info': bankInfo,
      'updated_by': updatedBy,
      'updated_by_name': updatedByName,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CompanyProfile copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? description,
    String? instagram,
    String? bankInfo,
    String? updatedBy,
    String? updatedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      instagram: instagram ?? this.instagram,
      bankInfo: bankInfo ?? this.bankInfo,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model domain untuk Sub-Brand / Multi-Brand di bawah satu badan usaha (Company).
/// Rekening bank & alamat tetap mengikuti Company utama, sedangkan nama, logo,
/// deskripsi, WhatsApp, dan Instagram dapat berbeda untuk tiap brand.
class CompanyBrand {
  final String id;
  final String companyId;
  final String name;
  final String logoUrl;
  final String description;
  final String phone;
  final String instagram;
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
