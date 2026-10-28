/// Model untuk Master Properti Dekorasi & Alat Kerja
class Property {
  final String id;
  final String companyId;
  final String name;
  final String category;
  final String type; // 'property' atau 'tool'
  final bool trackStock; // true = cek stok tanggal, false = bebas bawa
  final int totalStock;
  final String unit;
  final String notes;
  final String imageUrl;
  final int sortOrder;

  const Property({
    required this.id,
    this.companyId = 'cmp_default',
    required this.name,
    this.category = 'Lainnya',
    this.type = 'property',
    this.trackStock = true,
    this.totalStock = 1,
    this.unit = 'pcs',
    this.notes = '',
    this.imageUrl = '',
    this.sortOrder = 0,
  });

  bool get isTool => type.toLowerCase() == 'tool' || !trackStock;
  bool get isProperty => !isTool;

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? 'cmp_default',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? (json['type'] == 'tool' ? 'Alat Kerja' : 'Lainnya'),
      type: json['type'] as String? ?? 'property',
      trackStock: json['track_stock'] as bool? ?? (json['type'] != 'tool'),
      totalStock: (json['total_stock'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String? ?? 'pcs',
      notes: json['notes'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'category': category,
      'type': type,
      'track_stock': trackStock,
      'total_stock': totalStock,
      'unit': unit,
      'notes': notes,
      'image_url': imageUrl,
      'sort_order': sortOrder,
    };
  }
}

/// Template Properti bawaan Model Dekorasi
class DecorationModelProperty {
  final String id;
  final String companyId;
  final String decorationModelId;
  final String propertyId;
  final int defaultQty;
  final String notes;
  final Property? property;

  const DecorationModelProperty({
    required this.id,
    this.companyId = 'cmp_default',
    required this.decorationModelId,
    required this.propertyId,
    this.defaultQty = 1,
    this.notes = '',
    this.property,
  });

  factory DecorationModelProperty.fromJson(Map<String, dynamic> json) {
    return DecorationModelProperty(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? 'cmp_default',
      decorationModelId: json['decoration_model_id'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',
      defaultQty: (json['default_qty'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String? ?? '',
      property: json['property'] != null ? Property.fromJson(json['property'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'decoration_model_id': decorationModelId,
      'property_id': propertyId,
      'default_qty': defaultQty,
      'notes': notes,
    };
  }
}

/// Pick List Item per Agenda (Paperless Checklist)
class AgendaProperty {
  final String id;
  final String companyId;
  final String agendaId;
  final String propertyId;
  final String customName;
  final int qty;
  final String notes;
  final bool isPacked;
  final bool isReturned;
  final Property? property;

  const AgendaProperty({
    required this.id,
    this.companyId = 'cmp_default',
    required this.agendaId,
    required this.propertyId,
    this.customName = '',
    this.qty = 1,
    this.notes = '',
    this.isPacked = false,
    this.isReturned = false,
    this.property,
  });

  String get displayName => customName.isNotEmpty ? customName : (property?.name ?? 'Item Tanpa Nama');
  String get unit => property?.unit ?? 'pcs';
  bool get isTool => property?.isTool ?? false;
  String get category => property?.category ?? (isTool ? 'Alat Kerja' : 'Properti');

  AgendaProperty copyWith({
    String? id,
    String? companyId,
    String? agendaId,
    String? propertyId,
    String? customName,
    int? qty,
    String? notes,
    bool? isPacked,
    bool? isReturned,
    Property? property,
  }) {
    return AgendaProperty(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      agendaId: agendaId ?? this.agendaId,
      propertyId: propertyId ?? this.propertyId,
      customName: customName ?? this.customName,
      qty: qty ?? this.qty,
      notes: notes ?? this.notes,
      isPacked: isPacked ?? this.isPacked,
      isReturned: isReturned ?? this.isReturned,
      property: property ?? this.property,
    );
  }

  factory AgendaProperty.fromJson(Map<String, dynamic> json) {
    return AgendaProperty(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? 'cmp_default',
      agendaId: json['agenda_id'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',
      customName: json['custom_name'] as String? ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String? ?? '',
      isPacked: json['is_packed'] as bool? ?? false,
      isReturned: json['is_returned'] as bool? ?? false,
      property: json['property'] != null ? Property.fromJson(json['property'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'agenda_id': agendaId,
      'property_id': propertyId,
      'custom_name': customName,
      'qty': qty,
      'notes': notes,
      'is_packed': isPacked,
      'is_returned': isReturned,
    };
  }
}

/// Ketersediaan Properti pada Tanggal Tertentu
class PropertyAvailability {
  final Property property;
  final int bookedQty;
  final int availableQty;
  final bool isAvailable;

  const PropertyAvailability({
    required this.property,
    required this.bookedQty,
    required this.availableQty,
    required this.isAvailable,
  });

  factory PropertyAvailability.fromJson(Map<String, dynamic> json) {
    return PropertyAvailability(
      property: Property.fromJson(json),
      bookedQty: (json['booked_qty'] as num?)?.toInt() ?? 0,
      availableQty: (json['available_qty'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}
