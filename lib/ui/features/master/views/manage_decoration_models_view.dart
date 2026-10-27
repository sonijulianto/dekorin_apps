import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';

class ManageDecorationModelsView extends ConsumerStatefulWidget {
  const ManageDecorationModelsView({super.key});

  @override
  ConsumerState<ManageDecorationModelsView> createState() => _ManageDecorationModelsViewState();
}

class _ManageDecorationModelsViewState extends ConsumerState<ManageDecorationModelsView> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  List<DecorationModel>? _localModels;
  String _searchQuery = '';

  void _showModelFormSheet([DecorationModel? model]) {
    final isEdit = model != null;
    final thousandFormatter = NumberFormat('#,###', 'id_ID');
    final nameController = TextEditingController(text: model?.name ?? '');
    final widthController = TextEditingController(text: model?.width ?? '');
    final priceController = TextEditingController(
      text: model != null && model.price > 0 ? thousandFormatter.format(model.price.toInt()).replaceAll(',', '.') : '',
    );
    final descController = TextEditingController(text: model?.description ?? '');
    final formKey = GlobalKey<FormState>();

    File? selectedImageFile;
    String existingImageUrl = model?.imageUrl ?? '';
    bool isSubmitting = false;

    Future<void> pickImage(ImageSource source, StateSetter setModalState) async {
      try {
        final picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 70,
          maxWidth: 1080,
          maxHeight: 1080,
        );

        if (pickedFile != null) {
          setModalState(() {
            selectedImageFile = File(pickedFile.path);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memilih foto: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            ),
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: true,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isEdit ? 'Edit Model Dekorasi' : 'Tambah Model Baru',
                                style: AppTypography.titleLarge,
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Label Upload Foto
                      Text('Foto Model Dekorasi', style: AppTypography.labelLarge),
                      const SizedBox(height: 8),

                      // Box Preview Foto & Button Upload
                      GestureDetector(
                        onTap: () => pickImage(ImageSource.gallery, setModalState),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.goldLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: selectedImageFile != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(selectedImageFile!, fit: BoxFit.cover),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '✓ Terkompresi',
                                            style: AppTypography.caption.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : existingImageUrl.isNotEmpty
                                ? Image.network(
                                    existingImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(Icons.broken_image, size: 40, color: AppColors.textLight),
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primaryGold),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ketuk untuk memilih foto model dekorasi',
                                          style: AppTypography.caption.copyWith(color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tombol pilihan Galeri / Kamera
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickImage(ImageSource.gallery, setModalState),
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: Text(
                                'Galeri',
                                style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryGold,
                                side: const BorderSide(color: AppColors.primaryGold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickImage(ImageSource.camera, setModalState),
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: Text(
                                'Kamera',
                                style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryGold,
                                side: const BorderSide(color: AppColors.primaryGold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      DekorinTextField(
                        controller: nameController,
                        label: 'Nama Model Dekorasi',
                        hint: 'Contoh: Model Rustic Arch Wood / Modern Hexagon',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama model wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      DekorinTextField(
                        controller: widthController,
                        label: 'Lebar Model Dekorasi',
                        hint: 'Contoh: 3 Meter, 4 Meter, atau 6x3m',
                        prefixIcon: Icons.straighten,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Lebar dekorasi wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      DekorinTextField(
                        controller: priceController,
                        label: 'Harga Dasar / Acuan Model',
                        hint: 'Contoh: 2.000.000',
                        prefixText: 'Rp ',
                        prefixStyle: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Harga acuan wajib diisi';
                          final clean = v.replaceAll(RegExp(r'\D'), '');
                          if (double.tryParse(clean) == null || double.parse(clean) < 0) {
                            return 'Harga harus berupa angka valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      DekorinTextField(
                        controller: descController,
                        label: 'Deskripsi / Detail Model',
                        hint: 'Contoh: Rangkaian arch kayu jati belanda, pampas kering, kursi pelaminan...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSubmitting = true);

                                  try {
                                    final service = ref.read(masterServiceProvider);
                                    final cleanPrice = priceController.text.replaceAll(RegExp(r'\D'), '');
                                    final price = double.parse(cleanPrice);
                                    String finalImageUrl = existingImageUrl;

                                    if (selectedImageFile != null) {
                                      finalImageUrl = await ApiClient.uploadImage(selectedImageFile!);
                                    }

                                    if (isEdit) {
                                      await service.updateDecorationModel(
                                        model.id,
                                        name: nameController.text.trim(),
                                        width: widthController.text.trim(),
                                        price: price,
                                        description: descController.text.trim(),
                                        imageUrl: finalImageUrl,
                                      );
                                    } else {
                                      await service.createDecorationModel(
                                        name: nameController.text.trim(),
                                        width: widthController.text.trim(),
                                        price: price,
                                        description: descController.text.trim(),
                                        imageUrl: finalImageUrl,
                                      );
                                    }
                                    ref.invalidate(decorationModelsProvider);
                                    if (context.mounted) Navigator.pop(context);
                                  } catch (e) {
                                    setModalState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gagal menyimpan model dekorasi: $e',
                                            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isEdit ? 'Simpan Perubahan' : 'Tambahkan Model',
                                  style: AppTypography.button.copyWith(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
  }

  void _confirmDelete(DecorationModel model) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Model Dekorasi', style: AppTypography.h3),
        content: Text('Apakah Anda yakin ingin menghapus model "${model.name}"?', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(masterServiceProvider).deleteDecorationModel(model.id);
                ref.invalidate(decorationModelsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Model dekorasi berhasil dihapus',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus model dekorasi: $e',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text('Hapus', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(decorationModelsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Master Model Dekorasi', style: AppTypography.titleMedium),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.dividerColor, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Model', style: AppTypography.button.copyWith(color: Colors.white)),
        onPressed: () => _showModelFormSheet(),
      ),
      body: modelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat model dekorasi:\n$err',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold),
                  onPressed: () => ref.invalidate(decorationModelsProvider),
                  child: Text('Coba Lagi', style: AppTypography.button),
                ),
              ],
            ),
          ),
        ),
        data: (models) {
          if (models.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_carousel_outlined, size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('Belum ada master model dekorasi.', style: AppTypography.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan model dekorasi untuk dipilih dalam paket dan agenda.',
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (_localModels == null || _localModels!.length != models.length) {
            _localModels = List.from(models);
          }
          final displayList = _localModels!;

          final filteredList = _searchQuery.isEmpty
              ? displayList
              : displayList.where((m) {
                  final q = _searchQuery.toLowerCase();
                  return m.name.toLowerCase().contains(q) ||
                      m.width.toLowerCase().contains(q) ||
                      m.description.toLowerCase().contains(q);
                }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(decorationModelsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: AppColors.primaryGold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Model dekorasi ini bisa dipilih dan ditautkan ke Paket Dekorasi dengan penyesuaian biaya tambahan.',
                          style: AppTypography.caption.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search field jika model > 2
                if (models.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari model atau ukuran lebar...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textLight),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                  ),

                // Model Cards
                ...filteredList.map((model) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: model.imageUrl.isNotEmpty
                                ? Image.network(
                                    model.imageUrl,
                                    width: 75,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 75,
                                      height: 75,
                                      color: AppColors.goldLight,
                                      child: const Icon(Icons.view_carousel, color: AppColors.primaryGold),
                                    ),
                                  )
                                : Container(
                                    width: 75,
                                    height: 75,
                                    color: AppColors.goldLight,
                                    child: const Icon(Icons.view_carousel, color: AppColors.primaryGold),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(model.name, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.goldLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.straighten, size: 12, color: AppColors.primaryGold),
                                          const SizedBox(width: 4),
                                          Text(
                                            model.width.isNotEmpty ? model.width : 'Lebar standar',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.primaryGold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      currencyFormatter.format(model.price),
                                      style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (model.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    model.description,
                                    style: AppTypography.caption.copyWith(color: AppColors.textLight),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showModelFormSheet(model);
                              } else if (value == 'delete') {
                                _confirmDelete(model);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 18, color: AppColors.textDark),
                                    const SizedBox(width: 8),
                                    Text('Edit', style: AppTypography.bodyMedium),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline, size: 18, color: AppColors.errorRed),
                                    const SizedBox(width: 8),
                                    Text('Hapus', style: AppTypography.bodyMedium.copyWith(color: AppColors.errorRed)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
