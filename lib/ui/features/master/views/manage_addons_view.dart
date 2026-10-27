import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/domain/models/decoration_addon.dart';
import 'package:flutter/services.dart';
import 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';

class ManageAddonsView extends ConsumerStatefulWidget {
  const ManageAddonsView({super.key});

  @override
  ConsumerState<ManageAddonsView> createState() => _ManageAddonsViewState();
}

class _ManageAddonsViewState extends ConsumerState<ManageAddonsView> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  List<DecorationAddon>? _localAddons;

  void _showAddonFormSheet([DecorationAddon? addon]) {
    final isEdit = addon != null;
    final thousandFormatter = NumberFormat('#,###', 'id_ID');
    final nameController = TextEditingController(text: addon?.name ?? '');
    final priceController = TextEditingController(
      text: addon != null && addon.price > 0 ? thousandFormatter.format(addon.price.toInt()).replaceAll(',', '.') : '',
    );
    final descController = TextEditingController(text: addon?.description ?? '');
    final formKey = GlobalKey<FormState>();

    File? selectedImageFile;
    String existingImageUrl = addon?.imageUrl ?? '';
    bool isSubmitting = false;

    Future<void> pickImage(ImageSource source, StateSetter setModalState) async {
      try {
        final picker = ImagePicker();
        // Kompresi foto secara otomatis saat dipilih dari galeri/kamera
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 70, // Kompres kualitas gambar ke 70%
          maxWidth: 1080, // Resize resolusi maksimal 1080px
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
                                isEdit ? 'Edit Item Tambahan' : 'Tambah Addon Baru',
                                style: AppTypography.titleLarge,
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Label Upload Foto
                      Text('Foto Item Tambahan', style: AppTypography.labelLarge),
                      const SizedBox(height: 8),

                      // Box Preview Foto & Button Upload
                      GestureDetector(
                        onTap: () => pickImage(ImageSource.gallery, setModalState),
                        child: Container(
                          height: 140,
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
                                      child: Icon(Icons.broken_image, size: 40, color: AppColors.textMuted),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.primaryGold),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Pilih Foto dari Galeri / Kamera',
                                        style: AppTypography.titleSmall.copyWith(color: AppColors.primaryGold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Foto otomatis dikompresi sebelum di-upload', style: AppTypography.caption),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Action Pickers
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
                        label: 'Nama Item Tambahan',
                        hint: 'Contoh: Lighting Ambient Tambahan',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama addon wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DekorinTextField(
                        controller: priceController,
                        label: 'Harga Item',
                        hint: 'Contoh: 300.000',
                        prefixText: 'Rp ',
                        prefixStyle: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Harga wajib diisi';
                          final clean = v.replaceAll(RegExp(r'\D'), '');
                          if (double.tryParse(clean) == null || double.parse(clean) <= 0) {
                            return 'Harga harus berupa angka valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DekorinTextField(
                        controller: descController,
                        label: 'Deskripsi / Catatan Item',
                        hint: 'Keterangan tambahan...',
                        maxLines: 2,
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

                                    // Upload gambar terkompresi ke server jika ada foto baru yang dipilih
                                    if (selectedImageFile != null) {
                                      finalImageUrl = await ApiClient.uploadImage(selectedImageFile!);
                                    }

                                    if (isEdit) {
                                      await service.updateAddon(
                                        addon.id,
                                        name: nameController.text.trim(),
                                        price: price,
                                        description: descController.text.trim(),
                                        imageUrl: finalImageUrl,
                                      );
                                    } else {
                                      await service.createAddon(
                                        name: nameController.text.trim(),
                                        price: price,
                                        description: descController.text.trim(),
                                        imageUrl: finalImageUrl,
                                      );
                                    }
                                    ref.invalidate(addonsProvider);
                                    if (context.mounted) Navigator.pop(context);
                                  } catch (e) {
                                    setModalState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gagal menyimpan addon: $e',
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
                              : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Addon', style: AppTypography.button),
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

  void _confirmDelete(DecorationAddon addon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Addon', style: AppTypography.titleMedium),
        content: Text('Apakah Anda yakin ingin menghapus addon "${addon.name}"?', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.labelMedium.copyWith(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(masterServiceProvider).deleteAddon(addon.id);
                ref.invalidate(addonsProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus addon: $e',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text('Hapus', style: AppTypography.labelMedium.copyWith(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<DecorationAddon>>>(addonsProvider, (_, next) {
      next.whenData((data) {
        setState(() {
          _localAddons = List.from(data);
        });
      });
    });

    final addonsAsync = ref.watch(addonsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Kelola Item Tambahan', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddonFormSheet(),
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Addon', style: AppTypography.button.copyWith(fontSize: 14)),
      ),
      body: addonsAsync.when(
        data: (addons) {
          if (addons.isEmpty) {
            return Center(child: Text('Belum ada item tambahan.', style: AppTypography.bodyMedium));
          }

          if (_localAddons == null || _localAddons!.length != addons.length) {
            _localAddons = List.from(addons);
          }
          final displayList = _localAddons!;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(addonsProvider),
            child: ReorderableListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: displayList.length,
              header: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.primaryGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tekan & tahan kartu atau geser ikon untuk ubah urutan',
                          style: AppTypography.caption.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onReorderItem: (int oldIndex, int newIndex) async {
                setState(() {
                  final item = displayList.removeAt(oldIndex);
                  displayList.insert(newIndex, item);
                });

                try {
                  final ids = displayList.map((a) => a.id).toList();
                  await ref.read(masterServiceProvider).reorderAddons(ids);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Urutan addon berhasil disimpan',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                        ),
                        duration: Duration(milliseconds: 1200),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal menyimpan urutan addon: $e',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                        ),
                      ),
                    );
                  }
                  ref.invalidate(addonsProvider);
                }
              },
              itemBuilder: (context, index) {
                final addon = displayList[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(addon.id),
                  index: index,
                  child: Container(
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.drag_indicator_rounded, color: AppColors.textLight, size: 22),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: addon.imageUrl.isNotEmpty
                                ? Image.network(
                                    addon.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.goldLight,
                                      child: const Icon(Icons.auto_awesome, color: AppColors.primaryGold),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: AppColors.goldLight,
                                    child: const Icon(Icons.auto_awesome, color: AppColors.primaryGold),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(addon.name, style: AppTypography.titleSmall),
                                const SizedBox(height: 2),
                                Text(
                                  currencyFormatter.format(addon.price),
                                  style: AppTypography.labelMedium.copyWith(color: AppColors.primaryGold),
                                ),
                                if (addon.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    addon.description,
                                    style: AppTypography.caption,
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
                                _showAddonFormSheet(addon);
                              } else if (value == 'delete') {
                                _confirmDelete(addon);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Edit', style: AppTypography.bodyMedium),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, size: 18, color: AppColors.errorRed),
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
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Gagal memuat addon: $err', style: AppTypography.bodyMedium.copyWith(color: AppColors.errorRed)),
        ),
      ),
    );
  }
}
