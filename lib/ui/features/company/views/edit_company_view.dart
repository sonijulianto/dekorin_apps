import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class EditCompanyView extends ConsumerStatefulWidget {
  const EditCompanyView({super.key});

  @override
  ConsumerState<EditCompanyView> createState() => _EditCompanyViewState();
}

class _EditCompanyViewState extends ConsumerState<EditCompanyView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _descriptionController;
  late TextEditingController _instagramController;
  late TextEditingController _bankInfoController;

  File? _selectedImageFile;
  String _currentLogoUrl = '';
  CompanyProfile? _companyProfile;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _emailController = TextEditingController();
    _descriptionController = TextEditingController();
    _instagramController = TextEditingController();
    _bankInfoController = TextEditingController();

    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _bankInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // 1. Ambil data cepat dari cache user yang sedang login
    final currentUser = ref.read(globalAuthProvider).value;
    if (currentUser != null) {
      _nameController.text = currentUser.companyName;
      _phoneController.text = currentUser.companyPhone;
      _addressController.text = currentUser.companyAddress;
      _currentLogoUrl = currentUser.companyLogo;
      _emailController.text = currentUser.companyEmail;
      _descriptionController.text = currentUser.companyDescription;
      _instagramController.text = currentUser.companyInstagram;
      _bankInfoController.text = currentUser.companyBankInfo;
    }

    // 2. Fetch data terbaru dari server
    try {
      final profile = await ref.read(companyServiceProvider).getCompanyProfile();
      if (mounted) {
        setState(() {
          _companyProfile = profile;
          _nameController.text = profile.name;
          _phoneController.text = profile.phone;
          _addressController.text = profile.address;
          _emailController.text = profile.email;
          _currentLogoUrl = profile.logoUrl;
          _descriptionController.text = profile.description;
          _instagramController.text = profile.instagram;
          _bankInfoController.text = profile.bankInfo;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih logo: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pilih Sumber Foto Logo', style: AppTypography.titleMedium),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryGold),
                  title: Text('Ambil dari Galeri', style: AppTypography.bodyMedium),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickLogo(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGold),
                  title: Text('Ambil dari Kamera', style: AppTypography.bodyMedium),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickLogo(ImageSource.camera);
                  },
                ),
                if (_selectedImageFile != null || _currentLogoUrl.isNotEmpty) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                    title: Text(
                      'Hapus Logo Saat Ini',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.errorRed),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedImageFile = null;
                        _currentLogoUrl = '';
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCompanyProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(globalAuthProvider).value;
    if (user == null || (!user.isOwner && !user.isAdmin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hanya Owner dan Administrator yang dapat memperbarui data usaha.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String finalLogoUrl = _currentLogoUrl;

      // 1. Upload foto baru jika ada yang dipilih
      if (_selectedImageFile != null) {
        final uploadedUrl = await ApiClient.uploadImage(_selectedImageFile!);
        if (uploadedUrl.isNotEmpty) {
          finalLogoUrl = uploadedUrl;
        }
      }

      // 2. Simpan perubahan ke backend
      final updatedProfile = await ref.read(companyServiceProvider).updateCompanyProfile(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            logoUrl: finalLogoUrl,
            description: _descriptionController.text.trim(),
            instagram: _instagramController.text.trim(),
            bankInfo: _bankInfoController.text.trim(),
          );

      // 3. Update global session auth agar perubahan langsung terlihat di seluruh aplikasi
      await ref.read(globalAuthProvider.notifier).updateCompanyData(
            name: updatedProfile.name,
            address: updatedProfile.address,
            phone: updatedProfile.phone,
            logoUrl: updatedProfile.logoUrl,
            email: updatedProfile.email,
            description: updatedProfile.description,
            instagram: updatedProfile.instagram,
            bankInfo: updatedProfile.bankInfo,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data profil usaha dekorasi berhasil disimpan!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
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
    final user = ref.watch(globalAuthProvider).value;
    final isAuthorized = user?.canManageCompany ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Profil Usaha Dekorasi', style: AppTypography.titleLarge),
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
          : !isAuthorized
              ? _buildUnauthorizedView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header: Logo Usaha
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: AppColors.primaryGold,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryGold.withValues(alpha: 0.15),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(21),
                                        child: _buildLogoPreview(),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGold,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: _showImageSourceDialog,
                                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                                label: Text(
                                  _selectedImageFile != null || _currentLogoUrl.isNotEmpty
                                      ? 'Ubah Logo Usaha'
                                      : 'Unggah Logo Usaha',
                                  style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold),
                                ),
                              ),
                              Text(
                                'Logo akan tampil di Profil Aplikasi dan Invoice Resmi',
                                style: AppTypography.caption.copyWith(color: AppColors.textLight),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Info Audit Terakhir Diperbarui (jika ada)
                        if (_companyProfile?.updatedByName.isNotEmpty == true ||
                            _companyProfile?.updatedAt != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.history_edu_rounded, size: 20, color: Colors.blue),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _formatAuditText(_companyProfile!),
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFF1565C0),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Identitas Pokok Usaha
                        _buildSectionHeader('INFORMASI UTAMA USAHA'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            children: [
                              DekorinTextField(
                                controller: _nameController,
                                label: 'Nama Usaha Dekorasi *',
                                hint: 'Contoh: Dekorin Wedding & Event',
                                prefixIcon: Icons.storefront,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Nama usaha tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DekorinTextField(
                                controller: _descriptionController,
                                label: 'Slogan / Deskripsi Singkat',
                                hint: 'Contoh: Wedding & Event Decoration Vendor',
                                prefixIcon: Icons.info_outline,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Kontak & Alamat
                        _buildSectionHeader('KONTAK & ALAMAT'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            children: [
                              DekorinTextField(
                                controller: _phoneController,
                                label: 'Nomor WhatsApp / Telp Usaha *',
                                hint: '081234567890',
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_android,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Nomor telepon usaha wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DekorinTextField(
                                controller: _emailController,
                                label: 'Email Resmi Usaha',
                                hint: 'kontak@dekorin.id',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.mail_outline,
                              ),
                              const SizedBox(height: 16),
                              DekorinTextField(
                                controller: _addressController,
                                label: 'Alamat Workshop / Kantor Usaha',
                                hint: 'Jl. Melati Raya No. 123, Jakarta Selatan',
                                maxLines: 3,
                                prefixIcon: Icons.location_on_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Rekening Pembayaran & Medsos (Untuk Tampil di Invoice & Profil)
                        _buildSectionHeader('DATA INVOICE & REKENING PEMBAYARAN'),
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
                              DekorinTextField(
                                controller: _bankInfoController,
                                label: 'Informasi Rekening Pembayaran',
                                hint: 'Contoh: Bank BCA\nNo Rek: 873-501-9920\na.n Dekorin Official',
                                maxLines: 3,
                                prefixIcon: Icons.account_balance_outlined,
                                helperText: 'Akan dicetak di bagian "Payment Method" pada Invoice PDF',
                              ),
                              const SizedBox(height: 16),
                              DekorinTextField(
                                controller: _instagramController,
                                label: 'Instagram / Media Sosial',
                                hint: '@dekorin_wedding',
                                prefixIcon: Icons.camera_alt_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Tombol Simpan
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveCompanyProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.save_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Simpan Data Profil Usaha',
                                        style: AppTypography.button.copyWith(fontSize: 16),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildLogoPreview() {
    if (_selectedImageFile != null) {
      return Image.file(
        _selectedImageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_currentLogoUrl.isNotEmpty) {
      return Image.network(
        _currentLogoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildFallbackLogoWidget(),
      );
    }

    return _buildFallbackLogoWidget();
  }

  Widget _buildFallbackLogoWidget() {
    return Container(
      color: AppColors.goldLight,
      child: Center(
        child: Image.asset(
          'assets/images/logo_icon.png',
          width: 52,
          height: 52,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.storefront,
            size: 48,
            color: AppColors.primaryGold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.textLight,
        ),
      ),
    );
  }

  String _formatAuditText(CompanyProfile profile) {
    final buffer = StringBuffer('Terakhir diperbarui');
    if (profile.updatedByName.isNotEmpty) {
      buffer.write(' oleh ${profile.updatedByName}');
    }
    if (profile.updatedAt != null) {
      final formatted = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(profile.updatedAt!.toLocal());
      buffer.write(' pada $formatted WIB');
    }
    return buffer.toString();
  }

  Widget _buildUnauthorizedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gpp_bad_rounded, size: 64, color: AppColors.errorRed),
            const SizedBox(height: 16),
            Text('Akses Dibatasi', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Halaman pengaturan data profil badan usaha hanya dapat diakses oleh Owner dan Administrator.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
