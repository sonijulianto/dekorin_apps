import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/couple_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/wedding_plan.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/couple/view_models/couple_plan_provider.dart';

/// Direktori Publik Vendor Multi-Kategori untuk Calon Pengantin.
class VendorDirectoryView extends ConsumerStatefulWidget {
  const VendorDirectoryView({super.key});

  @override
  ConsumerState<VendorDirectoryView> createState() => _VendorDirectoryViewState();
}

class _VendorDirectoryViewState extends ConsumerState<VendorDirectoryView> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'all';
  bool _isLoading = true;
  bool _hasAddedVendor = false;
  List<PublicVendorSummary> _vendors = [];

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);
    try {
      final list = await ref.read(coupleServiceProvider).getPublicVendors(
            category: _selectedCategory,
            search: _searchCtrl.text.trim(),
          );
      if (mounted) {
        setState(() {
          _vendors = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      const MapEntry('all', 'Semua'),
      ...VendorCategoryOption.all.map((c) => MapEntry(c.id, c.shortLabel)),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _hasAddedVendor);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text('Direktori Vendor', style: AppTypography.titleLarge),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context, _hasAddedVendor),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  DekorinTextField(
                    controller: _searchCtrl,
                    hint: 'Cari nama vendor atau kota...',
                    prefixIcon: Icons.search,
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => _loadVendors(),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadVendors();
                            },
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final selected = _selectedCategory == cat.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat.value,
                              style: AppTypography.labelMedium.copyWith(
                                color: selected ? Colors.white : AppColors.textDark,
                              ),
                            ),
                            selected: selected,
                            selectedColor: AppColors.primaryGold,
                            backgroundColor: AppColors.backgroundLight,
                            onSelected: (_) {
                              setState(() => _selectedCategory = cat.key);
                              _loadVendors();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                  : _vendors.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Belum ada vendor terdaftar pada kategori atau pencarian ini.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primaryGold,
                          onRefresh: _loadVendors,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _vendors.length,
                            itemBuilder: (context, index) => _buildVendorSummaryCard(_vendors[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorSummaryCard(PublicVendorSummary vendor) {
    final catLabel = VendorCategoryOption.byId(vendor.category).shortLabel;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => PublicVendorDetailView(vendorId: vendor.id)),
          );
          if (added == true) {
            _hasAddedVendor = true;
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: vendor.logoUrl.isNotEmpty
                        ? Image.network(
                            vendor.logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset('assets/images/logo_icon.png', fit: BoxFit.contain),
                          )
                        : Image.asset('assets/images/logo_icon.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                catLabel,
                                style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (vendor.city.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  vendor.city,
                                  style: AppTypography.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(vendor.name, style: AppTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (vendor.minPrice > 0)
                          Text(
                            'Mulai ${formatCoupleRupiah(vendor.minPrice)}',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.primaryGold),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (vendor.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(vendor.description, style: AppTypography.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (vendor.sampleImages.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: vendor.sampleImages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, imgIdx) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        vendor.sampleImages[imgIdx],
                        width: 96,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(width: 96, height: 72, color: AppColors.goldLight),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Halaman Detail Profil Vendor Publik lengkap dengan Paket & Portofolio.
class PublicVendorDetailView extends ConsumerStatefulWidget {
  const PublicVendorDetailView({super.key, required this.vendorId});

  final String vendorId;

  @override
  ConsumerState<PublicVendorDetailView> createState() => _PublicVendorDetailViewState();
}

class _PublicVendorDetailViewState extends ConsumerState<PublicVendorDetailView> {
  PublicVendorDetail? _detail;
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final d = await ref.read(coupleServiceProvider).getPublicVendorDetail(widget.vendorId);
      if (mounted) {
        setState(() {
          _detail = d;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openWhatsApp(PublicVendorSummary v) async {
    var clean = v.phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    if (clean.startsWith('0')) clean = '62${clean.substring(1)}';
    final msg = Uri.encodeComponent('Halo ${v.name}, saya melihat profil Anda di Dekorin dan ingin konsultasi untuk acara pernikahan kami.');
    final uri = Uri.parse('https://wa.me/$clean?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _addToPlan({String packageName = '', double price = 0}) async {
    setState(() => _isAdding = true);
    try {
      await ref.read(coupleServiceProvider).addPublicVendorToPlan(
            companyId: widget.vendorId,
            packageName: packageName,
            agreedPrice: price,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vendor ditambahkan ke Wedding Plan Anda!', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(detail?.summary.name ?? 'Detail Vendor', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
          : detail == null
              ? Center(child: Text('Detail vendor tidak ditemukan', style: AppTypography.bodyMedium))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(16)),
                                clipBehavior: Clip.antiAlias,
                                child: detail.summary.logoUrl.isNotEmpty
                                    ? Image.network(detail.summary.logoUrl, fit: BoxFit.cover)
                                    : Image.asset('assets/images/logo_icon.png', fit: BoxFit.contain),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      VendorCategoryOption.byId(detail.summary.category).label,
                                      style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                    ),
                                    Text(detail.summary.name, style: AppTypography.h3),
                                    if (detail.summary.city.isNotEmpty || detail.summary.address.isNotEmpty)
                                      Text(
                                        [detail.summary.city, detail.summary.address].where((e) => e.isNotEmpty).join(' • '),
                                        style: AppTypography.caption,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (detail.summary.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(detail.summary.description, style: AppTypography.bodyMedium),
                          ],
                          if (detail.summary.instagram.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Instagram: ${detail.summary.instagram}', style: AppTypography.bodySmall.copyWith(color: AppColors.primaryGold)),
                          ],
                        ],
                      ),
                    ),
                    if (detail.packages.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('PAKET LAYANAN', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...detail.packages.map(
                        (pkg) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              if (pkg.imageUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(pkg.imageUrl, width: 62, height: 62, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pkg.name, style: AppTypography.titleSmall),
                                    if (pkg.description.isNotEmpty)
                                      Text(pkg.description, style: AppTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatCoupleRupiah(pkg.basePrice),
                                      style: AppTypography.titleSmall.copyWith(color: AppColors.primaryGold),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _isAdding ? null : () => _addToPlan(packageName: pkg.name, price: pkg.basePrice),
                                child: Text('Pilih', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (detail.models.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('PORTOFOLIO & MODEL', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: detail.models.length,
                        itemBuilder: (_, idx) {
                          final m = detail.models[idx];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: m.imageUrl.isNotEmpty
                                      ? Image.network(m.imageUrl, width: double.infinity, fit: BoxFit.cover)
                                      : Container(color: AppColors.goldLight),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.name, style: AppTypography.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      if (m.price > 0)
                                        Text(
                                          formatCoupleRupiah(m.price),
                                          style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
      bottomNavigationBar: detail == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  children: [
                    if (detail.summary.phone.isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openWhatsApp(detail.summary),
                          icon: SvgPicture.asset('assets/icons/wa.svg', width: 18, height: 18),
                          label: Text('Chat WA', style: AppTypography.labelLarge.copyWith(color: AppColors.successGreen)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            side: const BorderSide(color: AppColors.successGreen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isAdding ? null : () => _addToPlan(),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _isAdding ? 'Menambahkan...' : 'Simpan ke Wedding Plan',
                          style: AppTypography.button,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
