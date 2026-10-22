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
import 'package:dekorin_apps/domain/models/decoration_package.dart';
import 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';

class _PackageModelItemEntry {
  final DecorationModel model;
  double additionalPrice;
  final TextEditingController controller;

  _PackageModelItemEntry({
    required this.model,
    required this.additionalPrice,
    required this.controller,
  });
}

class ManagePackagesView extends ConsumerStatefulWidget {
  const ManagePackagesView({super.key});

  @override
  ConsumerState<ManagePackagesView> createState() => _ManagePackagesViewState();
}

class _ManagePackagesViewState extends ConsumerState<ManagePackagesView> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  List<DecorationPackage>? _localPackages;

  Future<void> _showModelSelectorDialog({
    required List<_PackageModelItemEntry> currentSelected,
    required Function(List<_PackageModelItemEntry>) onUpdated,
  }) async {
    final masterModels = await ref.read(masterServiceProvider).getDecorationModels();
    if (!mounted) return;

    if (masterModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada master data model dekorasi. Silakan buat di menu Kelola Model Dekorasi terlebih dahulu.'),
          backgroundColor: AppColors.primaryGold,
        ),
      );
      return;
    }

    final selectedMap = <String, _PackageModelItemEntry>{
      for (final item in currentSelected) item.model.id: item,
    };

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.view_carousel, color: AppColors.primaryGold),
                  const SizedBox(width: 8),
                  Text('Pilih Model Dekorasi', style: AppTypography.titleMedium),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: masterModels.length,
                  separatorBuilder: (_, unused) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final m = masterModels[idx];
                    final isChecked = selectedMap.containsKey(m.id);

                    return CheckboxListTile(
                      value: isChecked,
                      activeColor: AppColors.primaryGold,
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.name, style: AppTypography.titleSmall),
                      subtitle: Text(
                        '${m.width.isNotEmpty ? 'Lebar: ${m.width} • ' : ''}${currencyFormatter.format(m.price)}',
                        style: AppTypography.caption,
                      ),
                      secondary: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: m.imageUrl.isNotEmpty
                            ? Image.network(
                                m.imageUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 44,
                                  height: 44,
                                  color: AppColors.goldLight,
                                  child: const Icon(Icons.view_carousel, color: AppColors.primaryGold, size: 20),
                                ),
                              )
                            : Container(
                                width: 44,
                                height: 44,
                                color: AppColors.goldLight,
                                child: const Icon(Icons.view_carousel, color: AppColors.primaryGold, size: 20),
                              ),
                      ),
                      onChanged: (val) {
                        setDlgState(() {
                          if (val == true) {
                            selectedMap[m.id] = _PackageModelItemEntry(
                              model: m,
                              additionalPrice: 0,
                              controller: TextEditingController(text: '0'),
                            );
                          } else {
                            selectedMap.remove(m.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgContext),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold),
                  onPressed: () {
                    onUpdated(selectedMap.values.toList());
                    Navigator.pop(dlgContext);
                  },
                  child: const Text('Simpan Pilihan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPackageFormSheet([DecorationPackage? package]) async {
    final isEdit = package != null;
    final thousandFormatter = NumberFormat('#,###', 'id_ID');
    final nameController = TextEditingController(text: package?.name ?? '');
    final priceController = TextEditingController(
      text: package != null && package.basePrice > 0
          ? thousandFormatter.format(package.basePrice.toInt()).replaceAll(',', '.')
          : '',
    );
    final descController = TextEditingController(text: package?.description ?? '');
    final formKey = GlobalKey<FormState>();

    // Ambil master models untuk mapping existing package_models jika ada
    final masterModels = await ref.read(masterServiceProvider).getDecorationModels();
    final modelMap = {for (final m in masterModels) m.id: m};

    final List<_PackageModelItemEntry> selectedModels = [];
    if (package != null && package.packageModels.isNotEmpty) {
      for (final pm in package.packageModels) {
        final model = pm.decorationModel ?? modelMap[pm.decorationModelId];
        if (model != null) {
          final addPrice = pm.additionalPrice;
          final txt = addPrice > 0 ? thousandFormatter.format(addPrice.toInt()).replaceAll(',', '.') : '0';
          selectedModels.add(
            _PackageModelItemEntry(
              model: model,
              additionalPrice: addPrice,
              controller: TextEditingController(text: txt),
            ),
          );
        }
      }
    }

    File? selectedImageFile;
    String existingImageUrl = package?.imageUrl ?? '';
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
            SnackBar(content: Text('Gagal memilih foto: $e')),
          );
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
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
                          Text(
                            isEdit ? 'Edit Paket Dekorasi' : 'Tambah Paket Baru',
                            style: AppTypography.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Label Upload Foto
                      Text('Foto Paket Dekorasi', style: AppTypography.labelLarge),
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
                                            style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
                                              'Ketuk untuk memilih foto paket',
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
                              label: const Text('Galeri'),
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
                              label: const Text('Kamera'),
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
                        label: 'Nama Paket',
                        hint: 'Contoh: Paket Lamaran Modern Rustic',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama paket wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DekorinTextField(
                        controller: priceController,
                        label: 'Harga Dasar',
                        hint: 'Contoh: 4.000.000',
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ThousandsSeparatorInputFormatter(),
                        ],
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
                        label: 'Deskripsi / Kelengkapan Paket',
                        hint: 'Rincian item kelengkapan...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // ── Bagian Model Dekorasi dalam Paket ──────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Model Dekorasi Paket', style: AppTypography.labelLarge),
                              const SizedBox(height: 2),
                              Text(
                                'Pilihan model & biaya tambahan (surcharge)',
                                style: AppTypography.caption.copyWith(color: AppColors.textLight),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryGold,
                              backgroundColor: AppColors.goldLight.withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Pilih Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              _showModelSelectorDialog(
                                currentSelected: selectedModels,
                                onUpdated: (newSelected) {
                                  setModalState(() {
                                    selectedModels.clear();
                                    selectedModels.addAll(newSelected);
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (selectedModels.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.grey.shade400),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Belum ada model khusus yang dipilih. Client dapat memilih model dekorasi bebas tanpa surcharge.',
                                  style: AppTypography.caption.copyWith(color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: selectedModels.length,
                          itemBuilder: (ctx, idx) {
                            final item = selectedModels[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: item.model.imageUrl.isNotEmpty
                                            ? Image.network(
                                                item.model.imageUrl,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) => Container(
                                                  width: 40,
                                                  height: 40,
                                                  color: AppColors.goldLight,
                                                  child: const Icon(Icons.view_carousel, color: AppColors.primaryGold, size: 20),
                                                ),
                                              )
                                            : Container(
                                                width: 40,
                                                height: 40,
                                                color: AppColors.goldLight,
                                                child: const Icon(Icons.view_carousel, color: AppColors.primaryGold, size: 20),
                                              ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.model.name, style: AppTypography.titleSmall),
                                            Text(
                                              item.model.width.isNotEmpty ? 'Lebar: ${item.model.width}' : 'Lebar Standar',
                                              style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: AppColors.errorRed),
                                        onPressed: () {
                                          setModalState(() {
                                            selectedModels.removeAt(idx);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'Biaya Tambahan: ',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: item.controller,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            ThousandsSeparatorInputFormatter(),
                                          ],
                                          decoration: InputDecoration(
                                            prefixText: '+ Rp ',
                                            prefixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                                            hintText: '0',
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            filled: true,
                                            fillColor: AppColors.backgroundLight,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: AppColors.borderLight),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: AppColors.primaryGold),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            final clean = val.replaceAll(RegExp(r'\D'), '');
                                            item.additionalPrice = double.tryParse(clean) ?? 0.0;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Quick chips untuk input cepat 0, 100k, 200k, 500k
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('Rp 0 (Termasuk)', style: TextStyle(fontSize: 10)),
                                        selected: item.additionalPrice == 0,
                                        selectedColor: AppColors.goldLight,
                                        onSelected: (_) {
                                          setModalState(() {
                                            item.additionalPrice = 0;
                                            item.controller.text = '0';
                                          });
                                        },
                                      ),
                                      ChoiceChip(
                                        label: const Text('+ 200.000', style: TextStyle(fontSize: 10)),
                                        selected: item.additionalPrice == 200000,
                                        selectedColor: AppColors.goldLight,
                                        onSelected: (_) {
                                          setModalState(() {
                                            item.additionalPrice = 200000;
                                            item.controller.text = '200.000';
                                          });
                                        },
                                      ),
                                      ChoiceChip(
                                        label: const Text('+ 500.000', style: TextStyle(fontSize: 10)),
                                        selected: item.additionalPrice == 500000,
                                        selectedColor: AppColors.goldLight,
                                        onSelected: (_) {
                                          setModalState(() {
                                            item.additionalPrice = 500000;
                                            item.controller.text = '500.000';
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

                                    final packageModelsPayload = selectedModels.map((item) {
                                      final clean = item.controller.text.replaceAll(RegExp(r'\D'), '');
                                      final addPrice = double.tryParse(clean) ?? 0.0;
                                      return {
                                        'model_id': item.model.id,
                                        'additional_price': addPrice,
                                      };
                                    }).toList();

                                    if (isEdit) {
                                      await service.updatePackage(
                                        package.id,
                                        name: nameController.text.trim(),
                                        description: descController.text.trim(),
                                        basePrice: price,
                                        imageUrl: finalImageUrl,
                                        packageModels: packageModelsPayload,
                                      );
                                    } else {
                                      await service.createPackage(
                                        name: nameController.text.trim(),
                                        description: descController.text.trim(),
                                        basePrice: price,
                                        imageUrl: finalImageUrl,
                                        packageModels: packageModelsPayload,
                                      );
                                    }
                                    ref.invalidate(packagesProvider);
                                    if (context.mounted) Navigator.pop(context);
                                  } catch (e) {
                                    setModalState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Gagal menyimpan paket: $e')),
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
                                  isEdit ? 'Simpan Perubahan' : 'Tambah Paket',
                                  style: AppTypography.button,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(DecorationPackage package) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Paket', style: AppTypography.titleMedium),
        content: Text(
          'Apakah Anda yakin ingin menghapus paket "${package.name}"?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.labelMedium.copyWith(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(masterServiceProvider).deletePackage(package.id);
                ref.invalidate(packagesProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus paket: $e')),
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
    ref.listen<AsyncValue<List<DecorationPackage>>>(packagesProvider, (_, next) {
      next.whenData((data) {
        setState(() {
          _localPackages = List.from(data);
        });
      });
    });

    final packagesAsync = ref.watch(packagesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Kelola Paket Dekorasi', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPackageFormSheet(),
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Paket', style: AppTypography.button.copyWith(fontSize: 14)),
      ),
      body: packagesAsync.when(
        data: (packages) {
          if (packages.isEmpty) {
            return Center(
              child: Text('Belum ada paket dekorasi.', style: AppTypography.bodyMedium),
            );
          }

          if (_localPackages == null || _localPackages!.length != packages.length) {
            _localPackages = List.from(packages);
          }
          final displayList = _localPackages!;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(packagesProvider),
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
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
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
                  final ids = displayList.map((p) => p.id).toList();
                  await ref.read(masterServiceProvider).reorderPackages(ids);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Urutan paket berhasil disimpan'),
                        duration: Duration(milliseconds: 1200),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan urutan paket: $e')),
                    );
                  }
                  ref.invalidate(packagesProvider);
                }
              },
              itemBuilder: (context, index) {
                final pkg = displayList[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(pkg.id),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                child: pkg.imageUrl.isNotEmpty
                                    ? Image.network(
                                        pkg.imageUrl,
                                        width: 65,
                                        height: 65,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          width: 65,
                                          height: 65,
                                          color: AppColors.goldLight,
                                          child: const Icon(Icons.inventory_2, color: AppColors.primaryGold),
                                        ),
                                      )
                                    : Container(
                                        width: 65,
                                        height: 65,
                                        color: AppColors.goldLight,
                                        child: const Icon(Icons.inventory_2, color: AppColors.primaryGold),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pkg.name, style: AppTypography.titleSmall),
                                    const SizedBox(height: 2),
                                    Text(
                                      currencyFormatter.format(pkg.basePrice),
                                      style: AppTypography.labelMedium.copyWith(color: AppColors.primaryGold),
                                    ),
                                    if (pkg.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        pkg.description,
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
                                    _showPackageFormSheet(pkg);
                                  } else if (value == 'delete') {
                                    _confirmDelete(pkg);
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
                          // Badge daftar model dekorasi yang terhubung
                          if (pkg.packageModels.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.view_carousel, size: 12, color: AppColors.primaryGold),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${pkg.packageModels.length} Model Tersedia',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.primaryGold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...pkg.packageModels.take(3).map((pm) {
                                  final name = pm.decorationModel?.name ?? 'Model';
                                  final extraText = pm.additionalPrice > 0
                                      ? '+${currencyFormatter.format(pm.additionalPrice)}'
                                      : 'Termasuk';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      '$name ($extraText)',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                    ),
                                  );
                                }),
                                if (pkg.packageModels.length > 3)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    child: Text(
                                      '+${pkg.packageModels.length - 3} lainnya',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    ),
                                  ),
                              ],
                            ),
                          ],
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
          child: Text('Gagal memuat paket: $err', style: AppTypography.bodyMedium.copyWith(color: AppColors.errorRed)),
        ),
      ),
    );
  }
}
