class CustomFormAnswer {
  const CustomFormAnswer({
    required this.key,
    required this.label,
    required this.type,
    required this.value,
  });

  final String key;
  final String label;
  final String type;
  final String value;

  factory CustomFormAnswer.fromJson(Map<String, dynamic> json) {
    return CustomFormAnswer(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type,
      'value': value,
    };
  }
}

class ClientFormModel {
  const ClientFormModel({
    required this.id,
    required this.agendaId,
    required this.eventAddress,
    required this.decorationTheme,
    required this.colorPreference,
    required this.specialRequests,
    required this.referencePhotoUrl,
    this.packageId = '',
    this.packageName = '',
    this.packagePrice = 0.0,
    this.selectedAddons = '',
    this.addonsPrice = 0.0,
    this.totalPrice = 0.0,
    this.customAnswers = const [],
    this.submittedAt,
  });

  final String id;
  final String agendaId;
  final String eventAddress;
  final String decorationTheme;
  final String colorPreference;
  final String specialRequests;
  final String referencePhotoUrl;
  final String packageId;
  final String packageName;
  final double packagePrice;
  final String selectedAddons;
  final double addonsPrice;
  final double totalPrice;
  final List<CustomFormAnswer> customAnswers;
  final DateTime? submittedAt;

  factory ClientFormModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedSubmitted;
    if (json['submitted_at'] != null) {
      try {
        parsedSubmitted = DateTime.parse(json['submitted_at'] as String);
      } catch (_) {}
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final rawCustom = json['custom_answers'];
    final customAnswers = <CustomFormAnswer>[];
    if (rawCustom is List) {
      for (final item in rawCustom) {
        if (item is Map<String, dynamic>) {
          customAnswers.add(CustomFormAnswer.fromJson(item));
        }
      }
    }

    return ClientFormModel(
      id: json['id'] as String? ?? '',
      agendaId: json['agenda_id'] as String? ?? '',
      eventAddress: json['event_address'] as String? ?? '',
      decorationTheme: json['decoration_theme'] as String? ?? '',
      colorPreference: json['color_preference'] as String? ?? '',
      specialRequests: json['special_requests'] as String? ?? '',
      referencePhotoUrl: json['reference_photo_url'] as String? ?? '',
      packageId: json['package_id'] as String? ?? '',
      packageName: json['package_name'] as String? ?? '',
      packagePrice: parseDouble(json['package_price']),
      selectedAddons: json['selected_addons'] as String? ?? '',
      addonsPrice: parseDouble(json['addons_price']),
      totalPrice: parseDouble(json['total_price']),
      customAnswers: customAnswers,
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
      'package_id': packageId,
      'package_name': packageName,
      'package_price': packagePrice,
      'selected_addons': selectedAddons,
      'addons_price': addonsPrice,
      'total_price': totalPrice,
      'submitted_at': submittedAt?.toIso8601String(),
    };
  }
}

class AgendaItem {
  const AgendaItem({
    required this.id,
    this.brandId = '',
    this.brandName = '',
    this.brandLogo = '',
    this.brandPhone = '',
    this.brandInstagram = '',
    this.brandDescription = '',
    this.eventType = '',
    this.eventLabel = '',
    required this.clientName,
    this.clientPhone = '',
    required this.backdropTitle,
    required this.eventDateTime,
    this.eventAddress = '',
    required this.mapsUrl,
    required this.packageId,
    required this.packageName,
    this.packagePrice = 0.0,
    this.modelId = '',
    this.modelName = '',
    this.modelWidth = '',
    this.modelImageUrl = '',
    this.modelAdditionalPrice = 0.0,
    this.discountType = 'amount',
    this.discountValue = 0.0,
    this.transportFee = 0.0,
    this.status = 'upcoming',
    this.paymentStatus = 'unpaid',
    this.formToken = '',
    this.formStatus = 'pending',
    this.isFormDraft = false,
    this.dpAmount = 0.0,
    this.notes = '',
    this.clientForm,
    this.createdAt,
  });

  final String id;
  final String brandId;
  final String brandName;
  final String brandLogo;
  final String brandPhone;
  final String brandInstagram;
  final String brandDescription;
  final String eventType;
  final String eventLabel;
  final String clientName;
  final String clientPhone;
  final String backdropTitle;
  final DateTime eventDateTime;
  final String eventAddress;
  final String mapsUrl;
  final String packageId;
  final String packageName;
  final double packagePrice;
  final String modelId;
  final String modelName;
  final String modelWidth;
  final String modelImageUrl;
  final double modelAdditionalPrice;
  final String discountType; // 'amount' (Rp) or 'percent' (%)
  final double discountValue;
  final double transportFee;
  final String status;
  final String paymentStatus; // 'unpaid', 'dp', 'paid'
  final String formToken;
  final String formStatus; // 'pending', 'filled'
  final bool isFormDraft;
  final double dpAmount;
  final String notes;
  final ClientFormModel? clientForm;
  final DateTime? createdAt;

