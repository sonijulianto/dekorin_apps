import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/invoice_template.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/invoice_template_provider.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_preview_view.dart';

/// Halaman Pengaturan untuk Memilih Template Invoice yang akan digunakan aplikasi
class InvoiceTemplateSettingView extends ConsumerWidget {
  const InvoiceTemplateSettingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTemplate = ref.watch(invoiceTemplateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Pilih Template Invoice',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          Text(
            'TEMPLATE TERSEDIA (${InvoiceTemplate.values.length})',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),

          // Daftar Card Template
          ...InvoiceTemplate.values.map((template) {
            final isSelected = template == currentTemplate;
            return _buildTemplateCard(context, ref, template, isSelected);
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, WidgetRef ref, InvoiceTemplate template, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppColors.primaryGold : AppColors.borderLight, width: isSelected ? 2 : 1),
        boxShadow: [
          if (isSelected)
            BoxShadow(color: AppColors.primaryGold.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))
          else
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Badge & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: Color(template.accentHex), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      template.subtitle,
                      style: AppTypography.caption.copyWith(color: AppColors.textLight, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryGold, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Digunakan',
                          style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Tersedia',
                    style: AppTypography.caption.copyWith(color: AppColors.textLight, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),

          // Mini Mockup Desain Visual
          Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: _buildMiniVisualMockup(template)),
          const SizedBox(height: 14),

          // Informasi Template
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Text(template.description, style: AppTypography.bodySmall.copyWith(color: AppColors.textLight, fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Divider(height: 1, color: AppColors.dividerColor),

          // Tombol Aksi: Pratinjau & Pilih
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                // Tombol Pratinjau
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openPreviewWithSample(context, template),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.textDark),
                    label: Text(
                      'Pratinjau',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Pilih Template
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSelected
                        ? null
                        : () async {
                            await ref.read(invoiceTemplateProvider.notifier).setTemplate(template);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.successGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Template diubah ke ${template.name}',
                                          style: AppTypography.bodySmall.copyWith(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.grey.shade300 : AppColors.primaryGold,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isSelected ? 'Aktif' : 'Pilih Template',
                      style: AppTypography.labelMedium.copyWith(color: isSelected ? AppColors.textLight : Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mini visual card mockup untuk memberikan gambaran estetika layout template
  Widget _buildMiniVisualMockup(InvoiceTemplate template) {
    if (template == InvoiceTemplate.minimalistGrey) {
      // Mockup Template Minimalist Grey (Chevron abu-abu, garis tabel tegas hitam)
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Header Chevron Mockup
              Container(
                height: 34,
                color: const Color(0xFFDFE2E6),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 48, height: 7, color: Colors.black87),
                        const SizedBox(height: 3),
                        Container(width: 70, height: 5, color: Colors.black54),
                      ],
                    ),
                    Row(
                      children: [
                        Transform.rotate(angle: 0.35, child: Container(width: 6, height: 26, color: Colors.white)),
                        const SizedBox(width: 6),
                        Transform.rotate(angle: 0.35, child: Container(width: 8, height: 26, color: const Color(0xFFC7CBD1))),
                      ],
                    ),
                  ],
                ),
              ),
              // Body Mockup
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 50, height: 5, color: Colors.grey.shade400),
                        Container(width: 45, height: 5, color: Colors.grey.shade400),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, color: Colors.black),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 75, height: 5, color: Colors.grey.shade600),
                        Container(width: 35, height: 5, color: Colors.grey.shade700),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 60, height: 5, color: Colors.grey.shade600),
                        Container(width: 35, height: 5, color: Colors.grey.shade700),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(height: 2, color: Colors.black),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mockup Template Modern Navy & Gold (Heksagonal navy & aksen emas)
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header Navy & Heksagonal Mockup
            Container(
              height: 34,
              color: const Color(0xFF1C3B57),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(color: const Color(0xFFE5B824), borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 50, height: 6, color: Colors.white),
                          const SizedBox(height: 3),
                          Container(width: 65, height: 4, color: Colors.white70),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5B824), width: 1.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            // Body Mockup
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Column(
                children: [
                  Container(
                    height: 12,
                    color: const Color(0xFFE5B824),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 40, height: 4, color: const Color(0xFF1C3B57)),
                        Container(width: 30, height: 4, color: const Color(0xFF1C3B57)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 80, height: 5, color: Colors.grey.shade500),
                      Container(width: 40, height: 5, color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 60, height: 5, color: Colors.grey.shade500),
                      Container(width: 40, height: 5, color: Colors.grey.shade600),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Bottom Bar Emas
            Container(height: 6, color: const Color(0xFFE5B824)),
          ],
        ),
      ),
    );
  }

  void _openPreviewWithSample(BuildContext context, InvoiceTemplate template) {
    // Agenda contoh untuk pratinjau live PDF
    final sampleAgenda = AgendaItem(
      id: 'FB001',
      clientName: 'Juwita',
      clientPhone: '0895-1678-9565',
      eventDateTime: DateTime.now(),
      packageId: 'pkg_platinum',
      packageName: 'Backdrop Platinum',
      packagePrice: 1100000,
      transportFee: 400000,
      dpAmount: 200000,
      modelName: 'Platinum Minimalis',
      modelWidth: '3 Meter',
      notes: '',
      backdropTitle: 'Wedding & Lamaran',
      mapsUrl: 'Jl. Mayor Oking Jaya Atmaja, Ciriung - Cibinong, Kab Bogor',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewView(agenda: sampleAgenda, forcedTemplate: template),
      ),
    );
  }
}
