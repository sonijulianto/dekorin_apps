import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/services/auth_service.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

/// Layar pendaftaran mandiri untuk akun Calon Pengantin ('couple').
class RegisterCoupleView extends ConsumerStatefulWidget {
  const RegisterCoupleView({super.key});

  @override
  ConsumerState<RegisterCoupleView> createState() => _RegisterCoupleViewState();
}

class _RegisterCoupleViewState extends ConsumerState<RegisterCoupleView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _partnerNameController = TextEditingController();
  final _weddingDateController = TextEditingController();
  final _cityController = TextEditingController();
  final _joinCodeController = TextEditingController();

  bool _hasJoinCode = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _partnerNameController.dispose();
    _weddingDateController.dispose();
    _cityController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickWeddingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryGold),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() {
        _weddingDateController.text = '$y-$m-$d';
      });
    }
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userModel = await ref.read(authServiceProvider).registerCouple(
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            partnerName: _hasJoinCode ? null : _partnerNameController.text.trim(),
            weddingDate: _hasJoinCode ? null : _weddingDateController.text.trim(),
            city: _hasJoinCode ? null : _cityController.text.trim(),
            joinCode: _hasJoinCode ? _joinCodeController.text.trim().toUpperCase() : null,
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
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Daftar Calon Pengantin', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/user.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wedding Plan Terintegrasi',
                              style: AppTypography.titleSmall.copyWith(color: AppColors.textDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Atur checklist, budget vendor, dan kelola undangan digital dalam satu aplikasi.',
                              style: AppTypography.caption.copyWith(color: AppColors.textDark.withValues(alpha: 0.75)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Data Akun Utama
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
                      Text('DATA AKUN ANDA', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      DekorinTextField(
                        controller: _fullNameController,
                        label: 'Nama Lengkap *',
                        hint: 'Contoh: Bagas Pratama',
                        prefixIcon: Icons.person_outline,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama lengkap wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DekorinTextField(
                        controller: _phoneController,
                        label: 'Nomor WhatsApp / HP *',
                        hint: '081234567890',
                        keyboardType: TextInputType.phone,
                        prefixWidget: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgPicture.asset(
                            'assets/icons/mobile-notch.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(AppColors.textLight, BlendMode.srcIn),
                          ),
                        ),
                        validator: (val) {
                          final digits = (val ?? '').replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 9) {
                            return 'Nomor HP minimal 9 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DekorinTextField(
                        controller: _passwordController,
                        label: 'Password *',
                        hint: 'Minimal 6 karakter',
                        obscureText: !_isPasswordVisible,
                        prefixWidget: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgPicture.asset(
                            'assets/icons/lock.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(AppColors.textLight, BlendMode.srcIn),
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textLight,
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Data Rencana Pernikahan / Kode Gabung Pasangan
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
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primaryGold,
                        title: Text('Gabung ke Wedding Plan Pasangan', style: AppTypography.titleSmall),
                        subtitle: Text(
                          'Aktifkan jika pasangan Anda sudah membuat Wedding Plan dan memberi kode gabung',
                          style: AppTypography.caption,
                        ),
                        value: _hasJoinCode,
                        onChanged: (val) => setState(() => _hasJoinCode = val),
                      ),
                      const SizedBox(height: 10),
                      if (_hasJoinCode) ...[
                        DekorinTextField(
                          controller: _joinCodeController,
                          label: 'Kode Gabung Pasangan (8 Karakter) *',
                          hint: 'Contoh: A7K9P2MX',
                          prefixIcon: Icons.vpn_key_outlined,
                          validator: (val) {
                            if (_hasJoinCode && (val == null || val.trim().isEmpty)) {
                              return 'Masukkan kode gabung dari pasangan Anda';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        DekorinTextField(
                          controller: _partnerNameController,
                          label: 'Nama Pasangan (Opsional)',
                          hint: 'Contoh: Zulia Rahma',
                          prefixIcon: Icons.favorite_border,
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _pickWeddingDate,
                          child: AbsorbPointer(
                            child: DekorinTextField(
                              controller: _weddingDateController,
                              label: 'Perkiraan Tanggal Acara (Opsional)',
                              hint: 'Pilih tanggal acara (YYYY-MM-DD)',
                              prefixWidget: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SvgPicture.asset(
                                  'assets/icons/calendar.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(AppColors.textLight, BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DekorinTextField(
                          controller: _cityController,
                          label: 'Kota Acara (Opsional)',
                          hint: 'Contoh: Jakarta / Bandung / Surabaya',
                          prefixIcon: Icons.location_city_outlined,
                        ),
                      ],
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text('Buat Akun & Mulai Wedding Plan', style: AppTypography.button),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
