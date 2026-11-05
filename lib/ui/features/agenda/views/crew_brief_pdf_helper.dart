import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/crew_brief.dart';
import 'package:dekorin_apps/domain/models/user.dart';

/// Helper untuk men-generate Lembar Kerja Visual Crew Dekorasi format A4 (PDF & Gambar PNG).
class CrewBriefPdfHelper {
  static const PdfColor primaryGold = PdfColor.fromInt(0xFFD4A574);
  static const PdfColor darkGold = PdfColor.fromInt(0xFF8C6239);
  static const PdfColor goldLight = PdfColor.fromInt(0xFFF9F3EC);
  static const PdfColor textDark = PdfColor.fromInt(0xFF2C2C2C);
  static const PdfColor textGrey = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor borderLight = PdfColor.fromInt(0xFFE5E7EB);

  /// Men-generate PDF Dokumen A4 dari data agenda dan daftar seksi instruksi crew.
  static Future<Uint8List> generateCrewBriefPdf({
    required AgendaItem agenda,
    required List<CrewBriefSection> sections,
    User? companyUser,
  }) async {
    final pdf = pw.Document();

    // 1. Ambil logo jika ada
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
    final companyPhone = agenda.brandPhone.isNotEmpty
        ? agenda.brandPhone
        : ((companyUser?.companyPhone.isNotEmpty ?? false)
            ? companyUser!.companyPhone
            : '-');
    final companyInstagram = agenda.brandInstagram.isNotEmpty
        ? agenda.brandInstagram
        : (companyUser?.companyInstagram ?? '');

    // 2. Pre-load semua gambar seksi ke MemoryImage
    final Map<int, pw.MemoryImage> loadedImages = {};
    for (int i = 0; i < sections.length; i++) {
      final sec = sections[i];
      Uint8List? rawBytes = sec.imageBytes;

      if (rawBytes == null && sec.imageFile != null) {
        try {
          rawBytes = await sec.imageFile!.readAsBytes();
        } catch (_) {}
      }

      if (rawBytes == null && sec.imageUrl != null && sec.imageUrl!.trim().isNotEmpty) {
        try {
          final res = await http.get(Uri.parse(sec.imageUrl!)).timeout(const Duration(seconds: 6));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            rawBytes = res.bodyBytes;
          }
        } catch (_) {}
      }

      if (rawBytes != null && rawBytes.isNotEmpty) {
        try {
          loadedImages[i] = pw.MemoryImage(rawBytes);
        } catch (_) {}
      }
    }

    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm', 'id_ID');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // ── HEADER VENDOR & JUDUL LEMBAR KERJA ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (companyLogoImage != null) ...[
                      pw.Container(
                        width: 44,
                        height: 44,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: primaryGold, width: 1.5),
                        ),
                        child: pw.ClipOval(child: pw.Image(companyLogoImage, fit: pw.BoxFit.cover)),
                      ),
                      pw.SizedBox(width: 10),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName.toUpperCase(),
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: textDark),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          children: [
                            if (companyPhone.isNotEmpty && companyPhone != '-') ...[
                              pw.Text('Telp: $companyPhone', style: const pw.TextStyle(fontSize: 9, color: textGrey)),
                              if (companyInstagram.isNotEmpty) pw.Text('  •  ', style: const pw.TextStyle(fontSize: 9, color: textGrey)),
                            ],
                            if (companyInstagram.isNotEmpty)
                              pw.Text('IG: @$companyInstagram', style: const pw.TextStyle(fontSize: 9, color: textGrey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: goldLight,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: primaryGold),
                  ),
                  child: pw.Text(
                    'LEMBAR KERJA CREW DEKOR',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkGold),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: primaryGold, thickness: 1.5),
            pw.SizedBox(height: 10),

            // ── KOTAK INFORMASI ACARA (EVENT SUMMARY) ──
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderLight),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NAMA KLIEN / PEMESAN:', style: const pw.TextStyle(fontSize: 8, color: textGrey)),
                        pw.Text(agenda.clientName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textDark)),
                        if (agenda.backdropTitle.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(agenda.backdropTitle, style: const pw.TextStyle(fontSize: 9, color: darkGold)),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('JADWAL PELAKSANAAN:', style: const pw.TextStyle(fontSize: 8, color: textGrey)),
                        pw.Text(
                          dateFormat.format(agenda.eventDateTime),
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Pukul ${timeFormat.format(agenda.eventDateTime)} WIB',
                          style: const pw.TextStyle(fontSize: 9, color: textGrey),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('LOKASI / VENUE ACARA:', style: const pw.TextStyle(fontSize: 8, color: textGrey)),
                        pw.Text(
                          agenda.displayAddress.isNotEmpty ? agenda.displayAddress : 'Alamat sesuai Maps',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ── DAFTAR BLOK FOTO & CHECKLIST INSTRUKSI ──
            ...List.generate(sections.length, (index) {
              final section = sections[index];
              final img = loadedImages[index];
              final validNotes = section.notes.where((n) => n.trim().isNotEmpty).toList();
              final sectionTitle = section.title.trim().isNotEmpty
                  ? section.title.trim()
                  : 'BAGIAN ${index + 1}: AREA DEKORASI';

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 14),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderLight),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Judul Seksi
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: goldLight,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        sectionTitle.toUpperCase(),
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkGold),
                      ),
                    ),
                    pw.SizedBox(height: 8),

                    // Konten: Foto (Kiri) & Checklist (Kanan)
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Foto Area Setup
                        pw.Container(
                          width: 170,
                          height: 130,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: borderLight),
                          ),
                          child: img != null
                              ? pw.ClipRRect(
                                  horizontalRadius: 6,
                                  verticalRadius: 6,
                                  child: pw.Image(img, fit: pw.BoxFit.cover),
                                )
                              : pw.Center(
                                  child: pw.Text(
                                    'Tidak ada foto',
                                    style: const pw.TextStyle(fontSize: 9, color: textGrey),
                                  ),
                                ),
                        ),
                        pw.SizedBox(width: 14),

                        // Checklist Instruksi Poin-Poin
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'INSTRUKSI & CHECKLIST SETUP:',
                                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark),
                              ),
                              pw.SizedBox(height: 6),
                              if (validNotes.isEmpty)
                                pw.Text(
                                  '- Pasang dan sesuaikan dengan foto referensi di samping.',
                                  style: const pw.TextStyle(fontSize: 9, color: textGrey),
                                )
                              else
                                ...validNotes.map((note) {
                                  return pw.Padding(
                                    padding: const pw.EdgeInsets.only(bottom: 6),
                                    child: pw.Row(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        // Checkbox kotak kosong untuk dicentang crew
                                        pw.Container(
                                          width: 10,
                                          height: 10,
                                          margin: const pw.EdgeInsets.only(top: 1.5, right: 6),
                                          decoration: pw.BoxDecoration(
                                            border: pw.Border.all(color: darkGold, width: 1.2),
                                            borderRadius: pw.BorderRadius.circular(2),
                                          ),
                                        ),
                                        pw.Expanded(
                                          child: pw.Text(
                                            note,
                                            style: const pw.TextStyle(fontSize: 9, color: textDark, lineSpacing: 1.2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // ── FOOTER SOP & QC LAPANGAN ──
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: goldLight,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: primaryGold),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PENTING: Pastikan checklist pick-list termuat & foto hasil dekorasi sebelum serah terima.',
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkGold),
                  ),
                  pw.Text(
                    'DEKORIN WORK ORDER',
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textGrey),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Mengonversi halaman PDF pertama menjadi gambar PNG A4 beresolusi tinggi (200 DPI).
  static Future<Uint8List> convertPdfToPng(Uint8List pdfBytes) async {
    await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 200)) {
      final png = await page.toPng();
      return png;
    }
    throw Exception('Gagal mengonversi halaman PDF ke gambar');
  }
}
