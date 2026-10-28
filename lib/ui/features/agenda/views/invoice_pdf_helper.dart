import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/invoice_template.dart';
import 'package:dekorin_apps/domain/models/user.dart';

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

  /// Generate PDF Invoice berdasarkan template pilihan (atau preferensi tersimpan)
  static Future<Uint8List> generateInvoicePdf(
    AgendaItem agenda, {
    User? companyUser,
    InvoiceTemplate? template,
  }) async {
    final activeTemplate = template ??
        InvoiceTemplate.fromId(DataPreferences.getInvoiceTemplate());

    if (activeTemplate == InvoiceTemplate.minimalistGrey) {
      return _generateMinimalistGreyPdf(agenda, companyUser: companyUser);
    }

    return _generateNavyGoldPdf(agenda, companyUser: companyUser);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TEMPLATE 1: Modern Navy & Gold (Desain Elegan Mewah)
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> _generateNavyGoldPdf(
    AgendaItem agenda, {
    User? companyUser,
  }) async {
    final pdf = pw.Document();

    // Unduh gambar logo vendor (prioritaskan logo Sub-Brand jika agenda memakai Sub-Brand)
    final effectiveLogoUrl = agenda.brandLogo.isNotEmpty
        ? agenda.brandLogo
        : (companyUser?.companyLogo ?? '');
    pw.MemoryImage? companyLogoImage;
    if (effectiveLogoUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(effectiveLogoUrl)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          companyLogoImage = pw.MemoryImage(res.bodyBytes);
        }
      } catch (_) {
        companyLogoImage = null;
      }
    }

    final companyName = agenda.brandName.isNotEmpty
        ? agenda.brandName
        : ((companyUser?.companyName.isNotEmpty ?? false)
            ? companyUser!.companyName
            : 'Dekorin');
    final companyDescription = agenda.brandDescription.isNotEmpty
        ? agenda.brandDescription
        : ((companyUser?.companyDescription.isNotEmpty ?? false)
            ? companyUser!.companyDescription
            : 'Wedding & Event Decoration');
    final companyPhone = agenda.brandPhone.isNotEmpty
        ? agenda.brandPhone
        : ((companyUser?.companyPhone.isNotEmpty ?? false)
            ? companyUser!.companyPhone
            : '+62 812-3456-7890');
    final companyInstagram = agenda.brandInstagram.isNotEmpty
        ? agenda.brandInstagram
        : (companyUser?.companyInstagram ?? '');
    final companyEmail = companyInstagram.isNotEmpty
        ? 'IG: $companyInstagram'
        : ((companyUser?.companyEmail.isNotEmpty ?? false)
            ? companyUser!.companyEmail
            : 'hello@dekorin.id');
    final companyAddress = (companyUser?.companyAddress.isNotEmpty ?? false)
        ? companyUser!.companyAddress
        : 'Jakarta, Indonesia';
    final companyBankInfo = (companyUser?.companyBankInfo.isNotEmpty ?? false)
        ? companyUser!.companyBankInfo
        : 'Bank Name : Bank Central Asia (BCA)\nAccount Number : 873-501-9920\nAccount Name : Dekorin Official';
    final signerName = (companyUser?.name.isNotEmpty ?? false)
        ? companyUser!.name
        : 'Administrator';
    final signerRole = (companyUser?.roleDisplayName.isNotEmpty ?? false)
        ? companyUser!.roleDisplayName
        : 'Administrator';

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final form = agenda.clientForm;

    // 1. Penentuan Harga Paket
    final double packagePrice = _calculatePackagePrice(agenda);

    // 2. Ekstraksi Item Addon & Kalkulasi
    final List<InvoiceItemData> items = [];
    
    // Item 1: Paket Dekorasi
    items.add(
      InvoiceItemData(
        no: 1,
        name: agenda.packageName.isNotEmpty ? agenda.packageName : 'Paket Dekorasi',
        subtitle: [
          if (agenda.backdropTitle.isNotEmpty) 'Acara: ${agenda.backdropTitle}',
          if (agenda.modelName.isNotEmpty) 'Model: ${agenda.modelName}${agenda.modelWidth.isNotEmpty ? ' (${agenda.modelWidth})' : ''}',
        ].join(' | '),
        quantity: 1,
        unitPrice: packagePrice,
        totalPrice: packagePrice,
      ),
    );

    // Item 2: Model Dekorasi Tambahan (jika ada biaya tambahan)
    if (agenda.modelAdditionalPrice > 0) {
      items.add(
        InvoiceItemData(
          no: items.length + 1,
          name: 'Upgrade Model: ${agenda.modelName}',
          subtitle: agenda.modelWidth.isNotEmpty ? 'Lebar Backdrop: ${agenda.modelWidth}' : '',
          quantity: 1,
          unitPrice: agenda.modelAdditionalPrice,
          totalPrice: agenda.modelAdditionalPrice,
        ),
      );
    }

    // Item Addon
    final addonList = _extractAddonItems(form?.selectedAddons ?? '', agenda.notes, startNo: items.length + 1);
    items.addAll(addonList);

    double addonsTotal = 0.0;
    for (final addon in addonList) {
      addonsTotal += addon.totalPrice;
    }
    if (addonsTotal == 0 && form != null && form.addonsPrice > 0) {
      addonsTotal = form.addonsPrice;
    }

    // Kalkulasi Total
    final double subtotal = packagePrice + agenda.modelAdditionalPrice + addonsTotal;
    final double transportFee = agenda.transportFee;
    final double totalTagihan = subtotal + transportFee;
    final double dpAmount = agenda.dpAmount;
    final double grandTotal = (totalTagihan - dpAmount) > 0 ? (totalTagihan - dpAmount) : 0.0;

    // Nomor Invoice & Tanggal
    final invoiceNumber =
        'INV-${agenda.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase()}-${DateFormat('yyMMdd').format(agenda.eventDateTime)}';
    final invoiceDateStr = DateFormat('dd/MM/yy').format(DateTime.now());
    final dueDateStr = DateFormat('dd/MM/yy').format(agenda.eventDateTime);

    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    final navyColor = PdfColor.fromHex('#1C3B57');
    final goldColor = PdfColor.fromHex('#E5B824');
    final textDark = PdfColor.fromHex('#212D38');
    final textGrey = PdfColor.fromHex('#64748B');
    final dividerColor = PdfColor.fromHex('#E2E8F0');

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
              // Top-Left Navy Banner Ornamen
              pw.Positioned(
                top: 0,
                left: 0,
                child: pw.SvgImage(
                  svg: topBannerSvg,
                  width: 210,
                  height: 145,
                ),
              ),

              // Logo & Brand Name
              pw.Positioned(
                top: 28,
                left: 28,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (companyLogoImage != null)
                      pw.Container(
                        width: 36,
                        height: 36,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 6,
                          verticalRadius: 6,
                          child: pw.Image(
                            companyLogoImage,
                            width: 36,
                            height: 36,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      pw.SvgImage(svg: logoSvg, width: 34, height: 34),
                    pw.SizedBox(width: 10),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.ConstrainedBox(
                          constraints: const pw.BoxConstraints(maxWidth: 160),
                          child: pw.Text(
                            companyName,
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: companyName.length > 20 ? 13 : 16,
                              color: PdfColors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        pw.ConstrainedBox(
                          constraints: const pw.BoxConstraints(maxWidth: 160),
                          child: pw.Text(
                            companyDescription,
                            style: pw.TextStyle(
                              font: baseFont,
                              fontSize: 7.5,
                              color: PdfColors.white,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Top-Right Hexagon Accent
              pw.Positioned(
                top: 0,
                right: 0,
                child: pw.SvgImage(
                  svg: topHexagonsSvg,
                  width: 130,
                  height: 112,
                ),
              ),

              // Bottom Accent Bar (Gold)
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
                        companyPhone,
                        style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: navyColor),
                      ),
                      pw.Text(
                        companyEmail,
                        style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: navyColor),
                      ),
                      pw.Text(
                        companyAddress,
                        style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: navyColor),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom-Left Hexagon Accent
              pw.Positioned(
                bottom: 0,
                left: 0,
                child: pw.SvgImage(
                  svg: bottomHexagonsSvg,
                  width: 125,
                  height: 109,
                ),
              ),

              // Konten Utama Invoice
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(42, 40, 42, 36),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
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

                    // Tabel Header
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
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

                    // Baris Item Tabel
                    ...items.map((item) {
                      return pw.Column(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
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

                    // Area Bawah Tabel: Tanda Tangan & Rincian Total
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 48, top: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SvgImage(svg: signatureSvg, width: 105, height: 40),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                signerName,
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 11,
                                  color: navyColor,
                                ),
                              ),
                              pw.SizedBox(height: 1),
                              pw.Text(
                                signerRole,
                                style: pw.TextStyle(
                                  font: baseFont,
                                  fontSize: 9,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        pw.Container(
                          width: 240,
                          padding: const pw.EdgeInsets.only(right: 14),
                          child: pw.Column(
                            children: [
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

                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
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
                                  companyBankInfo,
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

  // ─────────────────────────────────────────────────────────────────────────────
  // TEMPLATE 2: Minimalist Modern Grey (Desain Bersih Monokrom Chevron)
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> _generateMinimalistGreyPdf(
    AgendaItem agenda, {
    User? companyUser,
  }) async {
    final pdf = pw.Document();

    final effectiveLogoUrl = agenda.brandLogo.isNotEmpty
        ? agenda.brandLogo
        : (companyUser?.companyLogo ?? '');
    pw.MemoryImage? companyLogoImage;
    if (effectiveLogoUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(effectiveLogoUrl)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          companyLogoImage = pw.MemoryImage(res.bodyBytes);
        }
      } catch (_) {
        companyLogoImage = null;
      }
    }

    final companyName = agenda.brandName.isNotEmpty
        ? agenda.brandName
        : ((companyUser?.companyName.isNotEmpty ?? false)
            ? companyUser!.companyName
            : 'FAMILY BACKDROP');
    final companyPhone = agenda.brandPhone.isNotEmpty
        ? agenda.brandPhone
        : ((companyUser?.companyPhone.isNotEmpty ?? false)
            ? companyUser!.companyPhone
            : '0895 1678 9565');
    final companyInstagram = agenda.brandInstagram.isNotEmpty
        ? agenda.brandInstagram
        : (companyUser?.companyInstagram ?? '');
    final companyEmail = companyInstagram.isNotEmpty
        ? 'IG: $companyInstagram'
        : ((companyUser?.companyEmail.isNotEmpty ?? false)
            ? companyUser!.companyEmail
            : 'sonijulianto@gmail.com');
    final companyAddress = (companyUser?.companyAddress.isNotEmpty ?? false)
        ? companyUser!.companyAddress
        : 'Jl. Mayor oking jaya atmaja\nCiriung - Cibinong, Kab Bogor';
    final companyBankInfo = (companyUser?.companyBankInfo.isNotEmpty ?? false)
        ? companyUser!.companyBankInfo
        : 'Nama : Soni Julianto\nNo Rek (BCA) : 5720732931\nNo Rek (BRI) : 144801005406501';

    final form = agenda.clientForm;
    final double packagePrice = _calculatePackagePrice(agenda);

    // Ekstraksi item tabel
    final List<InvoiceItemData> items = [];

    // 1. Paket Utama
    items.add(
      InvoiceItemData(
        no: 1,
        name: agenda.packageName.isNotEmpty ? agenda.packageName.toUpperCase() : 'PAKET DEKORASI',
        subtitle: [
          if (agenda.backdropTitle.isNotEmpty) 'Acara: ${agenda.backdropTitle}',
          if (agenda.modelName.isNotEmpty) 'Model: ${agenda.modelName}${agenda.modelWidth.isNotEmpty ? ' (${agenda.modelWidth})' : ''}',
        ].join(' | '),
        quantity: 1,
        unitPrice: packagePrice,
        totalPrice: packagePrice,
      ),
    );

    // 2. Upgrade Model (jika ada harga tambahan)
    if (agenda.modelAdditionalPrice > 0) {
      items.add(
        InvoiceItemData(
          no: items.length + 1,
          name: 'UPGRADE MODEL: ${agenda.modelName.toUpperCase()}',
          subtitle: agenda.modelWidth.isNotEmpty ? 'Lebar: ${agenda.modelWidth}' : '',
          quantity: 1,
          unitPrice: agenda.modelAdditionalPrice,
          totalPrice: agenda.modelAdditionalPrice,
        ),
      );
    }

    // 3. Addon Items
    final addonList = _extractAddonItems(form?.selectedAddons ?? '', agenda.notes, startNo: items.length + 1);
    for (final a in addonList) {
      items.add(
        InvoiceItemData(
          no: a.no,
          name: a.name.toUpperCase(),
          subtitle: a.subtitle,
          quantity: a.quantity,
          unitPrice: a.unitPrice,
          totalPrice: a.totalPrice,
        ),
      );
    }

    // 4. Uang Transport (dimasukkan sebagai baris item sesuai referensi template 2)
    if (agenda.transportFee > 0) {
      items.add(
        InvoiceItemData(
          no: items.length + 1,
          name: 'TRANSPORT',
          subtitle: '',
          quantity: 1,
          unitPrice: agenda.transportFee,
          totalPrice: agenda.transportFee,
        ),
      );
    }

    // Kalkulasi
    double subtotal = 0.0;
    for (final it in items) {
      subtotal += it.totalPrice;
    }
    final double dpAmount = agenda.dpAmount;
    final double grandTotal = (subtotal - dpAmount) > 0 ? (subtotal - dpAmount) : 0.0;

    // Nomor Invoice: FB-001-21102026 format sesuai referensi user
    String initials = companyName
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .take(3)
        .join();
    if (initials.isEmpty) initials = 'FB';
    final cleanId = agenda.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final shortId = cleanId.length >= 3 ? cleanId.substring(cleanId.length - 3) : cleanId.padLeft(3, '0');
    final dateCode = DateFormat('ddMMyyyy').format(agenda.eventDateTime);
    final invoiceNumber = '$initials-$shortId-$dateCode';

    // Tanggal format Indonesia: "Rabu, 21 Oktober 2026"
    final formattedDate = DateFormat('EEEE, d MMMM y', 'id_ID').format(agenda.eventDateTime);

    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    // SVG Header Chevron Abu-abu Monokrom (A4 Width: 595.28, Header Height: 128)
    const headerBannerSvg = '''
<svg viewBox="0 0 595.28 128" width="595.28" height="128" xmlns="http://www.w3.org/2000/svg">
  <!-- Blok Utama Kiri berujung panah panah/chevron -->
  <polygon points="0,0 320,0 365,64 320,128 0,128" fill="#DFE2E6"/>
  <!-- Strip Chevron Tengah -->
  <polygon points="340,0 380,0 425,64 380,128 340,128 385,64" fill="#DFE2E6"/>
  <!-- Aksen Sudut Kanan Atas -->
  <polygon points="535,0 595.28,0 595.28,128 580,128" fill="#DFE2E6"/>
</svg>
''';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Header Banner Abu-Abu Chevron di puncak halaman
              pw.Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: pw.SvgImage(
                  svg: headerBannerSvg,
                  width: 595.28,
                  height: 128,
                ),
              ),

              // Teks Judul INVOICE & Nama Usaha di dalam Banner
              pw.Positioned(
                top: 32,
                left: 45,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (companyLogoImage != null) ...[
                      pw.Container(
                        width: 46,
                        height: 46,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(
                            companyLogoImage,
                            width: 46,
                            height: 46,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 32,
                            color: PdfColors.black,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          companyName.toUpperCase(),
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 15,
                            color: PdfColors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Seluruh Konten Faktur
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(45, 148, 45, 36),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Nomor Invoice
                    pw.Text(
                      'INVOICE # $invoiceNumber',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 10.5,
                        color: PdfColors.black,
                      ),
                    ),

                    pw.SizedBox(height: 14),

                    // Baris Informasi: KEPADA & TANGGAL
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // KEPADA
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'KEPADA :',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 10.5,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              agenda.clientName,
                              style: pw.TextStyle(
                                font: baseFont,
                                fontSize: 10.5,
                                color: PdfColors.black,
                              ),
                            ),
                            if (agenda.clientPhone.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                agenda.clientPhone,
                                style: pw.TextStyle(
                                  font: baseFont,
                                  fontSize: 9,
                                  color: PdfColor.fromHex('#444444'),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // TANGGAL
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'TANGGAL :',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 10.5,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              formattedDate,
                              style: pw.TextStyle(
                                font: baseFont,
                                fontSize: 10.5,
                                color: PdfColors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 18),

                    // Header Tabel: KETERANGAN | HARGA | JML | TOTAL
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'KETERANGAN',
                            style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: PdfColors.black),
                          ),
                        ),
                        pw.Container(
                          width: 105,
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            'HARGA',
                            style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: PdfColors.black),
                          ),
                        ),
                        pw.Container(
                          width: 50,
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'JML',
                            style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: PdfColors.black),
                          ),
                        ),
                        pw.Container(
                          width: 110,
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: PdfColors.black),
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 6),
                    // Garis hitam tebal di bawah header
                    pw.Container(height: 2.2, color: PdfColors.black),
                    pw.SizedBox(height: 4),

                    // Baris-baris item tabel
                    ...items.map((item) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    item.name,
                                    style: pw.TextStyle(
                                      font: baseFont,
                                      fontSize: 10,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                  if (item.subtitle.isNotEmpty) ...[
                                    pw.SizedBox(height: 1.5),
                                    pw.Text(
                                      item.subtitle,
                                      style: pw.TextStyle(
                                        font: baseFont,
                                        fontSize: 8.5,
                                        color: PdfColor.fromHex('#555555'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            pw.Container(
                              width: 105,
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                item.unitPrice > 0 ? _formatRupiahCaps(item.unitPrice) : '-',
                                style: pw.TextStyle(font: baseFont, fontSize: 10, color: PdfColors.black),
                              ),
                            ),
                            pw.Container(
                              width: 50,
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '${item.quantity}',
                                style: pw.TextStyle(font: baseFont, fontSize: 10, color: PdfColors.black),
                              ),
                            ),
                            pw.Container(
                              width: 110,
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                item.totalPrice > 0 ? _formatRupiahCaps(item.totalPrice) : '-',
                                style: pw.TextStyle(font: baseFont, fontSize: 10, color: PdfColors.black),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    pw.SizedBox(height: 14),
                    // Garis hitam pembatas tebal di bawah daftar item
                    pw.Container(height: 2.5, color: PdfColors.black),
                    pw.SizedBox(height: 12),

                    // Ringkasan Total (Rata Kanan)
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Container(
                        width: 250,
                        child: pw.Column(
                          children: [
                            // SUB TOTAL :
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'SUB TOTAL :',
                                  style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: PdfColors.black),
                                ),
                                pw.Text(
                                  _formatRupiahCaps(subtotal),
                                  style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: PdfColors.black),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 6),

                            // DP :
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'DP :',
                                  style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: PdfColors.black),
                                ),
                                pw.Text(
                                  dpAmount > 0 ? _formatRupiahCaps(dpAmount) : 'RP 0',
                                  style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: PdfColors.black),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 6),

                            // TOTAL :
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'TOTAL :',
                                  style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.black),
                                ),
                                pw.Text(
                                  _formatRupiahCaps(grandTotal),
                                  style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    pw.Spacer(),

                    // Footer Bagian Bawah: PEMBAYARAN (kiri) & INFO KONTAK/ALAMAT (kanan)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Kiri: Rekening Pembayaran
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'PEMBAYARAN :',
                              style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: PdfColors.black),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              companyBankInfo,
                              style: pw.TextStyle(font: baseFont, fontSize: 9, color: PdfColors.black, lineSpacing: 1.3),
                            ),
                          ],
                        ),

                        // Kanan: Alamat, Telepon, Email (Rata Kanan)
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            if (companyAddress.isNotEmpty) ...[
                              pw.Text(
                                companyAddress,
                                style: pw.TextStyle(font: baseFont, fontSize: 9, color: PdfColors.black, lineSpacing: 1.3),
                                textAlign: pw.TextAlign.right,
                              ),
                              pw.SizedBox(height: 4),
                            ],
                            if (companyPhone.isNotEmpty) ...[
                              pw.Text(
                                companyPhone,
                                style: pw.TextStyle(font: baseFont, fontSize: 9, color: PdfColors.black),
                                textAlign: pw.TextAlign.right,
                              ),
                              pw.SizedBox(height: 3),
                            ],
                            if (companyEmail.isNotEmpty) ...[
                              pw.Text(
                                companyEmail,
                                style: pw.TextStyle(font: baseFont, fontSize: 9, color: PdfColors.black),
                                textAlign: pw.TextAlign.right,
                              ),
                            ],
                          ],
                        ),
                      ],
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Helper Metrik & Parsing
  // ─────────────────────────────────────────────────────────────────────────────
  static double _calculatePackagePrice(AgendaItem agenda) {
    final form = agenda.clientForm;
    final isUnselected = agenda.packageName.toLowerCase().contains('belum dipilih') ||
        (form != null && form.packageName.toLowerCase().contains('belum dipilih'));

    if (isUnselected) {
      return 0.0;
    } else if (form != null && form.packagePrice > 0) {
      return form.packagePrice;
    } else if (agenda.packagePrice > 0) {
      return agenda.packagePrice;
    } else if (_fallbackPackagePrices.containsKey(agenda.packageId)) {
      return _fallbackPackagePrices[agenda.packageId]!;
    } else {
      final nameLower = agenda.packageName.toLowerCase();
      if (nameLower.contains('akad') || nameLower.contains('minimalis')) {
        return 2500000.0;
      } else if (nameLower.contains('lamaran') || nameLower.contains('rustic')) {
        return 4000000.0;
      } else if (nameLower.contains('pernikahan') || nameLower.contains('elegan')) {
        return 9500000.0;
      } else if (nameLower.contains('ballroom') || nameLower.contains('luxury')) {
        return 18000000.0;
      } else {
        return 0.0;
      }
    }
  }

  static String _formatRupiahCaps(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'RP ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
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
