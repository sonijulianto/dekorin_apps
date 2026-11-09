import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/services/invitation_service.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/core/widgets/portrait_crop_dialog.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_template_picker_view.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_template_preview_view.dart';

class LoveStoryItem {
  final TextEditingController dateController;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  LoveStoryItem({
    String date = '',
    String title = '',
    String description = '',
  })  : dateController = TextEditingController(text: date),
        titleController = TextEditingController(text: title),
        descriptionController = TextEditingController(text: description);

  void dispose() {
    dateController.dispose();
    titleController.dispose();
    descriptionController.dispose();
  }

  Map<String, String> toMap() => {
        'date': dateController.text.trim(),
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
      };
}

class InvitationFormView extends ConsumerStatefulWidget {
  const InvitationFormView({super.key, this.invitation});

  final InvitationItem? invitation;

  @override
  ConsumerState<InvitationFormView> createState() => _InvitationFormViewState();
}

class _InvitationFormViewState extends ConsumerState<InvitationFormView> {
  final _formKey = GlobalKey<FormState>();

  String _selectedTemplate = InvitationTemplate.ta17;
  String _selectedEventType = 'wedding';

  bool get _isSakuraBlossom => _selectedTemplate == InvitationTemplate.ta3;
  bool get _isOceanBlossom => _selectedTemplate == InvitationTemplate.ta17;
  bool get _isIllustrationTemplate => _isSakuraBlossom || _isOceanBlossom;
  bool get _isMonochrome => _selectedTemplate == InvitationTemplate.pn4;
  bool get _isJawa3 => _selectedTemplate == InvitationTemplate.jawa3;

  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _quotesController;

  // Data Mempelai Pria
  late TextEditingController _groomNameController;
  late TextEditingController _groomNicknameController;
  late TextEditingController _groomChildOrderController;
  late TextEditingController _groomParentsController;
  late TextEditingController _groomIgController;

  // Data Mempelai Wanita
  late TextEditingController _brideNameController;
  late TextEditingController _brideNicknameController;
  late TextEditingController _brideChildOrderController;
  late TextEditingController _brideParentsController;
  late TextEditingController _brideIgController;

  // Data Khitanan
  late TextEditingController _childNameController;
  late TextEditingController _childNicknameController;
  late TextEditingController _childOrderController;

  // Jadwal & Lokasi
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

  // Rekening & Kado
  late TextEditingController _bankName1Controller;
  late TextEditingController _bankAccount1Controller;
  late TextEditingController _bankHolder1Controller;

  late TextEditingController _bankName2Controller;
  late TextEditingController _bankAccount2Controller;
  late TextEditingController _bankHolder2Controller;

  late TextEditingController _giftAddressController;
  late TextEditingController _waConfirmationController;

  // Media & Cerita
  late TextEditingController _audioUrlController;
  late TextEditingController _youtubeUrlController;
  final List<LoveStoryItem> _loveStoryItems = [];
  late TextEditingController _turutMengundangController;

  String _coverImageUrl = '';
  String _groomPhotoUrl = '';
  String _bridePhotoUrl = '';
  String _sec1PhotoUrl = '';
  String _akadPhotoUrl = '';
  String _resepsiPhotoUrl = '';
  String _eventPhotoUrl = '';
  String _closingPhotoUrl = '';
  List<String> _galleryUrls = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final inv = widget.invitation;
    final isNew = inv == null;
    final randSuffix = (DateTime.now().millisecondsSinceEpoch % 9000 + 1000).toString();

    _selectedTemplate = (inv?.template.isNotEmpty == true &&
            (inv!.template == InvitationTemplate.ta17 ||
                inv.template == InvitationTemplate.ta3 ||
                inv.template == InvitationTemplate.pn4 ||
                inv.template == InvitationTemplate.jawa3))
        ? inv.template
        : InvitationTemplate.ta17;
    _selectedEventType = inv?.eventType.isNotEmpty == true ? inv!.eventType : 'wedding';

    _titleController = TextEditingController(text: inv?.title ?? 'The Wedding of Bagas & Zulia');
    _slugController = TextEditingController(text: inv?.slug ?? 'bagas-zulia-$randSuffix');
    _quotesController = TextEditingController(
      text:
          inv?.quotes ??
          '"Dan di antara tanda-tanda kekuasaan-Nya ialah Dia menciptakan untukmu isteri-isteri dari jenismu sendiri, supaya kamu cenderung dan merasa tenteram kepadanya, dan dijadikan-Nya di antaramu rasa kasih dan sayang." (QS. Ar-Rum: 21)',
    );

    _groomNameController = TextEditingController(text: inv?.groomName ?? 'Bagas Pratama, S.Kom.');
    _groomNicknameController = TextEditingController(text: inv?.groomNickname ?? 'Bagas');
    _groomChildOrderController = TextEditingController(
      text: inv?.groomChildOrder.isNotEmpty == true ? inv!.groomChildOrder : 'Putra pertama dari',
    );
    _groomParentsController = TextEditingController(text: inv?.groomParents ?? 'Bpk. Bambang & Ibu Siti');
    _groomIgController = TextEditingController(text: inv?.groomInstagram ?? 'bagaspratama');

    _brideNameController = TextEditingController(text: inv?.brideName ?? 'Zulia Maharani, S.Pd.');
    _brideNicknameController = TextEditingController(text: inv?.brideNickname ?? 'Zulia');
    _brideChildOrderController = TextEditingController(
      text: inv?.brideChildOrder.isNotEmpty == true ? inv!.brideChildOrder : 'Putri kedua dari',
    );
    _brideParentsController = TextEditingController(text: inv?.brideParents ?? 'Bpk. Agus & Ibu Dewi');
    _brideIgController = TextEditingController(text: inv?.brideInstagram ?? 'zuliamhr');

    _childNameController = TextEditingController(text: inv?.childName ?? 'Rayyan Althaf Pratama');
    _childNicknameController = TextEditingController(text: inv?.childNickname ?? 'Rayyan');
    _childOrderController = TextEditingController(
      text: inv?.childOrder.isNotEmpty == true ? inv!.childOrder : 'Putra pertama dari',
    );

    _akadDateController = TextEditingController(text: inv?.akadDate ?? 'Sabtu, 20 Desember 2026');
    _akadTimeController = TextEditingController(text: inv?.akadTime ?? '08:00 - 10:00 WIB');
    _akadVenueController = TextEditingController(text: inv?.akadVenue ?? 'Masjid Agung Al-Barkah');
    _akadAddressController = TextEditingController(text: inv?.akadAddress ?? 'Jl. Veteran No. 46, RT.004/RW.001, Marga Jaya, Bekasi Selatan');
    _akadMapsController = TextEditingController(text: inv?.akadMapsUrl ?? 'https://maps.app.goo.gl/9bN52xXn');