  bool get isPaidOff => paymentStatus.toLowerCase() == 'paid';
  bool get isEventCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get hasPackage => packageId.trim().isNotEmpty || packagePrice > 0;
  bool get isStandaloneModel => !hasPackage && (modelId.trim().isNotEmpty || modelName.trim().isNotEmpty);
  String get displayPackageOrModelTitle {
    if (isStandaloneModel) {
      return modelName.trim().isNotEmpty ? modelName.trim() : 'Model Dekorasi';
    }
    if (packageName.trim().isNotEmpty) {
      return packageName.trim();
    }
    return 'Belum Dipilih';
  }
  String get displayAddress => eventAddress.isNotEmpty ? eventAddress : (clientForm?.eventAddress ?? '');
  String get displayEventLabel {
    if (eventLabel.trim().isNotEmpty) return eventLabel.trim();
    switch (eventType.trim().toLowerCase()) {
      case 'wedding':
        return 'Wedding';
      case 'lamaran':
        return 'Lamaran';
      case 'birthday':
        return 'Ulang Tahun';
      case 'aqiqah':
        return 'Aqiqah';
      default:
        return eventType.trim().isEmpty
            ? ''
            : eventType.trim().replaceFirst('custom_', '').replaceAll('_', ' ');
    }
  }

  static String normalizeDiscountType(String? raw) {
    if ((raw ?? '').trim().toLowerCase() == 'percent') {
      return 'percent';
    }
    return 'amount';
  }

  bool get isPercentDiscount => normalizeDiscountType(discountType) == 'percent';

  static double calculateDiscountAmount({
    required double decorSubtotal,
    required String discountType,
    required double discountValue,
  }) {
    if (decorSubtotal <= 0 || discountValue <= 0) return 0.0;
    if (normalizeDiscountType(discountType) == 'percent') {
      final pct = discountValue.clamp(0.0, 100.0);
      return (decorSubtotal * pct / 100.0).roundToDouble();
    }
    return discountValue > decorSubtotal ? decorSubtotal : discountValue;
  }

  static String formatDiscountLabel({
    required String discountType,
    required double discountValue,
    String prefix = 'Diskon',
  }) {
    if (normalizeDiscountType(discountType) == 'percent' && discountValue > 0) {
      final clamped = discountValue.clamp(0.0, 100.0);
      final pctText = clamped == clamped.roundToDouble()
          ? clamped.toInt().toString()
          : clamped.toStringAsFixed(1);
      return '$prefix ($pctText%)';
    }
    return prefix;
  }

