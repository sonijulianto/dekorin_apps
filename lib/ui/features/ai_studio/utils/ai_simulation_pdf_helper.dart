import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:dekorin_apps/data/models/ai_decor_simulation_model.dart';
import 'package:dekorin_apps/domain/models/user.dart';

class AiSimulationPdfHelper {
  AiSimulationPdfHelper._();

  static Future<Uint8List?> _downloadBytes(String url) async {
    if (url.trim().isEmpty) return null;
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        return resp.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  static Future<Uint8List> generateProposalPdf(
    AiDecorSimulationModel simulation, {
    User? companyUser,
  }) async {
    final doc = pw.Document();

    final results = await Future.wait<Uint8List?>([
      _downloadBytes(simulation.originalUrl),
      _downloadBytes(simulation.resultUrl),
    ]);

    final origBytes = results[0];
    final simBytes = results[1];

    final companyName = (companyUser?.companyName.isNotEmpty ?? false)
        ? companyUser!.companyName
        : 'Dekorin Studio';
    final companyPhone = (companyUser?.companyPhone.isNotEmpty ?? false)
        ? companyUser!.companyPhone
        : (companyUser?.phone ?? '');

    const goldColor = PdfColor.fromInt(0xFFD4A574);
    const darkBrown = PdfColor.fromInt(0xFF4E350E);
    const softCream = PdfColor.fromInt(0xFFF9F3EC);
    const textDark = PdfColor.fromInt(0xFF2C2C2C);
    const textMuted = PdfColor.fromInt(0xFF6E6E73);
    const borderCol = PdfColor.fromInt(0xFFE5DEC9);

    String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
    try {
      if (simulation.createdAt.isNotEmpty) {
        final parsed = DateTime.parse(simulation.createdAt).toLocal();
        formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(parsed);
      }
    } catch (_) {}

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: darkBrown,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'SIMULASI VISUAL KUSTOMISASI WARNA DEKORASI (AI PREVIEW)',
                          style: const pw.TextStyle(
                            color: goldColor,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          formattedDate,
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                        ),
                        if (companyPhone.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'WA: $companyPhone',
                            style: const pw.TextStyle(color: goldColor, fontSize: 9),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Side-by-Side Comparison
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Expanded(
                      child: _buildPdfImageBox(
                        label: 'FOTO MODEL REFERENSI (SEBELUM)',
                        imageBytes: origBytes,
                        badgeColor: textMuted,
                        borderCol: borderCol,
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: _buildPdfImageBox(
                        label: 'HASIL SIMULASI WARNA KLIEN (AI)',
                        imageBytes: simBytes,
                        badgeColor: goldColor,
                        borderCol: goldColor,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Customization Summary Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: softCream,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: borderCol),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RINCIAN REQUEST KUSTOMISASI KLIEN',
                      style: pw.TextStyle(
                        color: darkBrown,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (simulation.modelName.isNotEmpty)
                      _buildSpecRow('Model Referensi', simulation.modelName, textDark, textMuted),
                    if (simulation.fabricColor.isNotEmpty)
                      _buildSpecRow('Warna Kain Backdrop', simulation.fabricColor, textDark, textMuted),
                    if (simulation.flowerColor.isNotEmpty)
                      _buildSpecRow('Warna & Jenis Bunga', simulation.flowerColor, textDark, textMuted),
                    if (simulation.nuance.isNotEmpty)
                      _buildSpecRow('Nuansa / Konsep', simulation.nuance, textDark, textMuted),
                    if (simulation.notes.isNotEmpty)
                      _buildSpecRow('Catatan Khusus', simulation.notes, textDark, textMuted),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Disclaimer Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'Catatan Penting: Gambar hasil di atas merupakan simulasi visual berbasis AI untuk membantu memberikan bayangan perpaduan warna kain & bunga. Hasil akhir di lokasi acara dapat memiliki sedikit perbedaan gradasi warna menyesuaikan pencahayaan venue dan ketersediaan bunga.',
                  style: const pw.TextStyle(
                    color: textMuted,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildPdfImageBox({
    required String label,
    required Uint8List? imageBytes,
    required PdfColor badgeColor,
    required PdfColor borderCol,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: borderCol, width: 1.2),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: pw.BoxDecoration(
              color: badgeColor,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Expanded(
            child: imageBytes != null
                ? pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(imageBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  )
                : pw.Center(
                    child: pw.Text(
                      'Gambar tidak tersedia',
                      style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSpecRow(
    String label,
    String value,
    PdfColor textDark,
    PdfColor textMuted,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                color: textMuted,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(color: textDark, fontSize: 9.5),
            ),
          ),
        ],
      ),
    );
  }
}
