import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:dekorin_apps/domain/models/agenda.dart';

class InvoiceItemData {
  final int no;
  final String name;
  final String subtitle;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const InvoiceItemData({
    required this.no,
    required this.name,
    this.subtitle = '',
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class InvoicePdfHelper {
  // Fallback harga default master paket jika belum tersimpan di DB
  static const Map<String, double> _fallbackPackagePrices = {
    'pkg_01': 2500000.0,
    'pkg_02': 4000000.0,
    'pkg_03': 9500000.0,
    'pkg_04': 18000000.0,
  };

  static Future<Uint8List> generateInvoicePdf(AgendaItem agenda) async {
    final pdf = pw.Document();

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final form = agenda.clientForm;

    // ── 1. Penentuan Harga Paket ──
    double packagePrice = 0.0;
    final isUnselected = agenda.packageName.toLowerCase().contains('belum dipilih') ||
        (form != null && form.packageName.toLowerCase().contains('belum dipilih'));

    if (isUnselected) {
      packagePrice = 0.0;
    } else if (form != null && form.packagePrice > 0) {
      packagePrice = form.packagePrice;
    } else if (agenda.packagePrice > 0) {
      packagePrice = agenda.packagePrice;
    } else if (_fallbackPackagePrices.containsKey(agenda.packageId)) {
      packagePrice = _fallbackPackagePrices[agenda.packageId]!;
    } else {
      final nameLower = agenda.packageName.toLowerCase();
      if (nameLower.contains('akad') || nameLower.contains('minimalis')) {
        packagePrice = 2500000.0;
      } else if (nameLower.contains('lamaran') || nameLower.contains('rustic')) {
        packagePrice = 4000000.0;
      } else if (nameLower.contains('pernikahan') || nameLower.contains('elegan')) {
        packagePrice = 9500000.0;
      } else if (nameLower.contains('ballroom') || nameLower.contains('luxury')) {
        packagePrice = 18000000.0;
      } else {
        packagePrice = 0.0;
      }
    }

    // ── 2. Ekstraksi Item Addon & Kalkulasi ──
    final List<InvoiceItemData> items = [];
    
    // Item 1: Paket Dekorasi
    items.add(
      InvoiceItemData(
        no: 1,
        name: agenda.packageName.isNotEmpty ? agenda.packageName : 'Paket Dekorasi',
        subtitle: [
          if (agenda.backdropTitle.isNotEmpty) 'Acara: ${agenda.backdropTitle}',
          if (agenda.modelName.isNotEmpty) 'Model: ${agenda.modelName}${agenda.modelWidth.isNotEmpty ? ' (${agenda.modelWidth})' : ''}',
        ].join(' • '),
        quantity: 1,
        unitPrice: packagePrice,
        totalPrice: packagePrice,
      ),
    );

    // Item 2+: Addon
    final addonList = _extractAddonItems(form?.selectedAddons ?? '', agenda.notes, startNo: 2);
    items.addAll(addonList);

    double addonsTotal = 0.0;
    for (final addon in addonList) {
      addonsTotal += addon.totalPrice;
    }
    if (addonsTotal == 0 && form != null && form.addonsPrice > 0) {
      addonsTotal = form.addonsPrice;
    }

    // Kalkulasi Total
    final double subtotal = packagePrice + addonsTotal;
    final double transportFee = agenda.transportFee;
    final double totalTagihan = subtotal + transportFee;
    final double dpAmount = agenda.dpAmount;
    final double grandTotal = (totalTagihan - dpAmount) > 0 ? (totalTagihan - dpAmount) : 0.0;

    // Nomor Invoice & Tanggal
    final invoiceNumber =
        'INV-${agenda.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase()}-${DateFormat('yyMMdd').format(agenda.eventDateTime)}';
    final invoiceDateStr = DateFormat('dd/MM/yy').format(DateTime.now());
    final dueDateStr = DateFormat('dd/MM/yy').format(agenda.eventDateTime);

    // Font Standar Helvetica (100% offline, stabil)
    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    // Warna Identik Desain Referensi
    final navyColor = PdfColor.fromHex('#1C3B57');
    final goldColor = PdfColor.fromHex('#E5B824');
    final textDark = PdfColor.fromHex('#212D38');
    final textGrey = PdfColor.fromHex('#64748B');
    final dividerColor = PdfColor.fromHex('#E2E8F0');

    // SVGs untuk Ornamen Poligon & Hexagon
    const topBannerSvg = '''
<svg viewBox="0 0 210 145" width="210" height="145" xmlns="http://www.w3.org/2000/svg">
  <polygon points="0,0 210,0 210,95 105,145 0,95" fill="#1C3B57"/>
</svg>
''';

    const logoSvg = '''
<svg viewBox="0 0 40 40" width="34" height="34" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 34 L6 18 L14 12 L14 34 Z" fill="none" stroke="#FFFFFF" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M14 34 L14 8 L24 2 L24 34 Z" fill="none" stroke="#FFFFFF" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M24 34 L24 16 L32 22 L32 34 Z" fill="none" stroke="#FFFFFF" stroke-width="2.5" stroke-linejoin="round"/>
  <line x1="2" y1="34" x2="36" y2="34" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round"/>
</svg>
''';

    const topHexagonsSvg = '''
<svg viewBox="0 0 150 130" width="130" height="112" xmlns="http://www.w3.org/2000/svg">
  <polygon points="90,4 135,30 135,82 90,108 45,82 45,30" fill="none" stroke="#1C3B57" stroke-width="2"/>
  <polygon points="90,14 127,35 127,77 90,98 53,77 53,35" fill="none" stroke="#1C3B57" stroke-width="2"/>
  <polygon points="90,24 119,41 119,72 90,89 61,72 61,41" fill="none" stroke="#1C3B57" stroke-width="2"/>
  <polygon points="90,32 112,45 112,69 90,82 68,69 68,45" fill="#E5B824"/>
</svg>
''';

    const bottomHexagonsSvg = '''
<svg viewBox="0 0 160 140" width="125" height="109" xmlns="http://www.w3.org/2000/svg">
  <polygon points="55,8 105,37 105,95 55,124 5,95 5,37" fill="none" stroke="#1C3B57" stroke-width="2.5"/>
  <polygon points="55,20 95,43 95,89 55,112 15,89 15,43" fill="none" stroke="#1C3B57" stroke-width="2.5"/>
  <polygon points="55,32 85,49 85,83 55,100 25,83 25,49" fill="none" stroke="#1C3B57" stroke-width="2"/>
  <polygon points="55,42 75,53 75,77 55,88 35,77 35,53" fill="#E5B824"/>
</svg>
''';

    const noHexagonSvg = '''
<svg viewBox="0 0 46 40" width="44" height="38" xmlns="http://www.w3.org/2000/svg">
  <polygon points="23,2 43,12 43,34 23,38 3,34 3,12" fill="#1C3B57"/>
</svg>
''';

    const signatureSvg = '''
<svg viewBox="0 0 130 50" width="110" height="42" xmlns="http://www.w3.org/2000/svg">
  <path d="M8,36 C18,14 26,6 32,16 C38,26 30,42 45,34 C58,28 62,20 68,34 C74,25 82,22 88,32 C92,26 98,27 106,30 C110,16 112,12 116,32" fill="none" stroke="#1C3B57" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

    // Alamat Klien
    String clientAddress = 'Jl. Lokasi Acara';
    if (form != null && form.eventAddress.isNotEmpty) {
      clientAddress = form.eventAddress;
    } else if (agenda.mapsUrl.isNotEmpty) {
      clientAddress = agenda.mapsUrl;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // ── 1. Top-Left Navy Banner Ornamen ──
              pw.Positioned(
                top: 0,
                left: 0,
                child: pw.SvgImage(
                  svg: topBannerSvg,
                  width: 210,
                  height: 145,
                ),
              ),

              // Logo & Brand Name di dalam Banner
              pw.Positioned(
                top: 28,
                left: 28,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SvgImage(svg: logoSvg, width: 34, height: 34),
                    pw.SizedBox(width: 10),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Dekorin',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 18,
                            color: PdfColors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.Text(
                          'Wedding & Event Decoration',
                          style: pw.TextStyle(
                            font: baseFont,
                            fontSize: 7.5,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 2. Top-Right Hexagon Accent ──
              pw.Positioned(
                top: 0,
                right: 0,
                child: pw.SvgImage(
                  svg: topHexagonsSvg,
                  width: 130,
                  height: 112,
                ),
              ),

              // ── 3. Bottom Accent Bar (Yellow/Gold) ──
              pw.Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: pw.Container(
                  height: 28,
                  color: goldColor,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 42),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '+62 812-3456-7890',
                        style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: navyColor),
                      ),
                      pw.Text(
                        'hello@dekorin.id',
                        style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: navyColor),
                      ),
                      pw.Text(
                        'Jakarta, Indonesia',
                        style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: navyColor),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 4. Bottom-Left Hexagon Accent ──
              pw.Positioned(
                bottom: 0,
                left: 0,
                child: pw.SvgImage(
                  svg: bottomHexagonsSvg,
                  width: 125,
                  height: 109,
                ),
              ),

              // ── 5. Konten Utama Invoice ──
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(42, 40, 42, 36),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header Row: Kanan INVOICE & Nomor
                    pw.Align(
                      alignment: pw.Alignment.topRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'INVOICE',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 38,
                              color: navyColor,
                              letterSpacing: 2.5,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Number : $invoiceNumber',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 10.5,
                              color: navyColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 52),

                    // Baris Informasi Klien & Tanggal
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Kiri: Invoice To
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Invoice To:',
                              style: pw.TextStyle(font: baseFont, fontSize: 11, color: textGrey),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              agenda.clientName,
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 14,
                                color: navyColor,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.ConstrainedBox(
                              constraints: const pw.BoxConstraints(maxWidth: 240),
                              child: pw.Text(
                                clientAddress,
                                style: pw.TextStyle(font: baseFont, fontSize: 9.5, color: textGrey),
                                maxLines: 2,
                              ),
                            ),
                            if (agenda.clientPhone.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Telp/WA: ${agenda.clientPhone}',
                                style: pw.TextStyle(font: baseFont, fontSize: 9.5, color: textGrey),
                              ),
                            ],
                          ],
                        ),

                        // Kanan: Invoice Date & Due Date
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Invoice Date:',
                              style: pw.TextStyle(font: baseFont, fontSize: 9.5, color: textGrey),
                            ),
                            pw.SizedBox(height: 1),
                            pw.Text(
                              invoiceDateStr,
                              style: pw.TextStyle(font: boldFont, fontSize: 10, color: navyColor),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Due Date:',
                              style: pw.TextStyle(font: baseFont, fontSize: 9.5, color: textGrey),
                            ),
                            pw.SizedBox(height: 1),
                            pw.Text(
                              dueDateStr,
                              style: pw.TextStyle(font: boldFont, fontSize: 10, color: navyColor),
                            ),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 24),

                    // ── Tabel Header ──
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Hexagon NO
                        pw.Container(
                          width: 44,
                          height: 38,
                          child: pw.Stack(
                            alignment: pw.Alignment.center,
                            children: [
                              pw.SvgImage(svg: noHexagonSvg, width: 44, height: 38),
                              pw.Center(
                                child: pw.Text(
                                  'NO',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 10.5,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 4),

                        // Bar Kuning: ITEMS | QTY | PRICE | TOTAL
                        pw.Expanded(
                          child: pw.Container(
                            height: 38,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 14),
                            color: goldColor,
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    'ITEMS',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 10,
                                      color: navyColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                pw.Container(
                                  width: 40,
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(
                                    'QTY',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 10,
                                      color: navyColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                pw.Container(
                                  width: 85,
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    'PRICE',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 10,
                                      color: navyColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                pw.Container(
                                  width: 90,
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    'TOTAL',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 10,
                                      color: navyColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 6),

                    // ── Baris Item Tabel ──
                    ...items.map((item) {
                      return pw.Column(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                // NO
                                pw.Container(
                                  width: 44,
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(
                                    '${item.no}',
                                    style: pw.TextStyle(
                                      font: baseFont,
                                      fontSize: 10,
                                      color: textGrey,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 4),

                                // ITEMS
                                pw.Expanded(
                                  child: pw.Padding(
                                    padding: const pw.EdgeInsets.only(left: 14),
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          item.name,
                                          style: pw.TextStyle(
                                            font: boldFont,
                                            fontSize: 10,
                                            color: textDark,
                                          ),
                                        ),
                                        if (item.subtitle.isNotEmpty) ...[
                                          pw.SizedBox(height: 1),
                                          pw.Text(
                                            item.subtitle,
                                            style: pw.TextStyle(
                                              font: baseFont,
                                              fontSize: 8.5,
                                              color: textGrey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),

                                // QTY
                                pw.Container(
                                  width: 40,
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(
                                    '${item.quantity}',
                                    style: pw.TextStyle(
                                      font: baseFont,
                                      fontSize: 10,
                                      color: textDark,
                                    ),
                                  ),
                                ),

                                // PRICE
                                pw.Container(
                                  width: 85,
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    item.unitPrice > 0 ? currencyFormatter.format(item.unitPrice) : '-',
                                    style: pw.TextStyle(
                                      font: baseFont,
                                      fontSize: 9.5,
                                      color: textDark,
                                    ),
                                  ),
                                ),

                                // TOTAL
                                pw.Container(
                                  width: 90,
                                  alignment: pw.Alignment.centerRight,
                                  padding: const pw.EdgeInsets.only(right: 14),
                                  child: pw.Text(
                                    item.totalPrice > 0 ? currencyFormatter.format(item.totalPrice) : '-',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 9.5,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Divider(thickness: 0.8, color: dividerColor),
                        ],
                      );
                    }),

                    pw.SizedBox(height: 16),

                    // ── Area Bawah Tabel: Tanda Tangan (Kiri) & Rincian Total (Kanan) ──
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Kiri: Tanda Tangan & Administrator
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 48, top: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SvgImage(svg: signatureSvg, width: 105, height: 40),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Adeline Cia',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 11,
                                  color: navyColor,
                                ),
                              ),
                              pw.SizedBox(height: 1),
                              pw.Text(
                                'Administrator',
                                style: pw.TextStyle(
                                  font: baseFont,
                                  fontSize: 9,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Kanan: Sub Total, DP, Discount, GRAND TOTAL
                        pw.Container(
                          width: 240,
                          padding: const pw.EdgeInsets.only(right: 14),
                          child: pw.Column(
                            children: [
                              // Sub Total
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Sub Total',
                                    style: pw.TextStyle(font: baseFont, fontSize: 10, color: textDark),
                                  ),
                                  pw.Text(
                                    currencyFormatter.format(subtotal),
                                    style: pw.TextStyle(font: boldFont, fontSize: 10, color: textDark),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 8),

                              // Uang Transport (Muncul di atas DP)
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Uang Transport',
                                    style: pw.TextStyle(font: baseFont, fontSize: 10, color: textDark),
                                  ),
                                  pw.Text(
                                    transportFee > 0 ? currencyFormatter.format(transportFee) : 'Rp 0',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 10,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 8),

                              // DP (Pengganti Tax sesuai instruksi user)
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'DP',
                                    style: pw.TextStyle(font: baseFont, fontSize: 10, color: textDark),
                                  ),
                                  pw.Text(
                                    dpAmount > 0 ? '- ${currencyFormatter.format(dpAmount)}' : 'Rp 0',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 10,
                                      color: dpAmount > 0 ? PdfColor.fromHex('#2E7D32') : textDark,
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 8),

                              // Discount
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Discount',
                                    style: pw.TextStyle(font: baseFont, fontSize: 10, color: textDark),
                                  ),
                                  pw.Text(
                                    'Rp 0',
                                    style: pw.TextStyle(font: baseFont, fontSize: 10, color: textDark),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 12),

                              // GRAND TOTAL Box Navy
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: pw.BoxDecoration(
                                  color: navyColor,
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                                ),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      'GRAND TOTAL',
                                      style: pw.TextStyle(
                                        font: boldFont,
                                        fontSize: 11,
                                        color: PdfColors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    pw.Text(
                                      currencyFormatter.format(grandTotal),
                                      style: pw.TextStyle(
                                        font: boldFont,
                                        fontSize: 12.5,
                                        color: PdfColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    pw.Spacer(),

                    // ── Footer: Term & Conditions (Kiri) dan Payment Method (Kanan) ──
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Kiri: Term and Conditions :
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Term and Conditions :',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 9.5,
                                    color: navyColor,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Pelunasan sisa tagihan wajib diselesaikan maksimal H-3 sebelum tanggal pelaksanaan acara. Pembayaran DP mengikat tanggal dan paket dekorasi yang telah disepakati.',
                                  style: pw.TextStyle(
                                    font: baseFont,
                                    fontSize: 7.5,
                                    color: textGrey,
                                    lineSpacing: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 36),

                          // Kanan: Payment Method
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Payment Method',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 9.5,
                                    color: navyColor,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Bank Name : Bank Central Asia (BCA)\nAccount Number : 873-501-9920\nAccount Name : Dekorin Official',
                                  style: pw.TextStyle(
                                    font: baseFont,
                                    fontSize: 7.5,
                                    color: textGrey,
                                    lineSpacing: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static List<InvoiceItemData> _extractAddonItems(String selectedAddonsStr, String rawNotes, {required int startNo}) {
    final List<InvoiceItemData> items = [];
    int currentNo = startNo;

    const addonTag = '[Item Tambahan / Addon]:';
    if (rawNotes.contains(addonTag)) {
      final parts = rawNotes.split(addonTag);
      if (parts.length > 1) {
        final lines = parts[1].trim().split('\n');
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;
          if (line.startsWith('- ')) line = line.substring(2).trim();

          int qty = 1;
          final qtyMatch = RegExp(r'x(\d+)', caseSensitive: false).firstMatch(line);
          if (qtyMatch != null) {
            qty = int.tryParse(qtyMatch.group(1)!) ?? 1;
          }

          double unitPrice = 0.0;
          double totalPrice = 0.0;
          String itemName = line;

          if (line.contains('(') && line.contains(')')) {
            final openIdx = line.indexOf('(');
            final closeIdx = line.lastIndexOf(')');
            itemName = line.substring(0, openIdx).trim();
            final pricePart = line.substring(openIdx + 1, closeIdx).trim();

            if (pricePart.contains('=')) {
              final eqParts = pricePart.split('=');
              unitPrice = _parseRupiah(eqParts[0]);
              totalPrice = _parseRupiah(eqParts[1]);
            } else {
              final num = _parseRupiah(pricePart);
              if (qty > 1) {
                unitPrice = num;
                totalPrice = unitPrice * qty;
              } else {
                unitPrice = num;
                totalPrice = num;
              }
            }
          }

          itemName = itemName.replaceAll(RegExp(r'\s+x\d+$', caseSensitive: false), '').trim();

          items.add(
            InvoiceItemData(
              no: currentNo++,
              name: itemName,
              quantity: qty,
              unitPrice: unitPrice,
              totalPrice: totalPrice,
            ),
          );
        }
      }
    }

    if (items.isEmpty && selectedAddonsStr.trim().isNotEmpty) {
      final names = selectedAddonsStr.split(',');
      for (final n in names) {
        final clean = n.trim();
        if (clean.isNotEmpty) {
          items.add(
            InvoiceItemData(
              no: currentNo++,
              name: clean,
              quantity: 1,
              unitPrice: 0.0,
              totalPrice: 0.0,
            ),
          );
        }
      }
    }

    return items;
  }

  static double _parseRupiah(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