  static double parseAddonsTotalFromNotes(String rawNotes) {
    const addonTag = '[Item Tambahan / Addon]:';
    if (!rawNotes.contains(addonTag)) return 0.0;
    final parts = rawNotes.split(addonTag);
    if (parts.length < 2) return 0.0;
    double total = 0.0;
    final lines = parts[1].trim().split('\n');
    for (var line in lines) {
      if (line.contains('(') && line.contains(')')) {
        final openIdx = line.indexOf('(');
        final closeIdx = line.lastIndexOf(')');
        final pStr = line.substring(openIdx + 1, closeIdx);
        if (pStr.contains('=')) {
          final val = double.tryParse(pStr.split('=')[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
          total += val;
        } else {
          final val = double.tryParse(pStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
          total += val;
        }
      }
    }
    return total;
  }

  double get effectivePackagePrice {
    if (packagePrice > 0) return packagePrice;
    if (clientForm != null && clientForm!.packagePrice > 0) {
      return clientForm!.packagePrice;
    }
    return 0.0;
  }

  double get effectiveAddonsPrice {
    if (clientForm != null && clientForm!.addonsPrice > 0) {
      return clientForm!.addonsPrice;
    }
    return parseAddonsTotalFromNotes(notes);
  }

  double get calculatedDecorSubtotal {
    if (clientForm != null && clientForm!.totalPrice > 0) {
      return modelAdditionalPrice + clientForm!.totalPrice;
    }
    return effectivePackagePrice + modelAdditionalPrice + effectiveAddonsPrice;
  }

  double get calculatedDiscountAmount => calculateDiscountAmount(
        decorSubtotal: calculatedDecorSubtotal,
        discountType: discountType,
        discountValue: discountValue,
      );

  double get calculatedTotalPrice {
    final netDecor = (calculatedDecorSubtotal - calculatedDiscountAmount).clamp(0.0, double.infinity);
    return netDecor + transportFee;
  }

  double get calculatedRemainingPayment =>
      (calculatedTotalPrice - dpAmount).clamp(0.0, double.infinity);

  AgendaItem copyWith({
    String? id,
    String? brandId,
    String? brandName,
    String? brandLogo,
    String? brandPhone,
    String? brandInstagram,
    String? brandDescription,
    String? eventType,
    String? eventLabel,
    String? clientName,
    String? clientPhone,
    String? backdropTitle,
    DateTime? eventDateTime,
    String? eventAddress,
    String? mapsUrl,
    String? packageId,
    String? packageName,
    double? packagePrice,
    String? modelId,
    String? modelName,
    String? modelWidth,
    String? modelImageUrl,
    double? modelAdditionalPrice,
    String? discountType,
    double? discountValue,
    double? transportFee,
    String? status,
    String? paymentStatus,
    String? formToken,
    String? formStatus,
    bool? isFormDraft,
    double? dpAmount,
    String? notes,
    ClientFormModel? clientForm,
    DateTime? createdAt,
  }) {
    return AgendaItem(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      brandLogo: brandLogo ?? this.brandLogo,
      brandPhone: brandPhone ?? this.brandPhone,
      brandInstagram: brandInstagram ?? this.brandInstagram,
      brandDescription: brandDescription ?? this.brandDescription,
      eventType: eventType ?? this.eventType,
      eventLabel: eventLabel ?? this.eventLabel,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      backdropTitle: backdropTitle ?? this.backdropTitle,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      eventAddress: eventAddress ?? this.eventAddress,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      packagePrice: packagePrice ?? this.packagePrice,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      modelWidth: modelWidth ?? this.modelWidth,
      modelImageUrl: modelImageUrl ?? this.modelImageUrl,
      modelAdditionalPrice: modelAdditionalPrice ?? this.modelAdditionalPrice,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      transportFee: transportFee ?? this.transportFee,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      formToken: formToken ?? this.formToken,
      formStatus: formStatus ?? this.formStatus,
      isFormDraft: isFormDraft ?? this.isFormDraft,
      dpAmount: dpAmount ?? this.dpAmount,
      notes: notes ?? this.notes,
      clientForm: clientForm ?? this.clientForm,
      createdAt: createdAt ?? this.createdAt,
    );
  }


  static DateTime? _parseValidDateTime(dynamic raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null || parsed.year <= 1970) return null;
    return parsed;
  }

  factory AgendaItem.fromJson(
    Map<String, dynamic> json, {
    DateTime? fallbackEventDateTime,
  }) {
    final rawClientForm = json['client_form'];
    final parsedDate = _parseValidDateTime(json['event_date_time']) ??
        (rawClientForm is Map<String, dynamic>
            ? _parseValidDateTime(rawClientForm['event_date_time'])
            : null) ??
        fallbackEventDateTime ??
        DateTime.now();

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      try {
        parsedCreatedAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }

    ClientFormModel? parsedForm;
    if (json['client_form'] != null && json['client_form'] is Map<String, dynamic>) {
      parsedForm = ClientFormModel.fromJson(json['client_form'] as Map<String, dynamic>);
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return AgendaItem(
      id: json['id'] as String? ?? '',
      brandId: json['brand_id'] as String? ?? '',
      brandName: json['brand_name'] as String? ?? '',
      brandLogo: json['brand_logo'] as String? ?? '',
      brandPhone: json['brand_phone'] as String? ?? '',
      brandInstagram: json['brand_instagram'] as String? ?? '',
      brandDescription: json['brand_description'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      eventLabel: json['event_label'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      clientPhone: json['client_phone'] as String? ?? '',
      backdropTitle: json['backdrop_title'] as String? ?? '',
      eventDateTime: parsedDate,
      eventAddress: json['event_address'] as String? ?? parsedForm?.eventAddress ?? '',
      mapsUrl: json['maps_url'] as String? ?? '',
      packageId: json['package_id'] as String? ?? '',
      packageName: json['package_name'] as String? ?? '',
      packagePrice: parseDouble(json['package_price']),
      modelId: json['model_id'] as String? ?? '',
      modelName: json['model_name'] as String? ?? '',
      modelWidth: json['model_width'] as String? ?? '',
      modelImageUrl: json['model_image_url'] as String? ?? '',
      modelAdditionalPrice: parseDouble(json['model_additional_price']),
      discountType: normalizeDiscountType(json['discount_type'] as String?),
      discountValue: parseDouble(json['discount_value']),
      transportFee: parseDouble(json['transport_fee']),
      status: json['status'] as String? ?? 'upcoming',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      formToken: json['form_token'] as String? ?? '',
      formStatus: json['form_status'] as String? ?? 'pending',
      isFormDraft: json['is_form_draft'] as bool? ?? false,
      dpAmount: parseDouble(json['dp_amount']),
      notes: json['notes'] as String? ?? '',
      clientForm: parsedForm,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand_id': brandId,
      'brand_name': brandName,
      'brand_logo': brandLogo,
      'brand_phone': brandPhone,
      'brand_instagram': brandInstagram,
      'brand_description': brandDescription,
      'event_type': eventType,
      'event_label': eventLabel,
      'client_name': clientName,
      'client_phone': clientPhone,
      'backdrop_title': backdropTitle,
      'event_date_time': eventDateTime.toIso8601String(),
      'event_address': eventAddress,
      'maps_url': mapsUrl,
      'package_id': packageId,
      'package_name': packageName,
      'package_price': packagePrice,
      'model_id': modelId,
      'model_name': modelName,
      'model_width': modelWidth,
      'model_image_url': modelImageUrl,
      'model_additional_price': modelAdditionalPrice,
      'discount_type': normalizeDiscountType(discountType),
      'discount_value': discountValue,
      'transport_fee': transportFee,
      'status': status,
      'payment_status': paymentStatus,
      'form_token': formToken,
      'form_status': formStatus,
      'is_form_draft': isFormDraft,
      'dp_amount': dpAmount,
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
