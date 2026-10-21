import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/services/invitation_service.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';

class InvitationFormView extends ConsumerStatefulWidget {
  const InvitationFormView({super.key, this.invitation});

  final InvitationItem? invitation;

  @override
  ConsumerState<InvitationFormView> createState() => _InvitationFormViewState();
}

class _InvitationFormViewState extends ConsumerState<InvitationFormView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _quotesController;

  late TextEditingController _groomNameController;
  late TextEditingController _groomNicknameController;
  late TextEditingController _groomParentsController;
  late TextEditingController _groomIgController;

  late TextEditingController _brideNameController;
  late TextEditingController _brideNicknameController;
  late TextEditingController _brideParentsController;
  late TextEditingController _brideIgController;

  late TextEditingController _akadDateController;
  late TextEditingController _akadTimeController;
  late TextEditingController _akadVenueController;
  late TextEditingController _akadAddressController;
  late TextEditingController _akadMapsController;

  late TextEditingController _resepsiDateController;
  late TextEditingController _resepsiTimeController;
  late TextEditingController _resepsiVenueController;
  late TextEditingController _resepsiAddressController;
  late TextEditingController _resepsiMapsController;

  late TextEditingController _bankName1Controller;
  late TextEditingController _bankAccount1Controller;
  late TextEditingController _bankHolder1Controller;

  late TextEditingController _bankName2Controller;
  late TextEditingController _bankAccount2Controller;
  late TextEditingController _bankHolder2Controller;

  late TextEditingController _giftAddressController;
  late TextEditingController _audioUrlController;

  String _coverImageUrl = '';
  String _groomPhotoUrl = '';
  String _bridePhotoUrl = '';

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final inv = widget.invitation;

    _titleController = TextEditingController(text: inv?.title ?? '');
    _slugController = TextEditingController(text: inv?.slug ?? '');
    _quotesController = TextEditingController(
      text: inv?.quotes ??
          '"Dan di antara tanda-tanda kekuasaan-Nya ialah Dia menciptakan untukmu isteri-isteri dari jenismu sendiri, supaya kamu cenderung dan merasa tenteram kepadanya, dan dijadikan-Nya di antaramu rasa kasih dan sayang." (QS. Ar-Rum: 21)',
    );

    _groomNameController = TextEditingController(text: inv?.groomName ?? '');
    _groomNicknameController = TextEditingController(text: inv?.groomNickname ?? '');
    _groomParentsController = TextEditingController(text: inv?.groomParents ?? '');
    _groomIgController = TextEditingController(text: inv?.groomInstagram ?? '');

    _brideNameController = TextEditingController(text: inv?.brideName ?? '');
    _brideNicknameController = TextEditingController(text: inv?.brideNickname ?? '');
    _brideParentsController = TextEditingController(text: inv?.brideParents ?? '');
    _brideIgController = TextEditingController(text: inv?.brideInstagram ?? '');

    _akadDateController = TextEditingController(text: inv?.akadDate ?? 'Sabtu, 20 Desember 2026');
    _akadTimeController = TextEditingController(text: inv?.akadTime ?? '08:00 - 10:00 WIB');
    _akadVenueController = TextEditingController(text: inv?.akadVenue ?? '');
    _akadAddressController = TextEditingController(text: inv?.akadAddress ?? '');
    _akadMapsController = TextEditingController(text: inv?.akadMapsUrl ?? '');

    _resepsiDateController = TextEditingController(text: inv?.resepsiDate ?? 'Sabtu, 20 Desember 2026');
    _resepsiTimeController = TextEditingController(text: inv?.resepsiTime ?? '11:00 - 14:00 WIB');
    _resepsiVenueController = TextEditingController(text: inv?.resepsiVenue ?? '');
    _resepsiAddressController = TextEditingController(text: inv?.resepsiAddress ?? '');
    _resepsiMapsController = TextEditingController(text: inv?.resepsiMapsUrl ?? '');

    _bankName1Controller = TextEditingController(text: inv?.bankName1 ?? 'BCA');
    _bankAccount1Controller = TextEditingController(text: inv?.bankAccount1 ?? '');
    _bankHolder1Controller = TextEditingController(text: inv?.bankHolder1 ?? '');

    _bankName2Controller = TextEditingController(text: inv?.bankName2 ?? 'Bank Mandiri');
    _bankAccount2Controller = TextEditingController(text: inv?.bankAccount2 ?? '');
    _bankHolder2Controller = TextEditingController(text: inv?.bankHolder2 ?? '');

    _giftAddressController = TextEditingController(text: inv?.giftAddress ?? '');
    _audioUrlController = TextEditingController(text: inv?.audioUrl ?? '');

    _coverImageUrl = inv != null 
        ? inv.coverImage 
        : '/assets/owlink/b9c1e420-cd8d-11f0-9fb2-69fd61d4e768.jpg';
    _groomPhotoUrl = inv?.groomPhoto ?? '';
    _bridePhotoUrl = inv?.bridePhoto ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _quotesController.dispose();
    _groomNameController.dispose();
    _groomNicknameController.dispose();
    _groomParentsController.dispose();
    _groomIgController.dispose();
    _brideNameController.dispose();
    _brideNicknameController.dispose();
    _brideParentsController.dispose();
    _brideIgController.dispose();
    _akadDateController.dispose();
    _akadTimeController.dispose();
    _akadVenueController.dispose();
    _akadAddressController.dispose();
    _akadMapsController.dispose();
    _resepsiDateController.dispose();
    _resepsiTimeController.dispose();
    _resepsiVenueController.dispose();
    _resepsiAddressController.dispose();
    _resepsiMapsController.dispose();
    _bankName1Controller.dispose();
    _bankAccount1Controller.dispose();
    _bankHolder1Controller.dispose();
    _bankName2Controller.dispose();
    _bankAccount2Controller.dispose();
    _bankHolder2Controller.dispose();
    _giftAddressController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(Function(String url) onUploaded) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (picked != null) {
        final uploadedUrl = await ApiClient.uploadImage(File(picked.path));
        onUploaded(uploadedUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload gambar: $e')),
        );
      }
    }
  }

  void _generateDefaultSlugAndTitle() {
    if (_groomNicknameController.text.isNotEmpty && _brideNicknameController.text.isNotEmpty) {
      final g = _groomNicknameController.text.trim().toLowerCase().replaceAll(' ', '-');
      final b = _brideNicknameController.text.trim().toLowerCase().replaceAll(' ', '-');
      if (_slugController.text.trim().isEmpty) {
        _slugController.text = '$g-$b';
      }
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = 'The Wedding of ${_groomNicknameController.text.trim()} & ${_brideNicknameController.text.trim()}';
      }
    }
  }

  Future<void> _saveInvitation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    _generateDefaultSlugAndTitle();

    final payload = {
      'title': _titleController.text.trim(),
      'slug': _slugController.text.trim().toLowerCase().replaceAll(' ', '-'),
      'quotes': _quotesController.text.trim(),
      'cover_image': _coverImageUrl,
      'groom_name': _groomNameController.text.trim(),
      'groom_nickname': _groomNicknameController.text.trim(),
      'groom_parents': _groomParentsController.text.trim(),
      'groom_instagram': _groomIgController.text.trim(),
      'groom_photo': _groomPhotoUrl,
      'bride_name': _brideNameController.text.trim(),
      'bride_nickname': _brideNicknameController.text.trim(),
      'bride_parents': _brideParentsController.text.trim(),
      'bride_instagram': _brideIgController.text.trim(),
      'bride_photo': _bridePhotoUrl,
      'akad_date': _akadDateController.text.trim(),
      'akad_time': _akadTimeController.text.trim(),
      'akad_venue': _akadVenueController.text.trim(),
      'akad_address': _akadAddressController.text.trim(),
      'akad_maps_url': _akadMapsController.text.trim(),
      'resepsi_date': _resepsiDateController.text.trim(),
      'resepsi_time': _resepsiTimeController.text.trim(),
      'resepsi_venue': _resepsiVenueController.text.trim(),
      'resepsi_address': _resepsiAddressController.text.trim(),
      'resepsi_maps_url': _resepsiMapsController.text.trim(),
      'bank_name_1': _bankName1Controller.text.trim(),
      'bank_account_1': _bankAccount1Controller.text.trim(),
      'bank_holder_1': _bankHolder1Controller.text.trim(),
      'bank_name_2': _bankName2Controller.text.trim(),
      'bank_account_2': _bankAccount2Controller.text.trim(),
      'bank_holder_2': _bankHolder2Controller.text.trim(),
      'gift_address': _giftAddressController.text.trim(),
      'audio_url': _audioUrlController.text.trim(),
      'is_active': true,
    };

    try {
      final service = ref.read(invitationServiceProvider);
      if (widget.invitation != null) {
        await service.updateInvitation(widget.invitation!.id, payload);
      } else {
        await service.createInvitation(payload);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.invitation != null ? 'Undangan berhasil diperbarui' : 'Undangan berhasil dibuat!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.invitation != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Undangan Digital' : 'Buat Undangan Digital', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionCard(
              title: '1. Judul & Link Khusus (URL Slug)',
              icon: Icons.link,
              children: [
                DekorinTextField(
                  controller: _titleController,
                  label: 'Judul Undangan',
                  hint: 'Contoh: The Wedding of Bagas & Zulia',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _slugController,
                  label: 'Tautan URL Slug (Unik)',
                  hint: 'Contoh: bagas-zulia',
                  helperText: 'Akan menjadi link: domain.com/invitation/slug',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Slug wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _quotesController,
                  label: 'Kutipan Ayat / Doa',
                  hint: 'Kutipan ayat suci...',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '2. Mempelai Pria',
              icon: Icons.male,
              children: [
                DekorinTextField(
                  controller: _groomNameController,
                  label: 'Nama Lengkap Pria',
                  hint: 'Contoh: Bagas Pratama, S.Kom.',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama mempelai pria wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _groomNicknameController,
                  label: 'Nama Panggilan',
                  hint: 'Contoh: Bagas',
                  onChanged: (_) => _generateDefaultSlugAndTitle(),
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _groomParentsController,
                  label: 'Nama Orang Tua Pria',
                  hint: 'Putra pertama dari Bpk. Bambang & Ibu Siti',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _groomIgController,
                  label: 'Akun Instagram Pria',
                  hint: 'Contoh: bagaspratama (tanpa @)',
                  prefixIcon: Icons.camera_alt_outlined,
                ),
                const SizedBox(height: 12),
                _buildPhotoPicker(
                  label: 'Foto Mempelai Pria',
                  imageUrl: _groomPhotoUrl,
                  onPick: () => _pickAndUploadImage((url) => setState(() => _groomPhotoUrl = url)),
                  onClear: () => setState(() => _groomPhotoUrl = ''),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '3. Mempelai Wanita',
              icon: Icons.female,
              children: [
                DekorinTextField(
                  controller: _brideNameController,
                  label: 'Nama Lengkap Wanita',
                  hint: 'Contoh: Zulia Maharani, S.Pd.',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama mempelai wanita wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _brideNicknameController,
                  label: 'Nama Panggilan',
                  hint: 'Contoh: Zulia',
                  onChanged: (_) => _generateDefaultSlugAndTitle(),
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _brideParentsController,
                  label: 'Nama Orang Tua Wanita',
                  hint: 'Putri bungsu dari Bpk. Haryono & Ibu Endang',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _brideIgController,
                  label: 'Akun Instagram Wanita',
                  hint: 'Contoh: zuliamaharani (tanpa @)',
                  prefixIcon: Icons.camera_alt_outlined,
                ),
                const SizedBox(height: 12),
                _buildPhotoPicker(
                  label: 'Foto Mempelai Wanita',
                  imageUrl: _bridePhotoUrl,
                  onPick: () => _pickAndUploadImage((url) => setState(() => _bridePhotoUrl = url)),
                  onClear: () => setState(() => _bridePhotoUrl = ''),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '4. Jadwal & Lokasi Akad Nikah',
              icon: Icons.ring_volume,
              children: [
                DekorinTextField(
                  controller: _akadDateController,
                  label: 'Tanggal Akad',
                  hint: 'Contoh: Sabtu, 10 Januari 2026',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _akadTimeController,
                  label: 'Waktu / Jam Akad',
                  hint: 'Contoh: 08:00 - 10:00 WIB',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _akadVenueController,
                  label: 'Tempat / Gedung Akad',
                  hint: 'Contoh: Masjid Agung Al-Barakah',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _akadAddressController,
                  label: 'Alamat Lengkap',
                  hint: 'Jl. Raya Tajur No. 59, Bogor',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _akadMapsController,
                  label: 'Link Google Maps Akad',
                  hint: 'https://maps.app.goo.gl/...',
                  prefixIcon: Icons.map_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '5. Jadwal & Lokasi Resepsi',
              icon: Icons.celebration,
              children: [
                DekorinTextField(
                  controller: _resepsiDateController,
                  label: 'Tanggal Resepsi',
                  hint: 'Contoh: Sabtu, 10 Januari 2026',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _resepsiTimeController,
                  label: 'Waktu / Jam Resepsi',
                  hint: 'Contoh: 11:00 - 14:00 WIB',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _resepsiVenueController,
                  label: 'Tempat / Gedung Resepsi',
                  hint: 'Contoh: Gedung Serbaguna Galaxy',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _resepsiAddressController,
                  label: 'Alamat Lengkap',
                  hint: 'Jl. Raya Tajur No. 59, Bogor',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _resepsiMapsController,
                  label: 'Link Google Maps Resepsi',
                  hint: 'https://maps.app.goo.gl/...',
                  prefixIcon: Icons.map_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '6. Amplop Digital & Rekening',
              icon: Icons.account_balance,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DekorinTextField(
                        controller: _bankName1Controller,
                        label: 'Bank 1',
                        hint: 'BCA',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DekorinTextField(
                        controller: _bankAccount1Controller,
                        label: 'Nomor Rekening 1',
                        hint: '1234567890',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DekorinTextField(
                  controller: _bankHolder1Controller,
                  label: 'Atas Nama Rekening 1',
                  hint: 'Contoh: Bagas Pratama',
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DekorinTextField(
                        controller: _bankName2Controller,
                        label: 'Bank 2 (Opsional)',
                        hint: 'Mandiri / BRI',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DekorinTextField(
                        controller: _bankAccount2Controller,
                        label: 'Nomor Rekening 2',
                        hint: '0987654321',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DekorinTextField(
                  controller: _bankHolder2Controller,
                  label: 'Atas Nama Rekening 2',
                  hint: 'Contoh: Zulia Maharani',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _giftAddressController,
                  label: 'Alamat Kirim Kado Fisik (Opsional)',
                  hint: 'Alamat rumah mempelai...',
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '7. Media & Musik Latar',
              icon: Icons.photo_library,
              children: [
                _buildPhotoPicker(
                  label: 'Foto Cover Utama Undangan',
                  imageUrl: _coverImageUrl,
                  onPick: () => _pickAndUploadImage((url) => setState(() => _coverImageUrl = url)),
                  onClear: () => setState(() => _coverImageUrl = ''),
                ),
                const SizedBox(height: 14),
                DekorinTextField(
                  controller: _audioUrlController,
                  label: 'Link Musik Latar (.mp3)',
                  hint: 'Kosongkan untuk musik romantis bawaan',
                  prefixIcon: Icons.music_note,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubmitting ? null : _saveInvitation,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEdit ? 'Simpan Perubahan Undangan' : 'Terbitkan Undangan Digital',
                        style: AppTypography.button,
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(color: AppColors.primaryGold),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.dividerColor),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPhotoPicker({
    required String label,
    required String imageUrl,
    required VoidCallback onPick,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.labelLarge),
            if (imageUrl.isNotEmpty && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red.shade400, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Hapus Foto',
                        style: AppTypography.caption.copyWith(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.goldLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5), width: 1.2),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl.startsWith('http')
                              ? imageUrl
                              : '${ApiEndpoint.webFormBaseUrl}$imageUrl',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, color: AppColors.primaryGold),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Ganti Foto', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ),
                        if (onClear != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: onClear,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryGold, size: 28),
                      const SizedBox(width: 10),
                      Text('Pilih Foto dari Galeri', style: AppTypography.labelMedium.copyWith(color: AppColors.primaryGold)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
