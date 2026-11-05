import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/models/ai_decor_simulation_model.dart';
import 'package:dekorin_apps/data/services/ai_decor_service.dart';
import 'package:dekorin_apps/ui/features/ai_studio/utils/ai_simulation_pdf_helper.dart';
import 'package:dekorin_apps/ui/features/ai_studio/widgets/before_after_slider.dart';
import 'package:dekorin_apps/ui/features/ai_studio/widgets/catalog_photo_picker_sheet.dart';
import 'package:dekorin_apps/ui/features/ai_studio/widgets/simulation_history_sheet.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class _PalettePreset {
  const _PalettePreset(this.label, this.swatch);
  final String label;
  final Color swatch;
}

class AiDecorStudioView extends ConsumerStatefulWidget {
  const AiDecorStudioView({super.key});

  @override
  ConsumerState<AiDecorStudioView> createState() => _AiDecorStudioViewState();
}

class _AiDecorStudioViewState extends ConsumerState<AiDecorStudioView> {
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _fabricController = TextEditingController();
  final TextEditingController _flowerController = TextEditingController();
  final TextEditingController _nuanceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  File? _selectedImageFile;
  String _selectedCatalogUrl = '';
  String _selectedModelName = '';

  AiDecorSimulationModel? _result;
  bool _isGenerating = false;
  bool _isSharingPdf = false;
  int _previewMode = 0; // 0: Split Geser, 1: Hasil AI, 2: Foto Asli

  static const List<_PalettePreset> _fabricPresets = [
    _PalettePreset('Sage Green', Color(0xFF8FA98F)),
    _PalettePreset('Broken White', Color(0xFFF6F2EA)),
    _PalettePreset('Terracotta', Color(0xFFC66B49)),
    _PalettePreset('Dusty Rose', Color(0xFFDCAE96)),
    _PalettePreset('Champagne Gold', Color(0xFFDFC59B)),
    _PalettePreset('Burgundy Maroon', Color(0xFF722F37)),
    _PalettePreset('Navy Blue', Color(0xFF1F305E)),
    _PalettePreset('Baby Blue', Color(0xFFA2C4E0)),
    _PalettePreset('Lilac Pastel', Color(0xFFC8B4D8)),
  ];

  static const List<String> _flowerPresets = [
    'Mawar Putih, Peach & Daun Eucalyptus',
    'Full White Orchid & Mawar Putih',
    'Blush Pink, Magenta & Baby Breath',
    'Rustic Terracotta, Cream & Daun Kering',
    'Biru Pastel, Putih & Hydrangea',
    'Merah Maroon, Gold & Mawar Merah',
  ];

  static const List<String> _nuancePresets = [
    'Elegant Modern',
    'Romantic Garden',
    'Rustic Warm',
    'Luxury Klasik',
    'Intimate Minimalist',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _fabricController.dispose();
    _flowerController.dispose();
    _nuanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFromDevice(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 88,
      );
      if (picked == null) return;
      setState(() {
        _selectedImageFile = File(picked.path);
        _selectedCatalogUrl = '';
        _selectedModelName = '';
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal mengambil foto: $e', isError: true);
    }
  }

  Future<void> _pickFromCatalog() async {
    final chosen = await showModalBottomSheet<SelectedCatalogPhoto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CatalogPhotoPickerSheet(),
    );
    if (chosen == null) return;
    setState(() {
      _selectedImageFile = null;
      _selectedCatalogUrl = chosen.imageUrl;
      _selectedModelName = chosen.name;
    });
  }