    _resepsiDateController = TextEditingController(text: inv?.resepsiDate ?? 'Sabtu, 20 Desember 2026');
    _resepsiTimeController = TextEditingController(text: inv?.resepsiTime ?? '11:00 - 14:00 WIB');
    _resepsiVenueController = TextEditingController(text: inv?.resepsiVenue ?? 'Grand Ballroom Hotel Santika');
    _resepsiAddressController = TextEditingController(text: inv?.resepsiAddress ?? 'Jl. Jend. Ahmad Yani No. 1, RT.001/RW.005, Margajaya, Bekasi Selatan');
    _resepsiMapsController = TextEditingController(text: inv?.resepsiMapsUrl ?? 'https://maps.app.goo.gl/9bN52xXn');

    _bankName1Controller = TextEditingController(text: inv?.bankName1 ?? 'BCA');
    _bankAccount1Controller = TextEditingController(text: inv?.bankAccount1 ?? '1234567890');
    _bankHolder1Controller = TextEditingController(text: inv?.bankHolder1 ?? 'Bagas Pratama');

    _bankName2Controller = TextEditingController(text: inv?.bankName2 ?? 'Bank Mandiri');
    _bankAccount2Controller = TextEditingController(text: inv?.bankAccount2 ?? '9876543210');
    _bankHolder2Controller = TextEditingController(text: inv?.bankHolder2 ?? 'Zulia Maharani');

    _giftAddressController = TextEditingController(text: inv?.giftAddress ?? 'Jl. Melati No. 12, RT.002/RW.005, Margajaya, Bekasi Selatan (Penerima: Bagas & Zulia)');
    _waConfirmationController = TextEditingController(text: inv?.waConfirmation ?? '081234567890');

    _audioUrlController = TextEditingController(text: inv?.audioUrl ?? '');
    _youtubeUrlController = TextEditingController(text: inv?.youtubeUrl ?? '');
    if (inv != null) {
      _initLoveStoryItems(inv.loveStory);
    } else {
      _loveStoryItems.addAll([
        LoveStoryItem(
          date: '1 September 2021',
          title: 'Pertama Kali Bertemu',
          description: 'Kami pertama kali bertemu di sebuah seminar kampus dan saling bertukar kontak.',
        ),
        LoveStoryItem(
          date: '14 Februari 2023',
          title: 'Komitmen Bersama',
          description: 'Setelah melewati berbagai suka dan duka bersama, kami memutuskan untuk berkomitmen melangkah ke jenjang yang lebih serius.',
        ),
        LoveStoryItem(
          date: '20 Oktober 2025',
          title: 'Lamaran',
          description: 'Dengan restu dari kedua keluarga besar, kami melangsungkan prosesi lamaran dan menyatukan tekad untuk menikah.',
        ),
      ]);
    }
    _turutMengundangController = TextEditingController(text: inv?.turutMengundang ?? 'Keluarga Besar Bpk. Bambang & Ibu Siti\nKeluarga Besar Bpk. Agus & Ibu Dewi');

