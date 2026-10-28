import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/company/views/edit_company_view.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class ManageBrandsView extends ConsumerWidget {
  const ManageBrandsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(globalAuthProvider).value;
    final brandsAsync = ref.watch(companyBrandsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Kelola Brand Usaha', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        onRefresh: () async {
          ref.invalidate(companyBrandsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            // Banner Info Multi-Brand
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.layers_outlined, color: AppColors.primaryGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1 Pencatatan Keuangan, Banyak Brand',
                          style: AppTypography.titleSmall.copyWith(color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Setiap brand memiliki Nama, Logo, Kontak WA, Instagram, serta Katalog Paket & Model sendiri untuk Invoice PDF & Link Klien. Alamat & Nomor Rekening tetap menggunakan profil usaha utama.',
                          style: AppTypography.caption.copyWith(color: AppColors.textLight, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Brand Utama Card
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'BRAND UTAMA (DEFAULT)',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.textLight,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildLogoAvatar(user?.companyLogo ?? ''),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user?.companyName.isNotEmpty == true ? user!.companyName : 'Brand Utama',
                                    style: AppTypography.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    'Utama',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondaryGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (user?.companyDescription.isNotEmpty == true) ...[
                              const SizedBox(height: 2),
                              Text(
                                user!.companyDescription,
                                style: AppTypography.caption.copyWith(color: AppColors.textLight),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                if (user?.companyPhone.isNotEmpty == true)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset('assets/icons/wa.svg', width: 13, height: 13),
                                      const SizedBox(width: 4),
                                      Text(user!.companyPhone, style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                                    ],
                                  ),
                                if (user?.companyInstagram.isNotEmpty == true)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.camera_alt_outlined, size: 13, color: AppColors.primaryGold),
                                      const SizedBox(width: 4),
                                      Text(user!.companyInstagram, style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Ubah Profil Utama',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditCompanyView()));
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/edit.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daftar Sub-Brand Tambahan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'SUB-BRAND / LINI MARKET LAINNYA',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            brandsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text('Gagal memuat daftar brand: $err', style: AppTypography.bodySmall),
              ),
              data: (brands) {
                if (brands.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: AppColors.goldLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_outlined, size: 32, color: AppColors.primaryGold),
                        ),
                        const SizedBox(height: 12),
                        Text('Belum Ada Sub-Brand Tambahan', style: AppTypography.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Tambahkan brand baru jika Anda memiliki nama usaha berbeda untuk market dekorasi lain (mis. Wedding vs Engagement / Kids Party).',
                          style: AppTypography.caption.copyWith(color: AppColors.textLight),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: brands.map((brand) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          _buildLogoAvatar(brand.logoUrl),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  brand.name,
                                  style: AppTypography.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (brand.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    brand.description,
                                    style: AppTypography.caption.copyWith(color: AppColors.textLight),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    if (brand.phone.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SvgPicture.asset('assets/icons/wa.svg', width: 13, height: 13),
                                          const SizedBox(width: 4),
                                          Text(brand.phone, style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                                        ],
                                      ),
                                    if (brand.instagram.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.camera_alt_outlined, size: 13, color: AppColors.primaryGold),
                                          const SizedBox(width: 4),
                                          Text(brand.instagram, style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit Brand',
                            onPressed: () => _showBrandFormSheet(context, ref, existing: brand),
                            icon: SvgPicture.asset(
                              'assets/icons/edit.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Hapus Brand',
                            onPressed: () => _confirmDeleteBrand(context, ref, brand),
                            icon: const Icon(Icons.delete_outline, color: AppColors.errorRed, size: 20),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBrandFormSheet(context, ref),
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.add_business_outlined, color: Colors.white),
        label: Text('Tambah Sub-Brand', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
      ),
    );
  }

  Widget _buildLogoAvatar(String logoUrl) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: logoUrl.isNotEmpty
            ? Image.network(
                logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Image.asset('assets/images/logo_icon.png', width: 28, height: 28),
                ),
              )
            : Center(
                child: Image.asset('assets/images/logo_icon.png', width: 28, height: 28),
              ),
      ),
    );
  }

  void _showBrandFormSheet(BuildContext context, WidgetRef ref, {CompanyBrand? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BrandFormSheet(existing: existing),
    );
  }

  void _confirmDeleteBrand(BuildContext context, WidgetRef ref, CompanyBrand brand) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Sub-Brand?', style: AppTypography.h3),
        content: Text(
          'Apakah Anda yakin ingin menghapus brand "${brand.name}"? Paket, model, dan agenda yang menggunakan brand ini akan dikembalikan ke Brand Utama.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(companyServiceProvider).deleteCompanyBrand(brand.id);
                ref.invalidate(companyBrandsProvider);
                ref.invalidate(packagesProvider);
                ref.invalidate(decorationModelsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sub-brand berhasil dihapus',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus brand: $e',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
            },
            child: Text('Hapus', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _BrandFormSheet extends ConsumerStatefulWidget {
  const _BrandFormSheet({this.existing});

  final CompanyBrand? existing;

  @override
  ConsumerState<_BrandFormSheet> createState() => _BrandFormSheetState();
}

class _BrandFormSheetState extends ConsumerState<_BrandFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _igCtrl;

  File? _pickedImageFile;
  String _currentLogoUrl = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
    _igCtrl = TextEditingController(text: widget.existing?.instagram ?? '');
    _currentLogoUrl = widget.existing?.logoUrl ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _igCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (file != null && mounted) {
      setState(() {
        _pickedImageFile = File(file.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String finalLogoUrl = _currentLogoUrl;
      if (_pickedImageFile != null) {
        final uploaded = await ApiClient.uploadImage(_pickedImageFile!);
        if (uploaded.isNotEmpty) {
          finalLogoUrl = uploaded;
        }
      }

      final service = ref.read(companyServiceProvider);
      if (widget.existing == null) {
        await service.createCompanyBrand(
          name: _nameCtrl.text.trim(),
          logoUrl: finalLogoUrl,
          description: _descCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          instagram: _igCtrl.text.trim(),
        );
      } else {
        await service.updateCompanyBrand(
          widget.existing!.id,
          name: _nameCtrl.text.trim(),
          logoUrl: finalLogoUrl,
          description: _descCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          instagram: _igCtrl.text.trim(),
        );
      }

      ref.invalidate(companyBrandsProvider);
      ref.invalidate(packagesProvider);
      ref.invalidate(decorationModelsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing == null ? 'Sub-Brand baru berhasil ditambahkan!' : 'Sub-Brand berhasil diperbarui!',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan brand: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Edit Sub-Brand' : 'Tambah Sub-Brand Baru',
                style: AppTypography.h3,
              ),
              const SizedBox(height: 4),
              Text(
                'Nomor rekening & alamat tetap mengikuti profil usaha utama.',
                style: AppTypography.caption.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 20),

              // Logo Picker
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryGold, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _pickedImageFile != null
                              ? Image.file(_pickedImageFile!, fit: BoxFit.cover)
                              : (_currentLogoUrl.isNotEmpty
                                  ? Image.network(
                                      _currentLogoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.primaryGold),
                                    )
                                  : const Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.primaryGold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _pickLogo,
                      child: Text(
                        _pickedImageFile != null || _currentLogoUrl.isNotEmpty ? 'Ubah Logo Brand' : 'Pilih Logo Brand',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              DekorinTextField(
                controller: _nameCtrl,
                label: 'Nama Brand *',
                hint: 'Contoh: Dekorin Engagement & Intimate',
                prefixIcon: Icons.storefront_outlined,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama brand wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              DekorinTextField(
                controller: _descCtrl,
                label: 'Slogan / Deskripsi Singkat',
                hint: 'Contoh: Intimate Engagement & Party Stylist',
                prefixIcon: Icons.info_outline,
              ),
              const SizedBox(height: 14),
              DekorinTextField(
                controller: _phoneCtrl,
                label: 'Nomor WhatsApp Brand',
                hint: '081234567890 (Kosongkan jika sama dengan utama)',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_android,
              ),
              const SizedBox(height: 14),
              DekorinTextField(
                controller: _igCtrl,
                label: 'Instagram Brand',
                hint: '@dekorin.engagement',
                prefixIcon: Icons.camera_alt_outlined,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isEdit ? 'Simpan Perubahan Brand' : 'Simpan Sub-Brand',
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