  Future<void> _openHistorySheet() async {
    final chosen = await showModalBottomSheet<AiDecorSimulationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SimulationHistorySheet(),
    );
    if (chosen == null) return;
    setState(() {
      _selectedImageFile = null;
      _selectedCatalogUrl = chosen.originalUrl;
      _selectedModelName = chosen.modelName;
      _fabricController.text = chosen.fabricColor;
      _flowerController.text = chosen.flowerColor;
      _nuanceController.text = chosen.nuance;
      _notesController.text = chosen.notes;
      _result = chosen;
      _previewMode = 0;
    });
    _scrollToResult();
  }

  void _toggleCommaValue(TextEditingController controller, String item) {
    final current = controller.text.trim();
    if (current.isEmpty) {
      setState(() => controller.text = item);
      return;
    }
    final parts = current
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final idx = parts.indexWhere((e) => e.toLowerCase() == item.toLowerCase());
    if (idx >= 0) {
      parts.removeAt(idx);
    } else {
      parts.add(item);
    }
    setState(() => controller.text = parts.join(', '));
  }

  bool _isPresetActive(TextEditingController controller, String item) {
    final parts = controller.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty);
    return parts.contains(item.toLowerCase());
  }

  Future<void> _runSimulation() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedImageFile == null && _selectedCatalogUrl.trim().isEmpty) {
      _showSnack('Pilih foto dekorasi referensi terlebih dahulu (Katalog / Galeri / Kamera).', isError: true);
      return;
    }

    final fabric = _fabricController.text.trim();
    final flower = _flowerController.text.trim();
    final nuance = _nuanceController.text.trim();
    final notes = _notesController.text.trim();

    if (fabric.isEmpty && flower.isEmpty && nuance.isEmpty && notes.isEmpty) {
      _showSnack('Isi minimal warna kain, warna bunga, atau catatan request klien.', isError: true);
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final sim = await ref.read(aiDecorServiceProvider).simulateDecor(
            imageFile: _selectedImageFile,
            imageUrl: _selectedCatalogUrl,
            modelName: _selectedModelName,
            fabricColor: fabric,
            flowerColor: flower,
            nuance: nuance,
            notes: notes,
          );

      await ref.read(aiDecorHistoryProvider.notifier).addSimulation(sim);

      if (!mounted) return;
      setState(() {
        _result = sim;
        _previewMode = 0;
        _isGenerating = false;
      });
      _showSnack('Simulasi warna dekorasi berhasil dibuat!');
      _scrollToResult();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      _showErrorDialog(e.toString());
    }
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.errorRed, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Simulasi Belum Berhasil', style: AppTypography.titleMedium),
            ),
          ],
        ),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              minimumSize: const Size(90, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Mengerti', style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  Future<void> _shareProposalPdf() async {
    final sim = _result;
    if (sim == null || _isSharingPdf) return;

    setState(() => _isSharingPdf = true);
    try {
      final user = ref.read(globalAuthProvider).value;
      final pdfBytes = await AiSimulationPdfHelper.generateProposalPdf(
        sim,
        companyUser: user,
      );
      final safeName = (sim.modelName.isNotEmpty ? sim.modelName : 'Dekorasi')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Simulasi_Warna_${safeName}_Dekorin.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal menyiapkan lembar simulasi: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSharingPdf = false);
      }
    }
  }

  Future<void> _openWhatsAppDialog() async {
    final sim = _result;
    if (sim == null) return;

    final phoneController = TextEditingController();
    final clientNameController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Kirim Simulasi ke WhatsApp Klien', style: AppTypography.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Isi nomor WA calon pengantin (opsional) atau langsung pilih kontak di aplikasi WhatsApp.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: clientNameController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Nama Klien / Pengantin (Opsional)',
                    labelStyle: AppTypography.bodySmall,
                    hintText: 'Contoh: Kak Dinda & Mas Reza',
                    hintStyle: AppTypography.caption,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Nomor WhatsApp (Opsional)',
                    labelStyle: AppTypography.bodySmall,
                    hintText: 'Contoh: 081234567890 (kosongkan untuk pilih kontak)',
                    hintStyle: AppTypography.caption,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final clientName = clientNameController.text.trim();
                      final rawPhone = phoneController.text.trim();
                      Navigator.pop(ctx);
                      await _launchWhatsAppMessage(sim, clientName: clientName, rawPhone: rawPhone);
                    },
                    icon: SvgPicture.asset(
                      'assets/icons/wa.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    label: Text(
                      'Buka WhatsApp Sekarang',
                      style: AppTypography.button,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchWhatsAppMessage(
    AiDecorSimulationModel sim, {
    String clientName = '',
    String rawPhone = '',
  }) async {
    final user = ref.read(globalAuthProvider).value;
    final brand = (user?.companyName.isNotEmpty ?? false) ? user!.companyName : 'Dekorin';
    final greeting = clientName.isNotEmpty ? 'Halo *$clientName*,' : 'Halo Kak,';

    final buffer = StringBuffer()
      ..writeln('$greeting berikut kami kirimkan *Simulasi Visual Kustomisasi Warna Dekorasi* dari *$brand*:')
      ..writeln('');
    if (sim.modelName.isNotEmpty) {
      buffer.writeln('• *Model Referensi:* ${sim.modelName}');
    }
    if (sim.fabricColor.isNotEmpty) {
      buffer.writeln('• *Warna Kain Backdrop:* ${sim.fabricColor}');
    }
    if (sim.flowerColor.isNotEmpty) {
      buffer.writeln('• *Warna & Jenis Bunga:* ${sim.flowerColor}');
    }
    if (sim.nuance.isNotEmpty) {
      buffer.writeln('• *Nuansa:* ${sim.nuance}');
    }
    if (sim.notes.isNotEmpty) {
      buffer.writeln('• *Catatan:* ${sim.notes}');
    }
    buffer
      ..writeln('')
      ..writeln('*Lihat Gambar Hasil Simulasi:*')
      ..writeln(sim.resultUrl)
      ..writeln('')
      ..writeln('_*Catatan: Gambar merupakan pratinjau simulasi AI sebagai referensi perpaduan warna. Hasil fisik menyesuaikan pencahayaan venue & ketersediaan bunga._');

    var cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    final encodedText = Uri.encodeComponent(buffer.toString());
    final waUrl = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$encodedText'
        : 'https://wa.me/?text=$encodedText';

    final uri = Uri.parse(waUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      _showSnack('Tidak dapat membuka aplikasi WhatsApp.', isError: true);
    }
  }

  void _openFullscreenViewer(String imageUrl, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.5,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyCount = ref.watch(aiDecorHistoryProvider).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                'assets/icons/ai-magic.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Simulasi Warna AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _openHistorySheet,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.goldLight,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.primaryGold),
              label: Text(
                historyCount > 0 ? 'Riwayat ($historyCount)' : 'Riwayat',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
        children: [
          // Banner Penjelasan Singkat
          _buildHeroInfoBanner(),
          const SizedBox(height: 16),

          // STEP 1: Pilih Foto Referensi
          _buildStepCard(
            stepNumber: '1',
            title: 'Foto Model Dekorasi Referensi',
            subtitle: 'Pilih dari katalog Dekorin atau unggah foto model yang diinginkan klien',
            child: _buildSourcePhotoSection(),
          ),
          const SizedBox(height: 16),

          // STEP 2: Form Kustomisasi Warna Kain & Bunga
          _buildStepCard(
            stepNumber: '2',
            title: 'Request Warna & Catatan Klien',
            subtitle: 'Pilih palet cepat atau ketik kombinasi warna sesuai permintaan pengantin',
            child: _buildCustomizationForm(),
          ),
          const SizedBox(height: 20),

          // Tombol Generate Utama
          _buildGenerateButton(),

          // STEP 3: Hasil Simulasi Before-After (Muncul bila ada hasil)
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildResultSection(_result!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF563B13),
            Color(0xFF88632E),
            Color(0xFFA57D3E),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4E350E).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SvgPicture.asset(
              'assets/icons/ai-magic.svg',
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visualisasi Request Pengantin Instan',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ubah warna kain tirai & rangkaian bunga pada foto model yang sudah ada tanpa merusak bentuk panggung asli.',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGold,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  stepNumber,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSourcePhotoSection() {
    final hasPhoto = _selectedImageFile != null || _selectedCatalogUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPhoto) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: _selectedImageFile != null
                      ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                      : Image.network(
                          _selectedCatalogUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.goldLight,
                            alignment: Alignment.center,
                            child: Text('Gagal memuat gambar', style: AppTypography.bodySmall),
                          ),
                        ),
                ),
              ),
              if (_selectedModelName.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedModelName,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() {
                        _selectedImageFile = null;
                        _selectedCatalogUrl = '';
                        _selectedModelName = '';
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ] else ...[
          InkWell(
            onTap: _pickFromCatalog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.goldLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.45),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 38, color: AppColors.primaryGold),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada foto referensi dipilih',
                    style: AppTypography.titleSmall.copyWith(color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pilih dari Katalog Dekorin, Galeri HP, atau Kamera di bawah ini',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 3 Tombol Sumber Foto
        Row(
          children: [
            Expanded(
              flex: 5,
              child: OutlinedButton.icon(
                onPressed: _pickFromCatalog,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                  side: const BorderSide(color: AppColors.primaryGold, width: 1.3),
                  backgroundColor: AppColors.goldLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.collections_bookmark_outlined, size: 17, color: AppColors.primaryGold),
                label: Text(
                  'Katalog',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                onPressed: () => _pickFromDevice(ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.photo_library_outlined, size: 17, color: AppColors.textDark),
                label: Text(
                  'Galeri',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(color: AppColors.textDark),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                onPressed: () => _pickFromDevice(ImageSource.camera),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.photo_camera_outlined, size: 17, color: AppColors.textDark),
                label: Text(
                  'Kamera',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(color: AppColors.textDark),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomizationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Warna Kain Backdrop
        Text('Warna Kain / Tirai Backdrop', style: AppTypography.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _fabricPresets.map((preset) {
            final selected = _isPresetActive(_fabricController, preset.label);
            return InkWell(
              onTap: () => _toggleCommaValue(_fabricController, preset.label),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryGold.withValues(alpha: 0.16) : const Color(0xFFF7F5F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primaryGold : AppColors.borderLight,
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: preset.swatch,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26, width: 0.8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      preset.label,
                      style: AppTypography.caption.copyWith(
                        color: selected ? const Color(0xFF6B4628) : AppColors.textDark,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _fabricController,
          style: AppTypography.bodyMedium,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Contoh: Kain tengah Broken White, tirai kiri-kanan Sage Green',
            hintStyle: AppTypography.caption,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 18),

        // 2. Warna & Jenis Bunga
        Text('Warna & Jenis Rangkaian Bunga', style: AppTypography.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _flowerPresets.map((flowerText) {
            final isSelected = _flowerController.text.trim().toLowerCase() == flowerText.toLowerCase();
            return InkWell(
              onTap: () {
                setState(() {
                  _flowerController.text = isSelected ? '' : flowerText;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGold.withValues(alpha: 0.16) : const Color(0xFFF7F5F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGold : AppColors.borderLight,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  flowerText,
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? const Color(0xFF6B4628) : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _flowerController,
          style: AppTypography.bodyMedium,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Contoh: Mawar putih, anggrek cream, peach lembut & daun ruskus',
            hintStyle: AppTypography.caption,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 18),

        // 3. Nuansa Acara (Opsional)
        Text('Nuansa / Konsep (Opsional)', style: AppTypography.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _nuancePresets.map((nuanceText) {
            final isSelected = _nuanceController.text.trim().toLowerCase() == nuanceText.toLowerCase();
            return InkWell(
              onTap: () {
                setState(() {
                  _nuanceController.text = isSelected ? '' : nuanceText;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGold.withValues(alpha: 0.16) : const Color(0xFFF7F5F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGold : AppColors.borderLight,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  nuanceText,
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? const Color(0xFF6B4628) : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nuanceController,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Contoh: Elegant Romantic dengan pencahayaan warm white',
            hintStyle: AppTypography.caption,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 18),

        // 4. Catatan Tambahan Khusus
        Text('Catatan Khusus Tambahan (Opsional)', style: AppTypography.titleSmall),
        const SizedBox(height: 6),
        TextField(
          controller: _notesController,
          style: AppTypography.bodyMedium,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Contoh: Hilangkan semua bunga warna biru, karpet bawah diganti warna krem polos, kursi pelaminan tetap putih.',
            hintStyle: AppTypography.caption,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _runSimulation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              disabledBackgroundColor: AppColors.primaryGold.withValues(alpha: 0.65),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : SvgPicture.asset(
                    'assets/icons/ai-magic.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
            label: Text(
              _isGenerating ? 'AI Sedang Merangkai Warna (~15 dtk)...' : 'Buat Simulasi Warna AI',
              style: AppTypography.button.copyWith(fontSize: 15),
            ),
          ),
        ),
        if (_isGenerating) ...[
          const SizedBox(height: 10),
          Text(
            'Mohon tunggu sebentar, AI sedang menyesuaikan kain & bunga tanpa mengubah tata letak dekorasi...',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: const Color(0xFF8F6431)),
          ),
        ],
      ],
    );
  }

  Widget _buildResultSection(AiDecorSimulationModel sim) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.55), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  'assets/icons/ai-magic.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hasil Simulasi Warna AI', style: AppTypography.titleMedium),
                    Text(
                      'Geser garis tengah atau pilih mode tampilan di bawah',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Toggle Mode Preview
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildModeTab(0, 'Geser Bandingkan'),
                _buildModeTab(1, 'Hasil AI'),
                _buildModeTab(2, 'Foto Asli'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Area Gambar
          if (_previewMode == 0)
            BeforeAfterSlider(
              afterImageUrl: sim.resultUrl,
              beforeImageFile: _selectedImageFile,
              beforeImageUrl: sim.originalUrl,
              height: 370,
              onTapFullscreen: () => _openFullscreenViewer(sim.resultUrl, 'Hasil Simulasi AI'),
            )
          else if (_previewMode == 1)
            GestureDetector(
              onTap: () => _openFullscreenViewer(sim.resultUrl, 'Hasil Simulasi AI'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  sim.resultUrl,
                  height: 370,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: sim.originalUrl.isNotEmpty
                  ? () => _openFullscreenViewer(sim.originalUrl, 'Foto Referensi Asli')
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _selectedImageFile != null
                    ? Image.file(
                        _selectedImageFile!,
                        height: 370,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        sim.originalUrl,
                        height: 370,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),

          const SizedBox(height: 14),

          // Disclaimer Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: AppColors.secondaryGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pratinjau AI: Gunakan lembar simulasi ini untuk menyamakan persepsi warna bersama calon pengantin.',
                    style: AppTypography.caption.copyWith(color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Kirim ke WhatsApp Klien
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openWhatsAppDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                elevation: 0,
              ),
              icon: SvgPicture.asset(
                'assets/icons/wa.svg',
                width: 19,
                height: 19,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              label: Text(
                'Kirim Simulasi via WhatsApp',
                style: AppTypography.button,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Baris Tombol Bagikan Lembar PDF & Salin Link
          Row(
            children: [
              Expanded(
                flex: 6,
                child: OutlinedButton.icon(
                  onPressed: _isSharingPdf ? null : _shareProposalPdf,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    side: const BorderSide(color: AppColors.primaryGold, width: 1.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  icon: _isSharingPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGold),
                        )
                      : SvgPicture.asset(
                          'assets/icons/share.svg',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                        ),
                  label: Text(
                    'Lembar Before-After',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: sim.resultUrl));
                    if (!mounted) return;
                    _showSnack('Link gambar simulasi disalin!');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  icon: SvgPicture.asset(
                    'assets/icons/copy-alt.svg',
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                  ),
                  label: Text(
                    'Salin Link',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(int index, String title) {
    final active = _previewMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _previewMode = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: active ? const Color(0xFF6B4628) : AppColors.textLight,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
