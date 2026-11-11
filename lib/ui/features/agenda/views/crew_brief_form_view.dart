import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/crew_brief.dart';
import 'package:dekorin_apps/ui/features/agenda/views/crew_brief_preview_view.dart';

/// Item form seksi instruksi kerja visual crew.
class _SectionFormItem {
  _SectionFormItem({
    String initialTitle = '',
    this.imageUrl,
    List<String>? initialNotes,
  })  : titleController = TextEditingController(text: initialTitle),
        noteControllers = (initialNotes != null && initialNotes.isNotEmpty)
            ? initialNotes.map((n) => TextEditingController(text: n)).toList()
            : [TextEditingController()];

  final TextEditingController titleController;
  final List<TextEditingController> noteControllers;
  Uint8List? imageBytes;
  String? imageUrl;

  void dispose() {
    titleController.dispose();
    for (final c in noteControllers) {
      c.dispose();
    }
  }

  bool get hasImage =>
      (imageBytes != null && imageBytes!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.trim().isNotEmpty);
}

/// Screen form dinamis untuk menyusun Lembar Kerja Visual Crew Dekorasi format A4.
/// Struktur data: [{gambar, [list catatan]}, {gambar, [list catatan]}, ...]
class CrewBriefFormView extends ConsumerStatefulWidget {
  const CrewBriefFormView({super.key, required this.agenda});

  final AgendaItem agenda;

  @override
  ConsumerState<CrewBriefFormView> createState() => _CrewBriefFormViewState();
}

class _CrewBriefFormViewState extends ConsumerState<CrewBriefFormView> {
  final List<_SectionFormItem> _sections = [];
  final _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Inisialisasi awal: 1 seksi dengan 1 foto & 1 baris catatan
    final item = widget.agenda;
    final initialTitle = item.modelName.isNotEmpty
        ? 'Area Backdrop: ${item.modelName}'
        : 'Area Pelaminan / Backdrop Utama';

    _sections.add(
      _SectionFormItem(
        initialTitle: initialTitle,
        imageUrl: item.modelImageUrl.isNotEmpty ? item.modelImageUrl : null,
      ),
    );
  }

  @override
  void dispose() {
    for (final sec in _sections) {
      sec.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _addSection() {
    setState(() {
      _sections.add(
        _SectionFormItem(
          initialTitle: 'Bagian ${_sections.length + 1}: Area Dekorasi',
        ),
      );
    });

    // Auto-scroll ke bawah agar pengguna langsung melihat seksi baru
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeSection(int index) {
    if (_sections.length <= 1) return;
    setState(() {
      final removed = _sections.removeAt(index);
      removed.dispose();
    });
  }

  void _addNoteToSection(int sectionIndex) {
    setState(() {
      _sections[sectionIndex].noteControllers.add(TextEditingController());
    });
  }

  void _removeNoteFromSection(int sectionIndex, int noteIndex) {
    final section = _sections[sectionIndex];
    if (section.noteControllers.length <= 1) return;
    setState(() {
      final removed = section.noteControllers.removeAt(noteIndex);
      removed.dispose();
    });
  }

  Future<void> _pickImage(int sectionIndex) async {
    final hasEventModelPhoto = widget.agenda.modelImageUrl.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text('Pilih Foto untuk Area Ini', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGold),
                  title: Text('Ambil Foto dari Kamera', style: AppTypography.bodyMedium),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      if (!mounted) return;
                      setState(() {
                        _sections[sectionIndex].imageBytes = bytes;
                        _sections[sectionIndex].imageUrl = null;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryGold),
                  title: Text('Pilih dari Galeri HP', style: AppTypography.bodyMedium),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      if (!mounted) return;
                      setState(() {
                        _sections[sectionIndex].imageBytes = bytes;
                        _sections[sectionIndex].imageUrl = null;
                      });
                    }
                  },
                ),
                if (hasEventModelPhoto)
                  ListTile(
                    leading: const Icon(Icons.view_carousel, color: AppColors.primaryGold),
                    title: Text('Gunakan Foto Model Backdrop Acara', style: AppTypography.bodyMedium),
                    subtitle: Text(widget.agenda.modelName, style: AppTypography.caption),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _sections[sectionIndex].imageUrl = widget.agenda.modelImageUrl;
                        _sections[sectionIndex].imageBytes = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToPreview() {
    // Validasi & konversi data
    final converted = _sections.map((item) {
      final notes = item.noteControllers
          .map((c) => c.text.trim())
          .where((n) => n.isNotEmpty)
          .toList();

      return CrewBriefSection(
        title: item.titleController.text.trim(),
        imageBytes: item.imageBytes,
        imageUrl: item.imageUrl,
        notes: notes.isNotEmpty ? notes : ['Pasang dan sesuaikan dengan foto referensi.'],
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrewBriefPreviewView(
          agenda: widget.agenda,
          sections: converted,
        ),
      ),
    );
  }

  Widget _buildSectionCard(int sectionIndex) {
    final section = _sections[sectionIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Seksi: Nama Area & Tombol Hapus Seksi
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'BAGIAN ${sectionIndex + 1}',
                  style: AppTypography.caption.copyWith(color: AppColors.secondaryGold, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: section.titleController,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    hintText: 'Nama area (contoh: Area Backdrop Pelaminan)',
                    hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_sections.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'Hapus Bagian Ini',
                  onPressed: () => _removeSection(sectionIndex),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Picker Foto Area
          InkWell(
            onTap: () => _pickImage(sectionIndex),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: section.hasImage
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: section.imageBytes != null
                                ? Image.memory(section.imageBytes!, fit: BoxFit.cover)
                                : Image.network(
                                    section.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 40)),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('Ganti Foto', style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.goldLight, shape: BoxShape.circle),
                            child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryGold, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pilih Foto Area / Referensi Setup',
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ketuk untuk ambil dari kamera, galeri, atau katalog',
                            style: AppTypography.caption.copyWith(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Daftar Catatan & Instruksi Setup (Poin-Poin)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Catatan & Instruksi Setup (Checklist):', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _addNoteToSection(sectionIndex),
                icon: const Icon(Icons.add, size: 16, color: AppColors.primaryGold),
                label: Text('Tambah Poin', style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Input Baris Catatan
          ...List.generate(section.noteControllers.length, (noteIdx) {
            final noteController = section.noteControllers[noteIdx];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${noteIdx + 1}',
                      style: AppTypography.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryGold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: noteController,
                      style: AppTypography.bodySmall,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Contoh: Pasang standing flower di kanan 2, kiri 1',
                        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5)),
                      ),
                    ),
                  ),
                  if (section.noteControllers.length > 1) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
                      tooltip: 'Hapus Poin',
                      onPressed: () => _removeNoteFromSection(sectionIndex, noteIdx),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Buat Lembar Kerja Crew A4', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner ringkasan acara
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primaryGold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Klien: ${widget.agenda.clientName}',
                                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                              Text(
                                'Rangkuman visual ini akan di-generate ke lembar A4 siap kirim ke WhatsApp crew.',
                                style: AppTypography.caption.copyWith(color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Daftar Semua Seksi Foto & Catatan
                  ...List.generate(_sections.length, (idx) => _buildSectionCard(idx)),

                  // Tombol Tambah Bagian / Area Foto Baru
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addSection,
                      icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primaryGold, size: 18),
                      label: Text('Tambah Bagian / Foto Lain', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Bar: Preview & Cetak Lembar A4
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _goToPreview,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text('Lihat & Cetak Lembar A4', style: AppTypography.button),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
