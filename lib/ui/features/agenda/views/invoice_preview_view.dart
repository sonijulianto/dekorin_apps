import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/invoice_template.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/invoice_template_provider.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_pdf_helper.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

/// Screen Preview & Cetak Invoice PDF ukuran standar A4 dengan fitur pilih template langsung.
class InvoicePreviewView extends ConsumerStatefulWidget {
  const InvoicePreviewView({
    super.key,
    required this.agenda,
    this.forcedTemplate,
  });

  final AgendaItem agenda;
  final InvoiceTemplate? forcedTemplate;

  @override
  ConsumerState<InvoicePreviewView> createState() => _InvoicePreviewViewState();
}

class _InvoicePreviewViewState extends ConsumerState<InvoicePreviewView> {
  late InvoiceTemplate _activeTemplate;
  late AgendaItem _agenda;

  @override
  void initState() {
    super.initState();
    _agenda = widget.agenda;
    _activeTemplate = widget.forcedTemplate ?? ref.read(invoiceTemplateProvider);
  }

  void _showBrandPickerSheet(List<CompanyBrand> brands, String mainCompanyName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih Brand untuk Invoice & Link Klien',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mengubah nama usaha, logo, kontak WA & Instagram pada dokumen Invoice.',
                  style: AppTypography.caption.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 14),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: _agenda.brandId.isEmpty ? AppColors.primaryGold : AppColors.borderLight,
                      width: _agenda.brandId.isEmpty ? 1.5 : 1,
                    ),
                  ),
                  tileColor: _agenda.brandId.isEmpty ? AppColors.goldLight.withValues(alpha: 0.4) : Colors.white,
                  title: Text(
                    mainCompanyName.isNotEmpty ? '$mainCompanyName (Brand Utama)' : 'Brand Utama',
                    style: AppTypography.titleSmall,
                  ),
                  trailing: _agenda.brandId.isEmpty
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGold)
                      : const Icon(Icons.radio_button_unchecked, color: AppColors.textLight),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    try {
                      final updated = await ref.read(agendaServiceProvider).updateAgendaBrand(_agenda.id, '');
                      ref.read(agendaViewModelProvider.notifier).refresh();
                      if (mounted) {
                        setState(() => _agenda = updated);
                      }
                    } catch (_) {
                      if (mounted) {
                        setState(() {
                          _agenda = _agenda.copyWith(
                            brandId: '',
                            brandName: '',
                            brandLogo: '',
                            brandPhone: '',
                            brandInstagram: '',
                            brandDescription: '',
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                ...brands.map((b) {
                  final isSelected = _agenda.brandId == b.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryGold : AppColors.borderLight,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      tileColor: isSelected ? AppColors.goldLight.withValues(alpha: 0.4) : Colors.white,
                      title: Text(b.name, style: AppTypography.titleSmall),
                      subtitle: b.description.isNotEmpty
                          ? Text(b.description, style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGold)
                          : const Icon(Icons.radio_button_unchecked, color: AppColors.textLight),
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        try {
                          final updated = await ref.read(agendaServiceProvider).updateAgendaBrand(_agenda.id, b.id);
                          ref.read(agendaViewModelProvider.notifier).refresh();
                          if (mounted) {
                            setState(() => _agenda = updated);
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(() {
                              _agenda = _agenda.copyWith(
                                brandId: b.id,
                                brandName: b.name,
                                brandLogo: b.logoUrl,
                                brandPhone: b.phone,
                                brandInstagram: b.instagram,
                                brandDescription: b.description,
                              );
                            });
                          }
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTemplatePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ganti Desain Template',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '2 Template Tersedia',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Opsi template
                    ...InvoiceTemplate.values.map((tmpl) {
                      final isSelected = tmpl == _activeTemplate;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.goldLight.withValues(alpha: 0.4) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGold : AppColors.borderLight,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          leading: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Color(tmpl.accentHex),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                            tmpl.name,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            tmpl.subtitle,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textLight,
                              fontSize: 11,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGold, size: 22)
                              : const Icon(Icons.radio_button_unchecked, color: AppColors.textLight, size: 22),
                          onTap: () async {
                            setState(() {
                              _activeTemplate = tmpl;
                            });
                            final navigator = Navigator.of(sheetContext);
                            final messenger = ScaffoldMessenger.of(context);
                            // Juga perbarui preferensi default
                            await ref.read(invoiceTemplateProvider.notifier).setTemplate(tmpl);
                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.primaryGold,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  content: Text(
                                    'Menampilkan invoice dengan ${tmpl.name}',
                                    style: AppTypography.bodySmall.copyWith(color: Colors.white),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(globalAuthProvider).value;
    final brands = ref.watch(companyBrandsProvider).value ?? const <CompanyBrand>[];
    final mainCompanyName = user?.companyName ?? 'Brand Utama';
    final activeBrandLabel = _agenda.brandName.isNotEmpty
        ? _agenda.brandName
        : (mainCompanyName.isNotEmpty ? mainCompanyName : 'Brand Utama');
    final fileName = 'Invoice_${_agenda.clientName.replaceAll(RegExp(r'\s+'), '_')}.pdf';

    return Scaffold(
      backgroundColor: const Color(0xFF424242),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Invoice Resmi (A4 PDF)',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '$activeBrandLabel • ${_activeTemplate.name}',
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context, _agenda),
        ),
        actions: [
          if (brands.isNotEmpty)
            IconButton(
              tooltip: 'Ganti Brand Invoice',
              onPressed: () => _showBrandPickerSheet(brands, mainCompanyName),
              icon: const Icon(Icons.layers_outlined, color: AppColors.primaryGold, size: 20),
            ),
          // Tombol ganti template invoice
          TextButton.icon(
            onPressed: _showTemplatePickerSheet,
            icon: const Icon(Icons.style_outlined, color: AppColors.primaryGold, size: 18),
            label: Text(
              'Template',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PdfPreview(
        key: ValueKey('${_activeTemplate.id}_${_agenda.brandId}_${_agenda.brandName}'),
        build: (format) => InvoicePdfHelper.generateInvoicePdf(
          _agenda,
          companyUser: user,
          template: _activeTemplate,
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.white70),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat PDF: $error',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
        loadingWidget: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryGold),
              const SizedBox(height: 14),
              Text(
                'Menyiapkan Dokumen PDF A4 (${_activeTemplate.name})...',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
