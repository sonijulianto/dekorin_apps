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
    return InvoiceTemplate.values.firstWhere(
      (t) => t.id == id,
      orElse: () => InvoiceTemplate.modernNavy,
    );
  }
}
