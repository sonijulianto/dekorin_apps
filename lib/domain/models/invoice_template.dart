enum InvoiceTemplate {
  modernNavy(
    id: 'template_modern_navy',
    name: 'Modern Navy & Gold',
    subtitle: 'Elegan & Beraksen Mewah',
    description: 'Format faktur formal dengan ornamen heksagonal modern, palet warna navy blue & emas, serta tanda tangan resmi.',
    accentHex: 0xFF1C3B57,
  ),
  minimalistGrey(
    id: 'template_minimalist_grey',
    name: 'Minimalist Modern Grey',
    subtitle: 'Bersih & Monokrom Minimalis',
    description: 'Format faktur simpel modern dengan header chevron abu-abu monokrom, baris rincian tegas, dan kalkulasi tagihan praktis.',
    accentHex: 0xFF4A5568,
  );

  final String id;
  final String name;
  final String subtitle;
  final String description;
  final int accentHex;

  const InvoiceTemplate({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.accentHex,
  });

  static InvoiceTemplate fromId(String? id) {
    final trimmed = id?.trim() ?? '';
    return InvoiceTemplate.values.firstWhere(
      (t) => t.id == trimmed,
      orElse: () => InvoiceTemplate.modernNavy,
    );
  }
}

/// Konfigurasi template invoice perusahaan & per sub-brand dari database.
class CompanyInvoiceTemplateConfig {
  final String brandId;
  final InvoiceTemplate invoiceTemplate;
  final InvoiceTemplate companyInvoiceTemplate;
  final bool isInherited;
  final Map<String, InvoiceTemplate> brandTemplates;
  final Set<String> inheritedBrandIds;

  const CompanyInvoiceTemplateConfig({
    this.brandId = '',
    this.invoiceTemplate = InvoiceTemplate.modernNavy,
    this.companyInvoiceTemplate = InvoiceTemplate.modernNavy,
    this.isInherited = false,
    this.brandTemplates = const {'': InvoiceTemplate.modernNavy},
    this.inheritedBrandIds = const {},
  });

  factory CompanyInvoiceTemplateConfig.fromJson(Map<String, dynamic> json) {
    final companyTmpl = InvoiceTemplate.fromId(
      json['company_invoice_template'] as String? ?? json['invoice_template'] as String?,
    );
    final selectedTmpl = InvoiceTemplate.fromId(
      json['invoice_template'] as String? ?? companyTmpl.id,
    );

    final parsedBrandTemplates = <String, InvoiceTemplate>{
      '': companyTmpl,
    };
    final rawMap = json['brand_templates'];
    if (rawMap is Map) {
      rawMap.forEach((key, value) {
        parsedBrandTemplates[key.toString()] = InvoiceTemplate.fromId(value?.toString());
      });
    }

    final parsedInherited = <String>{};
    final rawInherited = json['inherited_brands'];
    if (rawInherited is List) {
      for (final item in rawInherited) {
        final id = item?.toString().trim() ?? '';
        if (id.isNotEmpty) {
          parsedInherited.add(id);
        }
      }
    }

    return CompanyInvoiceTemplateConfig(
      brandId: json['brand_id'] as String? ?? '',
      invoiceTemplate: selectedTmpl,
      companyInvoiceTemplate: companyTmpl,
      isInherited: json['is_inherited'] as bool? ?? false,
      brandTemplates: parsedBrandTemplates,
      inheritedBrandIds: parsedInherited,
    );
  }
}
