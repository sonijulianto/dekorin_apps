class FormFieldDefinition {
  const FormFieldDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.placeholder = '',
    this.options = const [],
    this.isSystem = false,
    this.isActive = true,
    this.isRequired = false,
    this.sortOrder = 0,
  });

  final String key;
  final String label;
  final String type;
  final String placeholder;
  final List<String> options;
  final bool isSystem;
  final bool isActive;
  final bool isRequired;
  final int sortOrder;

  factory FormFieldDefinition.fromJson(Map<String, dynamic> json) {
    final rawOpts = json['options'];
    final opts = <String>[];
    if (rawOpts is List) {
      for (final item in rawOpts) {
        if (item != null && item.toString().trim().isNotEmpty) {
          opts.add(item.toString().trim());
        }
      }
    }

    return FormFieldDefinition(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      placeholder: json['placeholder'] as String? ?? '',
      options: opts,
      isSystem: json['is_system'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isRequired: json['is_required'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type,
      'placeholder': placeholder,
      'options': options,
      'is_system': isSystem,
      'is_active': isActive,
      'is_required': isRequired,
      'sort_order': sortOrder,
    };
  }

  FormFieldDefinition copyWith({
    String? key,
    String? label,
    String? type,
    String? placeholder,
    List<String>? options,
    bool? isSystem,
    bool? isActive,
    bool? isRequired,
    int? sortOrder,
  }) {
    return FormFieldDefinition(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      placeholder: placeholder ?? this.placeholder,
      options: options ?? this.options,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      isRequired: isRequired ?? this.isRequired,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  String get typeDisplayLabel {
    switch (type) {
      case 'text':
        return 'Teks Singkat';
      case 'textarea':
        return 'Paragraf';
      case 'number':
        return 'Angka';
      case 'date':
        return 'Tanggal';
      case 'time':
        return 'Jam';
      case 'datetime':
        return 'Tanggal & Jam';
      case 'select':
        return 'Dropdown';
      case 'radio':
        return 'Pilihan Tunggal';
      case 'checkbox':
        return 'Centang Ganda';
      case 'image':
        return 'Upload Foto';
      case 'maps':
        return 'Google Maps';
      case 'package_picker':
        return 'Pilih Paket';
      case 'model_picker':
        return 'Pilih Model';
      case 'addon_picker':
        return 'Pilih Addon';
      default:
        return type;
    }
  }
}

class FormTemplateSummary {
  const FormTemplateSummary({
    required this.eventType,
    required this.eventLabel,
    this.isSystemPreset = true,
    this.isCustomized = false,
    this.showPrice = true,
  });

  final String eventType;
  final String eventLabel;
  final bool isSystemPreset;
  final bool isCustomized;
  final bool showPrice;

  static const List<FormTemplateSummary> builtInDefaults = [
    FormTemplateSummary(eventType: '', eventLabel: 'Umum (Default)'),
    FormTemplateSummary(eventType: 'wedding', eventLabel: 'Wedding'),
    FormTemplateSummary(eventType: 'lamaran', eventLabel: 'Lamaran'),
    FormTemplateSummary(eventType: 'birthday', eventLabel: 'Ulang Tahun'),
    FormTemplateSummary(eventType: 'aqiqah', eventLabel: 'Aqiqah'),
  ];

  static String resolveLabel(String eventType, [String fallbackLabel = '']) {
    final norm = eventType.trim().toLowerCase();
    for (final item in builtInDefaults) {
      if (item.eventType == norm) return item.eventLabel;
    }
    if (fallbackLabel.trim().isNotEmpty) return fallbackLabel.trim();
    if (norm.isEmpty) return 'Umum (Default)';
    final cleaned = norm.replaceFirst('custom_', '').replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'Jenis Acara Khusus';
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  factory FormTemplateSummary.fromJson(Map<String, dynamic> json) {
    final et = (json['event_type'] as String? ?? '').trim();
    final el = (json['event_label'] as String? ?? '').trim();
    return FormTemplateSummary(
      eventType: et,
      eventLabel: resolveLabel(et, el),
      isSystemPreset: json['is_system_preset'] as bool? ?? true,
      isCustomized: json['is_customized'] as bool? ?? false,
      showPrice: json['show_price'] as bool? ?? true,
    );
  }
}

class CompanyFormConfig {
  const CompanyFormConfig({
    this.id = '',
    this.companyId = '',
    this.brandId = '',
    this.eventType = '',
    this.eventLabel = '',
    this.showPrice = true,
    this.fields = const [],
    this.isInherited = false,
  });

  final String id;
  final String companyId;
  final String brandId;
  final String eventType;
  final String eventLabel;
  final bool showPrice;
  final List<FormFieldDefinition> fields;
  final bool isInherited;

  factory CompanyFormConfig.fromJson(Map<String, dynamic> json, {bool isInherited = false}) {
    final rawFields = json['fields'];
    final parsedFields = <FormFieldDefinition>[];
    if (rawFields is List) {
      for (final f in rawFields) {
        if (f is Map<String, dynamic>) {
          parsedFields.add(FormFieldDefinition.fromJson(f));
        }
      }
    }

    final et = (json['event_type'] as String? ?? '').trim();
    final el = (json['event_label'] as String? ?? '').trim();

    return CompanyFormConfig(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      brandId: json['brand_id'] as String? ?? '',
      eventType: et,
      eventLabel: FormTemplateSummary.resolveLabel(et, el),
      showPrice: json['show_price'] as bool? ?? true,
      fields: parsedFields,
      isInherited: isInherited,
    );
  }
}
