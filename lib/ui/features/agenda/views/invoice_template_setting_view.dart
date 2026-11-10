import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/invoice_template.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/invoice_template_provider.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_preview_view.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

/// Halaman Pengaturan untuk Memilih Template Invoice per Brand (disimpan di database).
class InvoiceTemplateSettingView extends ConsumerStatefulWidget {
  const InvoiceTemplateSettingView({super.key});

  @override
  ConsumerState<InvoiceTemplateSettingView> createState() => _InvoiceTemplateSettingViewState();
}

class _InvoiceTemplateSettingViewState extends ConsumerState<InvoiceTemplateSettingView> {
  String _selectedBrandId = '';
  String? _savingTemplateId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFromServer();
    });
  }

  Future<void> _refreshFromServer() async {
    ref.invalidate(companyBrandsProvider);
    await ref.read(invoiceTemplateProvider.notifier).syncFromServer(brandId: _selectedBrandId);
  }

  CompanyBrand? _findSelectedBrand(List<CompanyBrand> brands) {
    if (_selectedBrandId.isEmpty) return null;
    for (final b in brands) {
      if (b.id == _selectedBrandId) return b;
    }
    return null;
  }

  String _selectedBrandDisplayName(List<CompanyBrand> brands) {
    final brand = _findSelectedBrand(brands);
    if (brand != null) return brand.name;
    return 'Brand Utama';
  }

  Future<void> _selectTemplate(
    InvoiceTemplate template,
    List<CompanyBrand> brands,
  ) async {
    if (_savingTemplateId != null) return;
    setState(() => _savingTemplateId = template.id);

    try {
      await ref.read(invoiceTemplateProvider.notifier).setTemplateForBrand(
            brandId: _selectedBrandId,
            template: template,
          );
      if (!mounted) return;
      final brandLabel = _selectedBrandDisplayName(brands);
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
                  'Template $brandLabel diubah ke ${template.name}',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            'Gagal menyimpan template: $errMsg',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingTemplateId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templateState = ref.watch(invoiceTemplateProvider);
    final brands = ref.watch(companyBrandsProvider).valueOrNull ?? const <CompanyBrand>[];
    final user = ref.watch(globalAuthProvider).valueOrNull;
    final mainBrandName = (user?.companyName.isNotEmpty ?? false) ? user!.companyName : 'Brand Utama';

    final selectedBrand = _findSelectedBrand(brands);
    final effectiveBrandId = selectedBrand?.id ?? '';
    if (effectiveBrandId != _selectedBrandId && brands.isNotEmpty && _selectedBrandId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedBrandId = '');
      });
    }

    final currentTemplate = templateState.templateForBrand(effectiveBrandId);
    final isInherited = templateState.isBrandInherited(effectiveBrandId);

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
        actions: [
          IconButton(
            tooltip: 'Sinkronkan dari server',
            icon: templateState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGold),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.textDark),
            onPressed: templateState.isLoading ? null : _refreshFromServer,
          ),
        ],
      ),
      body: Column(
        children: [
          // Brand / Sub-Brand Selector Tabs (jika perusahaan memiliki Sub-Brand)
          if (brands.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Brand / Sub-Brand:',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(
                            '$mainBrandName (Utama)',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: effectiveBrandId.isEmpty ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          selected: effectiveBrandId.isEmpty,
                          selectedColor: AppColors.primaryGold,
                          backgroundColor: AppColors.goldLight,
                          onSelected: (_) {
                            setState(() => _selectedBrandId = '');
                          },
                        ),
                        ...brands.map((b) {
                          final isSelectedBrand = effectiveBrandId == b.id;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text(
                                b.name,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelectedBrand ? Colors.white : AppColors.textDark,
                                ),
                              ),
                              selected: isSelectedBrand,
                              selectedColor: AppColors.primaryGold,
                              backgroundColor: AppColors.goldLight,
                              onSelected: (_) {
                                setState(() => _selectedBrandId = b.id);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  if (effectiveBrandId.isNotEmpty && isInherited) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        'Sub-brand ini masih mengikuti Brand Utama (${templateState.defaultTemplate.name}). Pilih template di bawah untuk mengatur khusus brand ini.',
                        style: AppTypography.caption.copyWith(color: Colors.amber.shade900, fontSize: 11.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGold,
              onRefresh: _refreshFromServer,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                children: [
                  if (templateState.errorMessage != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 18, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Gagal menyinkronkan ke server. Tarik ke bawah untuk coba lagi.',
                              style: AppTypography.caption.copyWith(color: Colors.red.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_done_outlined, size: 18, color: AppColors.primaryGold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            brands.isNotEmpty
                                ? 'Tersimpan terpusat di database untuk ${_selectedBrandDisplayName(brands)} & seragam bagi seluruh admin.'
                                : 'Tersimpan terpusat di database & seragam bagi seluruh admin di usaha ini.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    'TEMPLATE TERSEDIA (${InvoiceTemplate.values.length})',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Daftar Card Template
                  ...InvoiceTemplate.values.map((template) {
                    final isSelected = template == currentTemplate;
                    return _buildTemplateCard(context, template, isSelected, selectedBrand, brands);
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    InvoiceTemplate template,
    bool isSelected,
    CompanyBrand? selectedBrand,
    List<CompanyBrand> brands,
  ) {
    final isSavingThis = _savingTemplateId == template.id;
    final isAnySaving = _savingTemplateId != null;

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
                    onPressed: () => _openPreviewWithSample(context, template, selectedBrand),
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
                    onPressed: (isSelected || isAnySaving) ? null : () => _selectTemplate(template, brands),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.grey.shade300 : AppColors.primaryGold,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isSavingThis
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isSelected ? 'Aktif' : 'Pilih Template',
                            style: AppTypography.labelMedium.copyWith(
                              color: isSelected ? AppColors.textLight : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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

  void _openPreviewWithSample(
    BuildContext context,
    InvoiceTemplate template,
    CompanyBrand? selectedBrand,
  ) {
    // Agenda contoh untuk pratinjau live PDF (menyesuaikan brand yang sedang dipilih)
    final sampleAgenda = AgendaItem(
      id: 'FB001',
      brandId: selectedBrand?.id ?? '',
      brandName: selectedBrand?.name ?? '',
      brandLogo: selectedBrand?.logoUrl ?? '',
      brandPhone: selectedBrand?.phone ?? '',
      brandInstagram: selectedBrand?.instagram ?? '',
      brandDescription: selectedBrand?.description ?? '',
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
