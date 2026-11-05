import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/crew_brief.dart';
import 'package:dekorin_apps/ui/features/agenda/views/crew_brief_pdf_helper.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

/// Screen Preview & Ekspor Lembar Kerja Visual Crew Dekorasi format A4.
class CrewBriefPreviewView extends ConsumerStatefulWidget {
  const CrewBriefPreviewView({
    super.key,
    required this.agenda,
    required this.sections,
  });

  final AgendaItem agenda;
  final List<CrewBriefSection> sections;

  @override
  ConsumerState<CrewBriefPreviewView> createState() => _CrewBriefPreviewViewState();
}

class _CrewBriefPreviewViewState extends ConsumerState<CrewBriefPreviewView> {
  bool _isSharingImage = false;

  Future<void> _shareAsPngImage() async {
    if (_isSharingImage) return;

    setState(() => _isSharingImage = true);
    try {
      final user = ref.read(globalAuthProvider).value;
      final pdfBytes = await CrewBriefPdfHelper.generateCrewBriefPdf(
        agenda: widget.agenda,
        sections: widget.sections,
        companyUser: user,
      );

      final pngBytes = await CrewBriefPdfHelper.convertPdfToPng(pdfBytes);
      final safeClient = widget.agenda.clientName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'Brief_Crew_${safeClient}_A4.png';

      await Printing.sharePdf(
        bytes: pngBytes,
        filename: fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan gambar: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(globalAuthProvider).value;
    final safeClient = widget.agenda.clientName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'Brief_Crew_${safeClient}_A4.pdf';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Lembar Kerja Crew A4', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Tombol Bagikan Gambar PNG A4 ke WhatsApp / Galeri
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isSharingImage ? null : _shareAsPngImage,
              icon: _isSharingImage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGold),
                    )
                  : const Icon(Icons.image_outlined, size: 18, color: AppColors.primaryGold),
              label: Text(
                'Kirim Gambar A4',
                style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.goldLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => CrewBriefPdfHelper.generateCrewBriefPdf(
          agenda: widget.agenda,
          sections: widget.sections,
          companyUser: user,
        ),
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: fileName,
        actionBarTheme: const PdfActionBarTheme(
          backgroundColor: AppColors.primaryGold,
          iconColor: Colors.white,
        ),
        actions: [
          PdfPrintAction(
            icon: SvgPicture.asset(
              'assets/icons/print.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            jobName: fileName,
          ),
          PdfShareAction(
            icon: SvgPicture.asset(
              'assets/icons/share.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            filename: fileName,
          ),
        ],
        onError: (context, error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat preview lembar kerja: $error',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