    final rawCover = inv?.coverImage ?? (isNew ? (_isIllustrationTemplate ? '' : (_isJawa3 ? '/assets/templates/jawa3/bg-cover.jpg' : '/assets/templates/pn4/photos/LeniArdi2.jpeg')) : '');
    _coverImageUrl = _isJawa3
        ? '/assets/templates/jawa3/bg-cover.jpg'
        : ((rawCover == '/assets/owlink/b9c1e420-cd8d-11f0-9fb2-69fd61d4e768.jpg')
            ? (_isIllustrationTemplate ? '' : rawCover)
            : rawCover);
    _groomPhotoUrl = inv?.groomPhoto ?? (isNew ? '/assets/templates/pn4/photos/LeniArdi15.jpeg' : '');
    _bridePhotoUrl = inv?.bridePhoto ?? (isNew ? '/assets/templates/pn4/photos/LeniArdi16.jpeg' : '');
    _sec1PhotoUrl = inv?.sec1Photo ?? (isNew ? '/assets/templates/pn4/photos/LeniArdi15.jpeg' : '');
    _akadPhotoUrl = inv?.akadPhoto ?? (isNew ? '/assets/templates/pn4/photos/LeniArdi15.jpeg' : '');
    _resepsiPhotoUrl = inv?.resepsiPhoto ?? (isNew ? '/assets/templates/pn4/photos/LeniArdi16.jpeg' : '');
    _eventPhotoUrl = inv?.eventPhoto ?? (isNew ? '/assets/templates/pn4/photos/LeniArdi16.jpeg' : '');
    _closingPhotoUrl = inv?.closingPhoto ?? (isNew ? '/assets/templates/pn4/photos/LeniArdi2.jpeg' : '');
    if (inv != null && inv.galleryImages.isNotEmpty) {
      _galleryUrls = inv.galleryImages.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else if (isNew) {
      _galleryUrls = [
        '/assets/templates/pn4/photos/LeniArdi2.jpeg',
        '/assets/templates/pn4/photos/LeniArdi15.jpeg',
        '/assets/templates/pn4/photos/LeniArdi16.jpeg',
      ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _quotesController.dispose();
    _groomNameController.dispose();
    _groomNicknameController.dispose();
    _groomChildOrderController.dispose();
    _groomParentsController.dispose();
    _groomIgController.dispose();
    _brideNameController.dispose();
    _brideNicknameController.dispose();
    _brideChildOrderController.dispose();
    _brideParentsController.dispose();
    _brideIgController.dispose();
    _childNameController.dispose();
    _childNicknameController.dispose();
    _childOrderController.dispose();
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
    _waConfirmationController.dispose();
    _audioUrlController.dispose();
    _youtubeUrlController.dispose();
    for (final item in _loveStoryItems) {
      item.dispose();
    }
    _turutMengundangController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(
    Function(String url) onUploaded, {
    bool enableCrop = false,
    double aspectRatio = 3 / 4,
    String cropTitle = 'Sesuaikan Foto (Potrait)',
    String cropSubtitle = 'Geser foto ke kiri/kanan atau perbesar agar pas di bingkai potrait',
  }) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked != null) {
        File fileToUpload = File(picked.path);

        if (enableCrop && mounted) {
          final croppedFile = await PortraitCropDialog.show(
            context,
            imageFile: fileToUpload,
            aspectRatio: aspectRatio,
            title: cropTitle,
            subtitle: cropSubtitle,
          );
          if (croppedFile == null) {
            // User membatalkan dialog crop
            return;
          }
          fileToUpload = croppedFile;
        }

        final uploadedUrl = await ApiClient.uploadImage(fileToUpload);
        onUploaded(uploadedUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload gambar: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
          ),
        );
      }
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final picker = ImagePicker();
      final pickedList = await picker.pickMultiImage(imageQuality: 75, maxWidth: 1080, maxHeight: 1080);
      if (pickedList.isNotEmpty) {
        setState(() => _isSubmitting = true);
        for (final picked in pickedList) {
          final uploadedUrl = await ApiClient.uploadImage(File(picked.path));
          setState(() {
            _galleryUrls.add(uploadedUrl);
          });
        }
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal upload gambar galeri: $e',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _generateDefaultSlugAndTitle() {
    if (_selectedEventType == 'khitan') {
      final name = _childNicknameController.text.trim().isNotEmpty
          ? _childNicknameController.text.trim()
          : _childNameController.text.trim();
      if (name.isNotEmpty) {
        final s = name.toLowerCase().replaceAll(' ', '-');
        if (_slugController.text.trim().isEmpty) {
          _slugController.text = 'khitan-$s';
        }
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = 'Tasyakuran Khitanan $name';
        }
      }
    } else {
      if (_groomNicknameController.text.isNotEmpty && _brideNicknameController.text.isNotEmpty) {
        final g = _groomNicknameController.text.trim().toLowerCase().replaceAll(' ', '-');
        final b = _brideNicknameController.text.trim().toLowerCase().replaceAll(' ', '-');
        if (_slugController.text.trim().isEmpty) {
          _slugController.text = '$b-$g';
        }
        if (_titleController.text.trim().isEmpty) {
          _titleController.text =
              'The Wedding of ${_brideNicknameController.text.trim()} & ${_groomNicknameController.text.trim()}';
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }

  Future<void> _saveInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isMonochrome) {
      if (_selectedEventType == 'khitan') {
        if (_groomPhotoUrl.isEmpty) {
          _showErrorSnackBar('Foto Anak Khitan wajib diunggah untuk tema Monochrome (*Mandatory)');
          return;
        }
      } else {
        if (_bridePhotoUrl.isEmpty) {
          _showErrorSnackBar('Foto Mempelai Wanita wajib diunggah untuk tema Monochrome (*Mandatory)');
          return;
        }
        if (_groomPhotoUrl.isEmpty) {
          _showErrorSnackBar('Foto Mempelai Pria wajib diunggah untuk tema Monochrome (*Mandatory)');
          return;
        }
      }
      if (_coverImageUrl.isEmpty) {
        _showErrorSnackBar('Foto Cover Utama wajib diunggah untuk tema Monochrome (*Mandatory)');
        return;
      }
      if (_sec1PhotoUrl.isEmpty) {
        _showErrorSnackBar('Foto Hero Pembuka / Section 1 wajib diunggah untuk tema Monochrome (*Mandatory)');
        return;
      }
      if (_eventPhotoUrl.isEmpty) {
        _showErrorSnackBar('Foto Countdown Acara wajib diunggah untuk tema Monochrome (*Mandatory)');
        return;
      }
      if (_closingPhotoUrl.isEmpty) {
        _showErrorSnackBar('Foto Penutup / Terima Kasih wajib diunggah untuk tema Monochrome (*Mandatory)');
        return;
      }
      if (_galleryUrls.isEmpty) {
        _showErrorSnackBar('Minimal unggah 1 foto galeri momen untuk tema Monochrome (*Mandatory)');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    _generateDefaultSlugAndTitle();

    final payload = {
      'title': _titleController.text.trim(),
      'slug': _slugController.text.trim().toLowerCase().replaceAll(' ', '-'),
      'template': _selectedTemplate,
      'event_type': _selectedEventType,
      'quotes': _quotesController.text.trim(),
      'cover_image': _isJawa3
          ? '/assets/templates/jawa3/bg-cover.jpg'
          : (_isIllustrationTemplate && _coverImageUrl == '/assets/owlink/b9c1e420-cd8d-11f0-9fb2-69fd61d4e768.jpg')
              ? ''
              : _coverImageUrl,
      'groom_name': (_selectedEventType == 'khitan' || _selectedEventType == 'birthday' || _selectedEventType == 'aqiqah')
          ? (_childNameController.text.trim().isNotEmpty
                ? _childNameController.text.trim()
                : _groomNameController.text.trim())
          : _groomNameController.text.trim(),
      'groom_nickname': (_selectedEventType == 'khitan' || _selectedEventType == 'birthday' || _selectedEventType == 'aqiqah')
          ? (_childNicknameController.text.trim().isNotEmpty
                ? _childNicknameController.text.trim()
                : _groomNicknameController.text.trim())
          : _groomNicknameController.text.trim(),
      'groom_child_order': _groomChildOrderController.text.trim(),
      'groom_parents': _groomParentsController.text.trim(),
      'groom_instagram': _groomIgController.text.trim(),
      'groom_photo': _isIllustrationTemplate ? '' : _groomPhotoUrl,
      'bride_name': _brideNameController.text.trim(),
      'bride_nickname': _brideNicknameController.text.trim(),
      'bride_child_order': _brideChildOrderController.text.trim(),
      'bride_parents': _brideParentsController.text.trim(),
      'bride_instagram': _brideIgController.text.trim(),
      'bride_photo': _isIllustrationTemplate ? '' : _bridePhotoUrl,
      'child_name': _childNameController.text.trim(),
      'child_nickname': _childNicknameController.text.trim(),
      'child_order': _childOrderController.text.trim(),
      'akad_date': _akadDateController.text.trim(),
      'akad_time': _akadTimeController.text.trim(),
      'akad_venue': _akadVenueController.text.trim(),
      'akad_address': _akadAddressController.text.trim(),
      'akad_maps_url': _akadMapsController.text.trim(),
      'akad_photo': _isIllustrationTemplate ? '' : _akadPhotoUrl,
      'resepsi_date': _resepsiDateController.text.trim(),
      'resepsi_time': _resepsiTimeController.text.trim(),
      'resepsi_venue': _resepsiVenueController.text.trim(),
      'resepsi_address': _resepsiAddressController.text.trim(),
      'resepsi_maps_url': _resepsiMapsController.text.trim(),
      'resepsi_photo': _isIllustrationTemplate ? '' : _resepsiPhotoUrl,
      'sec1_photo': _isIllustrationTemplate ? '' : _sec1PhotoUrl,
      'event_photo': _isIllustrationTemplate ? '' : _eventPhotoUrl,
      'closing_photo': _isIllustrationTemplate ? '' : _closingPhotoUrl,
      'bank_name_1': _bankName1Controller.text.trim(),
      'bank_account_1': _bankAccount1Controller.text.trim(),
      'bank_holder_1': _bankHolder1Controller.text.trim(),
      'bank_name_2': _bankName2Controller.text.trim(),
      'bank_account_2': _bankAccount2Controller.text.trim(),
      'bank_holder_2': _bankHolder2Controller.text.trim(),
      'gift_address': _giftAddressController.text.trim(),
      'wa_confirmation': _waConfirmationController.text.trim(),
      'audio_url': _audioUrlController.text.trim(),
      'youtube_url': _youtubeUrlController.text.trim(),
      'love_story': _serializeLoveStory(),
      'turut_mengundang': _turutMengundangController.text.trim(),
      'gallery_images': _galleryUrls.join(','),
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
            content: Text(
              widget.invitation != null ? 'Undangan berhasil diperbarui' : 'Undangan berhasil dibuat!',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.invitation != null;
    final isSinglePerson = _selectedEventType == 'khitan' ||
        _selectedEventType == 'birthday' ||
        _selectedEventType == 'aqiqah';

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
            // 1. PILIH ACARA (DROPDOWN SEARCHABLE)
            _buildSectionCard(
              title: '1. Kategori Acara',
              icon: Icons.celebration_outlined,
              children: [
                Text(
                  'Pilih jenis / kategori perayaan untuk undangan digital Anda:',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 12),
                _buildEventCategoryDropdown(),
              ],
            ),
            const SizedBox(height: 16),

            // 2. PILIH TEMA / TEMPLATE (REDIRECT KE HALAMAN BARU BISA SEARCH)
            _buildSectionCard(
              title: '2. Pilihan Desain & Tema',
              icon: Icons.palette_outlined,
              children: [
                Text(
                  'Pilih tema visual yang sesuai dengan nuansa acara Anda:',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 12),
                _buildTemplateSelectorCard(),
              ],
            ),
            const SizedBox(height: 16),

            // 3. MASUKKAN DATA ACARA & INFORMASI URL
            _buildSectionCard(
              title: '3. Informasi Acara & URL Link',
              icon: Icons.link,
              children: [
                DekorinTextField(
                  controller: _titleController,
                  label: 'Judul Undangan',
                  hint: _getTitleHint(),
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _slugController,
                  label: 'Tautan URL Slug (Unik)',
                  hint: _getSlugHint(),
                  helperText: 'Akan menjadi tautan: undangan.dekorin.my.id/slug',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Slug wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _quotesController,
                  label: 'Kutipan Ayat / Doa Acara',
                  hint: 'Kutipan ayat suci atau kata mutiara...',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. TOKOH / MEMPELAI
            if (isSinglePerson) ...[
              _buildSectionCard(
                title: _selectedEventType == 'khitan'
                    ? '4. Data Anak yang Dikhitan'
                    : (_selectedEventType == 'birthday'
                        ? '4. Data yang Berulang Tahun'
                        : '4. Data Putra / Putri'),
                icon: Icons.child_care,
                children: [
                  DekorinTextField(
                    controller: _childNameController,
                    label: _selectedEventType == 'birthday' ? 'Nama Lengkap' : 'Nama Lengkap Anak',
                    hint: _selectedEventType == 'birthday' ? 'Contoh: Kenzo Althaf Pratama' : 'Contoh: Rayyan Althaf Pratama',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  DekorinTextField(
                    controller: _childNicknameController,
                    label: 'Nama Panggilan',
                    hint: _selectedEventType == 'birthday' ? 'Contoh: Kenzo' : 'Contoh: Rayyan',
                    onChanged: (_) => _generateDefaultSlugAndTitle(),
                  ),
                  const SizedBox(height: 12),
                  DekorinTextField(
                    controller: _childOrderController,
                    label: _selectedEventType == 'birthday' ? 'Perayaan Ulang Tahun Ke-' : 'Urutan Anak',
                    hint: _selectedEventType == 'birthday' ? 'Contoh: Ke-5 Tahun' : 'Putra pertama dari',
                  ),
                  const SizedBox(height: 12),
                  DekorinTextField(
                    controller: _groomParentsController,
                    label: 'Nama Orang Tua (Ayah & Ibu)',
                    hint: 'Bapak Ahmad & Ibu Siti',
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoPicker(
                    label: _isMonochrome ? 'Foto Profil (Potrait 3:4) *' : 'Foto Profil',
                    imageUrl: _groomPhotoUrl,
                    onPick: () => _pickAndUploadImage(
                      (url) => setState(() => _groomPhotoUrl = url),
                      enableCrop: true,
                      cropTitle: 'Atur Foto Profil (Potrait)',
                      cropSubtitle: 'Geser foto ke kiri / kanan agar pas dan tidak terpotong',
                    ),
                    onClear: () => setState(() => _groomPhotoUrl = ''),
                  ),
                ],
              ),
            ] else ...[
              _buildSectionCard(
                title: '4. Mempelai Wanita',
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
                    controller: _brideChildOrderController,
                    label: 'Urutan Anak Wanita',
                    hint: 'Putri kedua dari',
                  ),
                  const SizedBox(height: 12),
                  DekorinTextField(
                    controller: _brideParentsController,
                    label: 'Nama Orang Tua Wanita (Ayah & Ibu)',
                    hint: 'Bpk. Agus & Ibu Dewi',
                  ),
                  const SizedBox(height: 12),
                  DekorinTextField(
                    controller: _brideIgController,
                    label: 'Akun Instagram Wanita (Opsional)',
                    hint: 'Contoh: zuliamhr (tanpa @)',
                    prefixIcon: Icons.camera_alt_outlined,
                  ),
                  if (!_isIllustrationTemplate) ...[
                    const SizedBox(height: 12),
                    _buildPhotoPicker(
                      label: _isMonochrome ? 'Foto Mempelai Wanita (Potrait 3:4) *' : 'Foto Mempelai Wanita',
                      imageUrl: _bridePhotoUrl,
                      onPick: () => _pickAndUploadImage(
                        (url) => setState(() => _bridePhotoUrl = url),
                        enableCrop: true,
                        cropTitle: 'Atur Foto Mempelai Wanita (Potrait)',
                        cropSubtitle: 'Geser foto ke kiri / kanan agar wajah pas dan tidak terpotong',
                      ),
                      onClear: () => setState(() => _bridePhotoUrl = ''),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: '5. Mempelai Pria',
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
                    controller: _groomChildOrderController,
                    label: 'Urutan Anak Pria',
                    hint: 'Putra pertama dari',
                  ),
                  const SizedBox(height: 12),
                  DekorinTextField(
                    controller: _groomParentsController,
                    label: 'Nama Orang Tua Pria (Ayah & Ibu)',
                    hint: 'Bpk. Bambang & Ibu Siti',
                  ),
                  const SizedBox(height: 12),
                  DekorinTextField(
                    controller: _groomIgController,
                    label: 'Akun Instagram Pria (Opsional)',
                    hint: 'Contoh: bagaspratama (tanpa @)',
                    prefixIcon: Icons.camera_alt_outlined,
                  ),
                  if (!_isIllustrationTemplate) ...[
                    const SizedBox(height: 12),
                    _buildPhotoPicker(
                      label: _isMonochrome ? 'Foto Mempelai Pria (Potrait 3:4) *' : 'Foto Mempelai Pria',
                      imageUrl: _groomPhotoUrl,
                      onPick: () => _pickAndUploadImage(
                        (url) => setState(() => _groomPhotoUrl = url),
                        enableCrop: true,
                        cropTitle: 'Atur Foto Mempelai Pria (Potrait)',
                        cropSubtitle: 'Geser foto ke kiri / kanan agar wajah pas dan tidak terpotong',
                      ),
                      onClear: () => setState(() => _groomPhotoUrl = ''),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 16),

            // JADWAL ACARA INTI / AKAD NIKAH
            _buildSectionCard(
              title: isSinglePerson
                  ? (_selectedEventType == 'khitan'
                      ? '5. Acara Khitanan'
                      : (_selectedEventType == 'birthday' ? '5. Jadwal Pesta Ulang Tahun' : '5. Jadwal Acara Inti'))
                  : '6. Jadwal & Lokasi Akad Nikah',
              icon: Icons.favorite_border,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DekorinTextField(
                        controller: _akadDateController,
                        label: 'Hari & Tanggal',
                        hint: 'Sabtu, 20 Des 2026',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DekorinTextField(controller: _akadTimeController, label: 'Waktu / Jam', hint: '08:00 WIB'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _akadVenueController,
                  label: 'Tempat / Gedung',
                  hint: 'Masjid Agung Al-Barkah / Kediaman',
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _akadAddressController,
                  label: 'Alamat Lengkap',
                  hint: 'Jl. Veteran No. 12, Bogor Tengah',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _akadMapsController,
                  label: 'Link Google Maps',
                  hint: 'https://maps.app.goo.gl/...',
                  prefixWidget: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset('assets/icons/google-maps-icon.webp', width: 20, height: 20),
                  ),
                ),
                if (!_isIllustrationTemplate) ...[
                  const SizedBox(height: 14),
                  _buildPhotoPicker(
                    label: 'Foto Banner Akad Nikah (akad.jpeg)',
                    imageUrl: _akadPhotoUrl,
                    onPick: () => _pickAndUploadImage((url) => setState(() => _akadPhotoUrl = url)),
                    onClear: () => setState(() => _akadPhotoUrl = ''),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // JADWAL RESEPSI / TASYAKURAN
            _buildSectionCard(
              title: isSinglePerson
                  ? (_selectedEventType == 'khitan'
                      ? '6. Acara Tasyakuran & Ramah Tamah'
                      : '6. Jadwal Resepsi / Ramah Tamah')
                  : '7. Jadwal & Lokasi Resepsi',
              icon: Icons.celebration_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DekorinTextField(
                        controller: _resepsiDateController,
                        label: 'Hari & Tanggal Resepsi',
                        hint: 'Sabtu, 20 Des 2026',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DekorinTextField(
                        controller: _resepsiTimeController,
                        label: 'Waktu / Jam',
                        hint: '11:00 - 14:00 WIB',
                      ),
                    ),
                  ],
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
                  prefixWidget: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset('assets/icons/google-maps-icon.webp', width: 20, height: 20),
                  ),
                ),
                if (!_isIllustrationTemplate) ...[
                  const SizedBox(height: 14),
                  _buildPhotoPicker(
                    label: 'Foto Banner Resepsi (reception.jpeg)',
                    imageUrl: _resepsiPhotoUrl,
                    onPick: () => _pickAndUploadImage((url) => setState(() => _resepsiPhotoUrl = url)),
                    onClear: () => setState(() => _resepsiPhotoUrl = ''),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // FOTO KHUSUS TEMPLATE & MEDIA
            _buildSectionCard(
              title: isSinglePerson
                  ? (_isIllustrationTemplate
                      ? '7. Galeri Momen & Media Pendukung'
                      : '7. Foto Desain Template & Galeri Momen')
                  : (_isIllustrationTemplate
                      ? '8. Galeri Momen & Media Pendukung'
                      : '8. Foto Desain Template & Galeri Momen'),
              icon: Icons.photo_library_outlined,
              children: [
                if (_isIllustrationTemplate) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isOceanBlossom ? const Color(0xFFF0F6FC) : const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _isOceanBlossom ? const Color(0xFFB9D8F2) : const Color(0xFFFFABB8)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome, color: _isOceanBlossom ? const Color(0xFF4B8DCB) : const Color(0xFFD47A88), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isOceanBlossom
                                ? 'Tema Ocean Blossom memiliki ilustrasi karakter bawaan (couple-hero.png). Anda dapat mengunggah Foto Cover Utama di bawah ini jika ingin mengganti ilustrasi tersebut dengan foto Anda sendiri (opsional). Jika dikosongkan, ilustrasi bawaan tetap digunakan.'
                                : 'Tema Sakura Blossom memiliki ilustrasi karakter bawaan (couple-hero.png). Anda dapat mengunggah Foto Cover Utama di bawah ini jika ingin mengganti ilustrasi tersebut dengan foto Anda sendiri (opsional). Jika dikosongkan, ilustrasi bawaan tetap digunakan.',
                            style: AppTypography.caption.copyWith(
                              color: _isOceanBlossom ? const Color(0xFF295177) : const Color(0xFF7D4E55),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPhotoPicker(
                    label: 'Foto Cover Utama / Hero (Opsional - Gantikan couple-hero.png)',
                    imageUrl: _coverImageUrl,
                    onPick: () => _pickAndUploadImage(
                      (url) => setState(() => _coverImageUrl = url),
                      enableCrop: true,
                      cropTitle: _isOceanBlossom ? 'Atur Foto Cover Ocean Blossom' : 'Atur Foto Cover Sakura',
                      cropSubtitle: 'Geser atau perbesar foto agar pas di bingkai bulat cover',
                      aspectRatio: 1.0,
                    ),
                    onClear: () => setState(() => _coverImageUrl = ''),
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),
                ] else ...[
                  if (_isMonochrome) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.primaryGold, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tema Monochrome (Minimalist) mewajibkan seluruh foto terisi lengkap (*Mandatory) agar opening cover, sticky pane, kartu mempelai, countdown/streaming, polaroid, dan album galeri tampil rapi tanpa ada foto yang kosong.',
                              style: AppTypography.caption.copyWith(color: Colors.white, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_isJawa3) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F2323).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC59563).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFC59563), width: 1.2),
                              color: const Color(0xFF4F2323),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              '${ApiEndpoint.webFormBaseUrl}/assets/templates/jawa3/bg-cover.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.lock_outline, color: AppColors.primaryGold, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/lock.svg',
                                      width: 14,
                                      height: 14,
                                      colorFilter: const ColorFilter.mode(Color(0xFF8B4513), BlendMode.srcIn),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Foto Cover Utama (Terkunci Otomatis)',
                                      style: AppTypography.titleSmall.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF4F2323),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cover tema Art Jawa Coklat 3 menggunakan latar belakang gunungan wayang eksklusif bawaan dan tidak dapat diganti.',
                                  style: AppTypography.caption.copyWith(
                                    color: const Color(0xFF5C4033),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    _buildPhotoPicker(
                      label: _isMonochrome ? 'Foto Cover Utama / Sampul (opening.jpeg) *' : 'Foto Cover Utama / Sampul (opening.jpeg)',
                      imageUrl: _coverImageUrl,
                      onPick: () => _pickAndUploadImage(
                        (url) => setState(() => _coverImageUrl = url),
                        enableCrop: _isMonochrome,
                        cropTitle: 'Atur Foto Cover Utama',
                        cropSubtitle: 'Geser atau perbesar foto agar pas di bingkai pembuka',
                        aspectRatio: 9 / 16,
                      ),
                      onClear: () => setState(() => _coverImageUrl = ''),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildPhotoPicker(
                    label: _isMonochrome ? 'Foto Hero Pembuka / Section 1 (sec1.jpeg) *' : 'Foto Hero Pembuka / Section 1 (sec1.jpeg)',
                    imageUrl: _sec1PhotoUrl,
                    onPick: () => _pickAndUploadImage(
                      (url) => setState(() => _sec1PhotoUrl = url),
                      enableCrop: _isMonochrome,
                      cropTitle: 'Atur Foto Section 1 (Sticky & Polaroid)',
                      cropSubtitle: 'Geser foto agar pas di panel samping & polaroid',
                      aspectRatio: 3 / 4,
                    ),
                    onClear: () => setState(() => _sec1PhotoUrl = ''),
                  ),
                  const SizedBox(height: 14),
                  _buildPhotoPicker(
                    label: _isMonochrome ? 'Foto Countdown Acara & Streaming (event.jpeg) *' : 'Foto Countdown Acara (event.jpeg)',
                    imageUrl: _eventPhotoUrl,
                    onPick: () => _pickAndUploadImage((url) => setState(() => _eventPhotoUrl = url)),
                    onClear: () => setState(() => _eventPhotoUrl = ''),
                  ),
                  const SizedBox(height: 14),
                  _buildPhotoPicker(
                    label: _isMonochrome ? 'Foto Penutup / Wishes / Polaroid (closing.jpeg) *' : 'Foto Penutup / Terima Kasih (closing.jpeg)',
                    imageUrl: _closingPhotoUrl,
                    onPick: () => _pickAndUploadImage(
                      (url) => setState(() => _closingPhotoUrl = url),
                      enableCrop: _isMonochrome,
                      cropTitle: 'Atur Foto Penutup (Wishes & Polaroid)',
                      cropSubtitle: 'Geser foto agar pas di kartu ucapan & polaroid',
                      aspectRatio: 3 / 4,
                    ),
                    onClear: () => setState(() => _closingPhotoUrl = ''),
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),
                ],
                _buildGallerySection(),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 10),
                DekorinTextField(
                  controller: _youtubeUrlController,
                  label: 'Link Video YouTube (Opsional)',
                  hint: 'Contoh: https://youtu.be/abcd1234efg',
                  prefixIcon: Icons.play_circle_outline,
                  helperText: 'Akan disematkan langsung sebagai video prewedding di web',
                ),
                const SizedBox(height: 12),
                if (_selectedEventType == 'wedding') ...[
                  _buildLoveStorySection(),
                  const SizedBox(height: 14),
                ],
                DekorinTextField(
                  controller: _turutMengundangController,
                  label: 'Daftar Turut Mengundang (Opsional)',
                  hint: 'Pisahkan nama keluarga dengan baris baru (Enter)...',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _audioUrlController,
                  label: 'Tautan Musik Latar (.mp3)',
                  hint: 'Kosongkan untuk musik romantis bawaan',
                  prefixIcon: Icons.music_note,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // REKENING & HADIAH
            _buildSectionCard(
              title: isSinglePerson
                  ? '8. Amplop Digital & Tanda Kasih'
                  : '9. Amplop Digital & Tanda Kasih',
              icon: Icons.account_balance,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DekorinTextField(controller: _bankName1Controller, label: 'Bank 1', hint: 'BCA'),
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
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: _waConfirmationController,
                  label: 'No. WhatsApp Konfirmasi Kado (Opsional)',
                  hint: '08123456789 (untuk konfirmasi kirim kado)',
                  keyboardType: TextInputType.phone,
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

  String _getTitleHint() {
    switch (_selectedEventType) {
      case 'khitan':
        return 'Contoh: Tasyakuran Khitanan Rayyan Althaf';
      case 'birthday':
        return 'Contoh: The 5th Birthday Party of Kenzo';
      case 'aqiqah':
        return 'Contoh: Tasyakuran Aqiqah Muhammad Bilal';
      case 'engagement':
        return 'Contoh: The Engagement of Bagas & Zulia';
      default:
        return 'Contoh: The Wedding of Zulia & Bagas';
    }
  }

  String _getSlugHint() {
    switch (_selectedEventType) {
      case 'khitan':
        return 'khitan-rayyan';
      case 'birthday':
        return 'birthday-kenzo';
      case 'aqiqah':
        return 'aqiqah-bilal';
      case 'engagement':
        return 'engagement-bagas-zulia';
      default:
        return 'zulia-bagas';
    }
  }

  Widget _buildEventCategoryDropdown() {
    final currentCat = InvitationEventCategory.getById(_selectedEventType);
    return InkWell(
      onTap: _openEventCategoryPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                currentCat['icon'] as String? ?? '🎉',
                style: AppTypography.titleMedium.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentCat['name'] as String? ?? 'Pilih Acara',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentCat['description'] as String? ?? '',
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pilih',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: AppColors.primaryGold, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEventCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCategories = InvitationEventCategory.getAvailableCategories().where((cat) {
              final query = searchQuery.toLowerCase().trim();
              if (query.isEmpty) return true;
              final name = (cat['name'] as String? ?? '').toLowerCase();
              final desc = (cat['description'] as String? ?? '').toLowerCase();
              final short = (cat['shortName'] as String? ?? '').toLowerCase();
              return name.contains(query) || desc.contains(query) || short.contains(query);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle Bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pilih Kategori Acara', style: AppTypography.titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                  'Sesuaikan form data & tema dengan jenis perayaan Anda',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setModalState(() {
                              searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            icon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
                            hintText: 'Cari kategori acara (cth: Pernikahan, Khitan)...',
                            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    Expanded(
                      child: filteredCategories.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Kategori acara tidak ditemukan',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredCategories.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final cat = filteredCategories[index];
                                final isSelected = cat['id'] == _selectedEventType;

                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _onEventTypeSelected(cat['id'] as String);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.goldLight.withValues(alpha: 0.5) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryGold : AppColors.borderLight,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primaryGold.withValues(alpha: 0.15) : AppColors.backgroundLight,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            cat['icon'] as String? ?? '🎉',
                                            style: AppTypography.titleMedium.copyWith(fontSize: 22),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      cat['name'] as String? ?? '',
                                                      style: AppTypography.titleSmall.copyWith(
                                                        color: isSelected ? AppColors.primaryGold : AppColors.textDark,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primaryGold,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        'Aktif',
                                                        style: AppTypography.caption.copyWith(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                cat['description'] as String? ?? '',
                                                style: AppTypography.caption,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                                          color: isSelected ? AppColors.primaryGold : Colors.grey.shade400,
                                          size: isSelected ? 22 : 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _onEventTypeSelected(String newType) {
    setState(() {
      _selectedEventType = newType;
      final isNew = widget.invitation == null;
      if (isNew) {
        if (newType == 'khitan') {
          if (_titleController.text.isEmpty ||
              _titleController.text.startsWith('The Wedding') ||
              _titleController.text.startsWith('The Engagement')) {
            _titleController.text =
                'Tasyakuran Khitanan ${_childNicknameController.text.isNotEmpty ? _childNicknameController.text : "Rayyan"}';
          }
          if (_slugController.text.isEmpty || _slugController.text.startsWith('bagas-zulia')) {
            _slugController.text = 'khitan-rayyan-${DateTime.now().millisecondsSinceEpoch % 10000}';
          }
          if (_quotesController.text.isEmpty || _quotesController.text.contains('Ar-Rum')) {
            _quotesController.text =
                '“Semoga menjadi anak yang sholeh, berbakti kepada kedua orang tua, serta berguna bagi nusa, bangsa, dan agama. Aamiin ya Rabbal \'Alamin.”';
          }
        } else if (newType == 'birthday') {
          if (_titleController.text.isEmpty ||
              _titleController.text.startsWith('The Wedding') ||
              _titleController.text.startsWith('Tasyakuran')) {
            _titleController.text =
                'The Birthday Party of ${_childNicknameController.text.isNotEmpty ? _childNicknameController.text : "Kenzo"}';
          }
          if (_slugController.text.isEmpty ||
              _slugController.text.startsWith('bagas-zulia') ||
              _slugController.text.startsWith('khitan')) {
            _slugController.text = 'birthday-kenzo-${DateTime.now().millisecondsSinceEpoch % 10000}';
          }
          if (_quotesController.text.isEmpty ||
              _quotesController.text.contains('Ar-Rum') ||
              _quotesController.text.contains('anak yang sholeh')) {
            _quotesController.text =
                '“Bertambah satu tahun lagi usia penuh berkah, tawa, dan kebahagiaan bersama keluarga dan sahabat tercinta.”';
          }
        } else if (newType == 'aqiqah') {
          if (_titleController.text.isEmpty || _titleController.text.startsWith('The Wedding')) {
            _titleController.text =
                'Tasyakuran Aqiqah ${_childNicknameController.text.isNotEmpty ? _childNicknameController.text : "Bilal"}';
          }
          if (_slugController.text.isEmpty || _slugController.text.startsWith('bagas-zulia')) {
            _slugController.text = 'aqiqah-bilal-${DateTime.now().millisecondsSinceEpoch % 10000}';
          }
          if (_quotesController.text.isEmpty || _quotesController.text.contains('Ar-Rum')) {
            _quotesController.text =
                '“Semoga Allah memberkahi anak ini bagimu dan menjadikannya anak yang berbakti serta bertakwa.”';
          }
        } else {
          if (_titleController.text.isEmpty ||
              _titleController.text.startsWith('Tasyakuran') ||
              _titleController.text.startsWith('The Birthday')) {
            _titleController.text =
                'The Wedding of ${_brideNicknameController.text.isNotEmpty ? _brideNicknameController.text : "Zulia"} & ${_groomNicknameController.text.isNotEmpty ? _groomNicknameController.text : "Bagas"}';
          }
          if (_slugController.text.isEmpty ||
              _slugController.text.startsWith('khitan') ||
              _slugController.text.startsWith('birthday') ||
              _slugController.text.startsWith('aqiqah')) {
            _slugController.text = 'bagas-zulia-${DateTime.now().millisecondsSinceEpoch % 10000}';
          }
          if (_quotesController.text.isEmpty ||
              _quotesController.text.contains('anak yang sholeh') ||
              _quotesController.text.contains('penuh berkah')) {
            _quotesController.text =
                '"Dan di antara tanda-tanda kekuasaan-Nya ialah Dia menciptakan untukmu isteri-isteri dari jenismu sendiri, supaya kamu cenderung dan merasa tenteram kepadanya, dan dijadikan-Nya di antaramu rasa kasih dan sayang." (QS. Ar-Rum: 21)';
          }
        }
      }
      _generateDefaultSlugAndTitle();
    });
  }

  void _openCurrentTemplatePreview() {
    final tmpl = InvitationTemplate.getById(_selectedTemplate);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvitationTemplatePreviewView(
          templateId: _selectedTemplate,
          templateName: tmpl['name'] as String? ?? 'Preview Template',
          slug: _slugController.text.trim().isNotEmpty
              ? _slugController.text.trim()
              : widget.invitation?.slug,
        ),
      ),
    );
  }

  Future<void> _navigateToTemplatePicker() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => InvitationTemplatePickerView(
          initialTemplateId: _selectedTemplate,
          categoryFilter: _selectedEventType,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedTemplate = result;
        if (_isJawa3) {
          _coverImageUrl = '/assets/templates/jawa3/bg-cover.jpg';
        }
        _generateDefaultSlugAndTitle();
      });
    }
  }

  Widget _buildTemplateSelectorCard() {
    final tmpl = InvitationTemplate.getById(_selectedTemplate);
    final primaryColor = tmpl['primaryColor'] as Color? ?? AppColors.primaryGold;
    final secondaryColor = tmpl['secondaryColor'] as Color? ?? AppColors.secondaryGold;
    final bgColor = tmpl['backgroundColor'] as Color? ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.goldLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4), width: 1.2),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Visual Swatch Preview
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 10,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          tmpl['name'] as String? ?? '',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tmpl['tag'] as String? ?? '',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tmpl['description'] as String? ?? '',
                      style: AppTypography.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _openCurrentTemplatePreview,
                    icon: const Icon(Icons.visibility_outlined, size: 17, color: AppColors.primaryGold),
                    label: Text(
                      'Preview',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGold, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToTemplatePicker,
                    icon: const Icon(Icons.explore_outlined, size: 17, color: Colors.white),
                    label: Text(
                      'Ganti Template',
                      style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
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
                child: Text(title, style: AppTypography.titleSmall.copyWith(color: AppColors.primaryGold)),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.dividerColor),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _isMonochrome
                    ? 'Galeri Momen (Wajib min 1 foto) *'
                    : _isIllustrationTemplate ? 'Galeri Foto (Bisa tambah foto dinamis)' : 'Galeri Foto (gallery1 - gallery9)',
                style: AppTypography.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _pickGalleryImages,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text('Tambah Foto', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGold,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_galleryUrls.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.goldLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Icon(Icons.photo_library_outlined, color: AppColors.primaryGold, size: 30),
                const SizedBox(height: 6),
                Text(
                  'Belum ada foto galeri ditambahkan.\nKlik "Tambah Foto" untuk memilih multiple foto.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: _galleryUrls.length,
            itemBuilder: (context, index) {
              final url = _galleryUrls[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url.startsWith('http') ? url : '${ApiEndpoint.webFormBaseUrl}$url',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _galleryUrls.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  void _initLoveStoryItems(String rawStory) {
    _loveStoryItems.clear();
    final trimmed = rawStory.trim();
    if (trimmed.isEmpty) return;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            _loveStoryItems.add(
              LoveStoryItem(
                date: (item['date'] ?? item['tanggal'] ?? '').toString(),
                title: (item['title'] ?? item['judul'] ?? '').toString(),
                description: (item['description'] ?? item['deskripsi'] ?? item['body'] ?? item['story'] ?? '').toString(),
              ),
            );
          }
        }
        if (_loveStoryItems.isNotEmpty) return;
      }
    } catch (_) {
      // Fallback: parse legacy plain text
    }

    final parts = trimmed.split(RegExp(r'\n\s*---\s*\n|\n\s*={3,}\s*\n'));
    for (final part in parts) {
      final pTrimmed = part.trim();
      if (pTrimmed.isEmpty) continue;
      final lines = pTrimmed.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.length >= 3) {
        _loveStoryItems.add(
          LoveStoryItem(
            date: lines[0],
            title: lines[1],
            description: lines.sublist(2).join('\n'),
          ),
        );
      } else if (lines.length == 2) {
        _loveStoryItems.add(
          LoveStoryItem(
            date: lines[0],
            title: lines[1],
            description: '',
          ),
        );
      } else if (lines.length == 1) {
        if (lines[0].contains('|')) {
          final segs = lines[0].split('|').map((s) => s.trim()).toList();
          _loveStoryItems.add(
            LoveStoryItem(
              date: segs.isNotEmpty ? segs[0] : '',
              title: segs.length > 1 ? segs[1] : '',
              description: segs.length > 2 ? segs.sublist(2).join(' | ') : '',
            ),
          );
        } else {
          _loveStoryItems.add(
            LoveStoryItem(
              date: '',
              title: '',
              description: lines[0],
            ),
          );
        }
      }
    }
  }

  String _serializeLoveStory() {
    final validItems = _loveStoryItems
        .where((item) =>
            item.dateController.text.trim().isNotEmpty ||
            item.titleController.text.trim().isNotEmpty ||
            item.descriptionController.text.trim().isNotEmpty)
        .map((item) => item.toMap())
        .toList();

    if (validItems.isEmpty) return '';
    return jsonEncode(validItems);
  }

  Widget _buildLoveStorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Kisah Cinta / Perjalanan Momen (Opsional)',
                style: AppTypography.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _loveStoryItems.add(LoveStoryItem());
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text('Tambah Momen', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGold,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Bagikan kisah romantis pertemuan, lamaran, hingga menuju pelaminan.',
          style: AppTypography.caption.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(height: 10),
        if (_loveStoryItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.goldLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Icon(Icons.favorite_border, color: AppColors.primaryGold, size: 28),
                const SizedBox(height: 6),
                Text(
                  'Belum ada momen kisah cinta ditambahkan.\nKlik "Tambah Momen" untuk menambahkan kisah perjalanan cinta Anda.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loveStoryItems.add(LoveStoryItem());
                    });
                  },
                  icon: const Icon(Icons.add, size: 18, color: AppColors.primaryGold),
                  label: Text('Tambah Momen Pertama', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryGold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ..._loveStoryItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.goldLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite, size: 14, color: AppColors.primaryGold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Momen #${index + 1}',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Hapus Momen',
                        onPressed: () {
                          setState(() {
                            final removed = _loveStoryItems.removeAt(index);
                            removed.dispose();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DekorinTextField(
                    controller: item.dateController,
                    label: 'Tanggal / Waktu Momen',
                    hint: 'Contoh: 1 September 2025',
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 10),
                  DekorinTextField(
                    controller: item.titleController,
                    label: 'Judul Momen',
                    hint: 'Contoh: The Beginning / Pertemuan Pertama',
                    prefixIcon: Icons.bookmark_border,
                  ),
                  const SizedBox(height: 10),
                  DekorinTextField(
                    controller: item.descriptionController,
                    label: 'Deskripsi / Cerita',
                    hint: 'Ceritakan kisah dan kesan menarik pada momen ini...',
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _loveStoryItems.add(LoveStoryItem());
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primaryGold),
            label: Text('Tambah Momen Kisah Cinta', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: AppColors.primaryGold, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ],
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
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
                        style: AppTypography.caption.copyWith(color: Colors.red.shade400, fontWeight: FontWeight.w600),
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
                          imageUrl.startsWith('http') ? imageUrl : '${ApiEndpoint.webFormBaseUrl}$imageUrl',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image, color: AppColors.primaryGold)),
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
                            child: Text(
                              'Ganti Foto',
                              style: AppTypography.caption.copyWith(color: Colors.white, fontSize: 11),
                            ),
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
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
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
                      Text(
                        'Pilih Foto dari Galeri',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.primaryGold),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
