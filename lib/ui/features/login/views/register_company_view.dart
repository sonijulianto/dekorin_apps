import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/services/auth_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

/// Halaman pendaftaran mandiri usaha & akun Owner baru.
class RegisterCompanyView extends ConsumerStatefulWidget {
  const RegisterCompanyView({super.key});

  @override
  ConsumerState<RegisterCompanyView> createState() => _RegisterCompanyViewState();
}

class _RegisterCompanyViewState extends ConsumerState<RegisterCompanyView> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedCategory = 'decoration';
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _companyNameController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userModel = await ref.read(authServiceProvider).registerVendor(
            companyName: _companyNameController.text.trim(),
            companyCategory: _selectedCategory,
            ownerName: _ownerNameController.text.trim(),
            ownerPhone: _ownerPhoneController.text.trim(),
            ownerPassword: _passwordController.text,
          );

      ref.read(globalAuthProvider.notifier).setUser(userModel.toDomain());
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal mendaftar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: Text('Daftar Usaha Baru', style: AppTypography.titleLarge),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Buat akun usaha Anda dan mulai kelola agenda, katalog paket, hingga invoice dengan mudah.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // --- Nama Usaha ---
                    DekorinTextField(
                      controller: _companyNameController,
                      label: 'Nama Usaha *',
                      hint: 'Contoh: Studio Foto & Video Cahaya',
                      prefixWidget: const Icon(Icons.storefront_rounded, color: AppColors.textLight, size: 22),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama usaha wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Tipe / Kategori Usaha ---
                    Text(
                      'Tipe Usaha *',
                      style: AppTypography.labelLarge.copyWith(fontSize: 13, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                        ),
                      ),
                      style: AppTypography.bodyMedium,
                      items: VendorCategoryOption.all
                          .map((opt) => DropdownMenuItem<String>(
                                value: opt.id,
                                child: Text(opt.label, style: AppTypography.bodyMedium),
                              ))
                          .toList(),
                      onChanged: _isLoading
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // --- Nama Lengkap Owner ---
                    DekorinTextField(
                      controller: _ownerNameController,
                      label: 'Nama Lengkap *',
                      hint: 'Contoh: Budi Santoso',
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Nomor WhatsApp / HP ---
                    DekorinTextField(
                      controller: _ownerPhoneController,
                      label: 'Nomor WhatsApp / HP (Untuk Login) *',
                      hint: '081234567890',
                      prefixWidget: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SvgPicture.asset(
                          'assets/icons/mobile-notch.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(AppColors.textLight, BlendMode.srcIn),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 9) return 'Nomor WhatsApp / HP minimal 9 digit';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Password ---
                    DekorinTextField(
                      controller: _passwordController,
                      label: 'Password *',
                      hint: 'Minimal 6 karakter',
                      prefixWidget: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SvgPicture.asset(
                          'assets/icons/lock.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(AppColors.textLight, BlendMode.srcIn),
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitRegister(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textLight,
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      validator: (v) => (v == null || v.trim().length < 6) ? 'Password minimal 6 karakter' : null,
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.errorRed, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitRegister,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text('Daftar Sekarang', style: AppTypography.button),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Sudah punya akun? Masuk',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
