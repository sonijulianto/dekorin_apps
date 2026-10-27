import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_pdf_helper.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

/// Screen Preview & Cetak Invoice PDF ukuran standar A4.
class InvoicePreviewView extends ConsumerWidget {
  const InvoicePreviewView({super.key, required this.agenda});

  final AgendaItem agenda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(globalAuthProvider).value;
    final fileName = 'Invoice_${agenda.clientName.replaceAll(RegExp(r'\s+'), '_')}.pdf';

    return Scaffold(
      backgroundColor: const Color(0xFF424242),
      appBar: AppBar(
        title: const Text(
          'Invoice Resmi (A4 PDF)',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PdfPreview(
        build: (format) => InvoicePdfHelper.generateInvoicePdf(agenda, companyUser: user),
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: fileName,
        onError: (context, error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.white70),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat PDF: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryGold),
              SizedBox(height: 14),
              Text(
                'Menyiapkan Dokumen PDF A4...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
