import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/data/services/property_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/property.dart';
import 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/master/widgets/multi_select_property_sheet.dart';

class ManageDecorationModelsView extends ConsumerStatefulWidget {
  const ManageDecorationModelsView({super.key});

  @override
  ConsumerState<ManageDecorationModelsView> createState() => _ManageDecorationModelsViewState();
}

class _ManageDecorationModelsViewState extends ConsumerState<ManageDecorationModelsView> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  List<DecorationModel>? _localModels;
  String _searchQuery = '';
  String? _selectedFilterBrandId; // null = Semua, '' = Brand Utama, 'brd_...' = Sub-Brand

  void _showModelFormSheet([DecorationModel? model]) async {
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
    String selectedBrandId = model?.brandId ?? (_selectedFilterBrandId ?? '');
    bool isSubmitting = false;

    final brands = await ref.read(companyServiceProvider).getCompanyBrands();
    final allProperties = await ref.read(propertyServiceProvider).getProperties();
    final mainBrandName = ref.read(globalAuthProvider).value?.companyName ?? 'Brand Utama';
    List<DecorationModelProperty> selectedProps = List.from(model?.modelProperties ?? []);
    if (!mounted) return;

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

                      // Pilihan Brand Model
                      Text('Brand Usaha untuk Model Ini', style: AppTypography.labelLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(
                              mainBrandName.isNotEmpty ? '$mainBrandName (Utama)' : 'Brand Utama',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: selectedBrandId.isEmpty ? Colors.white : AppColors.textDark,
                              ),
                            ),
                            selected: selectedBrandId.isEmpty,
                            selectedColor: AppColors.primaryGold,
                            backgroundColor: AppColors.goldLight,
                            onSelected: (_) => setModalState(() => selectedBrandId = ''),
                          ),
                          ...brands.map((b) {
                            final isSelected = selectedBrandId == b.id;
                            return ChoiceChip(
                              label: Text(
                                b.name,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textDark,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primaryGold,
                              backgroundColor: AppColors.goldLight,
                              onSelected: (_) => setModalState(() => selectedBrandId = b.id),
                            );
                          }),
                        ],
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
                      const SizedBox(height: 16),

                      // Section Template Properti & Alat Bawaan
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.playlist_add_check_circle, size: 20, color: AppColors.primaryGold),
                                    const SizedBox(width: 8),
                                    Text('Barang & Alat Bawaan', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (selectedProps.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (clearCtx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: Text('Kosongkan Daftar?', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                          content: Text('Semua barang bawaan untuk model ini akan dihapus dari daftar.', style: AppTypography.bodySmall),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(clearCtx), child: Text('Batal', style: AppTypography.caption)),
                                            ElevatedButton(
                                              onPressed: () {
                                                setModalState(() => selectedProps.clear());
                                                Navigator.pop(clearCtx);
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                              child: Text('Kosongkan', style: AppTypography.button),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.red),
                                          const SizedBox(width: 2),
                                          Text('Kosongkan', style: AppTypography.caption.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Barang di bawah akan otomatis terisi saat model ini dipilih pada agenda.',
                              style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textLight),
                            ),
                            const SizedBox(height: 10),

                            // Action Buttons: Salin dari Model Lain & Pilih Sekaligus
                            Row(
                              children: [
                                // Tombol 1: Salin dari Model Lain
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final otherModels = (_localModels ?? ref.read(decorationModelsProvider).value ?? [])
                                          .where((m) => m.id != model?.id && m.modelProperties.isNotEmpty)
                                          .toList();

                                      if (otherModels.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Belum ada model lain yang memiliki barang bawaan untuk disalin.', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      showDialog(
                                        context: context,
                                        builder: (dialogCtx) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: Row(
                                              children: [
                                                const Icon(Icons.copy_rounded, color: AppColors.primaryGold, size: 20),
                                                const SizedBox(width: 8),
                                                Text('Salin dari Model Lain', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            content: SizedBox(
                                              width: double.maxFinite,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Pilih model yang ingin disalin seluruh barang & alatnya:', style: AppTypography.bodySmall),
                                                  const SizedBox(height: 12),
                                                  Flexible(
                                                    child: ListView.separated(
                                                      shrinkWrap: true,
                                                      itemCount: otherModels.length,
                                                      separatorBuilder: (_, _) => const Divider(height: 1),
                                                      itemBuilder: (ctx, idx) {
                                                        final om = otherModels[idx];
                                                        return ListTile(
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          leading: Container(
                                                            padding: const EdgeInsets.all(6),
                                                            decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(8)),
                                                            child: const Icon(Icons.view_carousel, color: AppColors.primaryGold, size: 20),
                                                          ),
                                                          title: Text(om.name, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                                          subtitle: Text('${om.modelProperties.length} Barang & Alat', style: AppTypography.caption),
                                                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
                                                          onTap: () {
                                                            Navigator.pop(dialogCtx);
                                                            void applyClone(bool replace) {
                                                              setModalState(() {
                                                                if (replace) {
                                                                  selectedProps.clear();
                                                                }
                                                                for (final mp in om.modelProperties) {
                                                                  if (!selectedProps.any((sp) => sp.propertyId == mp.propertyId)) {
                                                                    selectedProps.add(
                                                                      DecorationModelProperty(
                                                                        id: '',
                                                                        decorationModelId: model?.id ?? '',
                                                                        propertyId: mp.propertyId,
                                                                        defaultQty: mp.defaultQty,
                                                                        property: mp.property,
                                                                      ),
                                                                    );
                                                                  }
                                                                }
                                                              });
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('✓ ${om.modelProperties.length} barang berhasil disalin dari "${om.name}"!', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                                                                  backgroundColor: AppColors.primaryGold,
                                                                ),
                                                              );
                                                            }

                                                            if (selectedProps.isNotEmpty) {
                                                              showDialog(
                                                                context: context,
                                                                builder: (confirmCtx) => AlertDialog(
                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                                  title: Text('Metode Salin', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                                                  content: Text('Daftar saat ini sudah berisi ${selectedProps.length} barang. Apakah ingin mengganti semua atau menggabungkannya?', style: AppTypography.bodySmall),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () {
                                                                        Navigator.pop(confirmCtx);
                                                                        applyClone(false);
                                                                      },
                                                                      child: Text('Gabungkan', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                                                                    ),
                                                                    ElevatedButton(
                                                                      onPressed: () {
                                                                        Navigator.pop(confirmCtx);
                                                                        applyClone(true);
                                                                      },
                                                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.white),
                                                                      child: Text('Ganti Semua', style: AppTypography.button),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            } else {
                                                              applyClone(true);
                                                            }
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text('Tutup', style: AppTypography.caption)),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 15),
                                    label: Text('Salin dari Model', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryGold,
                                      side: const BorderSide(color: AppColors.primaryGold),
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Tombol 2: Pilih Sekaligus (Multi-Select)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final selectedIds = selectedProps.map((p) => p.propertyId).toSet();
                                      final currentQtys = {for (var p in selectedProps) p.propertyId: p.defaultQty};

                                      final result = await MultiSelectPropertySheet.show(
                                        context,
                                        allProperties: allProperties,
                                        initiallySelectedPropertyIds: selectedIds,
                                        initialQuantities: currentQtys,
                                      );

                                      if (result != null) {
                                        setModalState(() {
                                          selectedProps = result.map((item) {
                                            return DecorationModelProperty(
                                              id: '',
                                              decorationModelId: model?.id ?? '',
                                              propertyId: item.property.id,
                                              defaultQty: item.qty,
                                              property: item.property,
                                            );
                                          }).toList();
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.checklist_rounded, size: 16),
                                    label: Text('Pilih Sekaligus', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGold,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // List of items currently selected
                            if (selectedProps.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.center,
                                child: Text('Belum ada barang bawaan yang diatur', style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                              )
                            else
                              ...selectedProps.map((sp) {
                                final propName = sp.property?.name ?? allProperties.firstWhere((p) => p.id == sp.propertyId, orElse: () => Property(id: sp.propertyId, name: 'Barang #${sp.propertyId}')).name;
                                final isTool = sp.property?.isTool ?? allProperties.firstWhere((p) => p.id == sp.propertyId, orElse: () => const Property(id: '', name: '')).isTool;
                                final unit = sp.property?.unit ?? allProperties.firstWhere((p) => p.id == sp.propertyId, orElse: () => const Property(id: '', name: '', unit: 'pcs')).unit;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderLight)),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isTool ? Colors.blue.shade50 : AppColors.goldLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(isTool ? '🛠️' : '📦', style: const TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(propName, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text(unit, style: AppTypography.caption.copyWith(color: AppColors.textLight, fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                      // Stepper Qty (- dan +) langsung di kartu
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundLight,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.borderLight),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                if (sp.defaultQty > 1) {
                                                  setModalState(() {
                                                    final idx = selectedProps.indexOf(sp);
                                                    if (idx != -1) {
                                                      selectedProps[idx] = DecorationModelProperty(
                                                        id: sp.id,
                                                        decorationModelId: sp.decorationModelId,
                                                        propertyId: sp.propertyId,
                                                        defaultQty: sp.defaultQty - 1,
                                                        property: sp.property,
                                                      );
                                                    }
                                                  });
                                                }
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(Icons.remove, size: 14, color: AppColors.primaryGold),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Text(
                                                '${sp.defaultQty}',
                                                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setModalState(() {
                                                  final idx = selectedProps.indexOf(sp);
                                                  if (idx != -1) {
                                                    selectedProps[idx] = DecorationModelProperty(
                                                      id: sp.id,
                                                      decorationModelId: sp.decorationModelId,
                                                      propertyId: sp.propertyId,
                                                      defaultQty: sp.defaultQty + 1,
                                                      property: sp.property,
                                                    );
                                                  }
                                                });
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(Icons.add, size: 14, color: AppColors.primaryGold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                        onPressed: () {
                                          setModalState(() {
                                            selectedProps.removeWhere((p) => p.propertyId == sp.propertyId);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
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

                                    final modelPropsPayload = selectedProps.map((sp) {
                                      return {
                                        'property_id': sp.propertyId,
                                        'default_qty': sp.defaultQty,
                                        'notes': sp.notes,
                                      };
                                    }).toList();

                                    if (isEdit) {
                                      await service.updateDecorationModel(
                                        model.id,
                                        brandId: selectedBrandId,
                                        name: nameController.text.trim(),
                                        width: widthController.text.trim(),
                                        price: price,
                                        description: descController.text.trim(),
                                        imageUrl: finalImageUrl,
                                        modelProperties: modelPropsPayload,
                                      );
                                    } else {
                                      await service.createDecorationModel(
                                        brandId: selectedBrandId,
                                        name: nameController.text.trim(),
                                        width: widthController.text.trim(),
                                        price: price,
                                        description: descController.text.trim(),
                                        imageUrl: finalImageUrl,
                                        modelProperties: modelPropsPayload,
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
    final brandsAsync = ref.watch(companyBrandsProvider);
    final brands = brandsAsync.value ?? const <CompanyBrand>[];
    final mainBrandName = ref.watch(globalAuthProvider).value?.companyName ?? 'Brand Utama';

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

          final brandFiltered = _selectedFilterBrandId == null
              ? displayList
              : displayList.where((m) => m.brandId == _selectedFilterBrandId).toList();

          final filteredList = _searchQuery.isEmpty
              ? brandFiltered
              : brandFiltered.where((m) {
                  final q = _searchQuery.toLowerCase();
                  return m.name.toLowerCase().contains(q) ||
                      m.width.toLowerCase().contains(q) ||
                      m.description.toLowerCase().contains(q);
                }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(decorationModelsProvider);
              ref.invalidate(companyBrandsProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                if (brands.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(
                            'Semua Brand (${displayList.length})',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _selectedFilterBrandId == null ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          selected: _selectedFilterBrandId == null,
                          selectedColor: AppColors.primaryGold,
                          backgroundColor: Colors.white,
                          onSelected: (_) => setState(() => _selectedFilterBrandId = null),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(
                            mainBrandName.isNotEmpty ? '$mainBrandName (Utama)' : 'Brand Utama',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _selectedFilterBrandId == '' ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          selected: _selectedFilterBrandId == '',
                          selectedColor: AppColors.primaryGold,
                          backgroundColor: Colors.white,
                          onSelected: (_) => setState(() => _selectedFilterBrandId = ''),
                        ),
                        ...brands.map((b) {
                          final isSelected = _selectedFilterBrandId == b.id;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text(
                                b.name,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textDark,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primaryGold,
                              backgroundColor: Colors.white,
                              onSelected: (_) => setState(() => _selectedFilterBrandId = b.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
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
                                if (brands.isNotEmpty || model.brandName.isNotEmpty) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: model.brandId.isNotEmpty
                                          ? AppColors.primaryGold.withValues(alpha: 0.14)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: model.brandId.isNotEmpty
                                            ? AppColors.primaryGold.withValues(alpha: 0.4)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      model.brandName.isNotEmpty
                                          ? model.brandName
                                          : (mainBrandName.isNotEmpty ? '$mainBrandName (Utama)' : 'Brand Utama'),
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: model.brandId.isNotEmpty ? AppColors.secondaryGold : AppColors.textLight,
                                      ),
                                    ),
                                  ),
                                ],
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
                                    SvgPicture.asset(
                                      'assets/icons/edit.svg',
                                      width: 18,
                                      height: 18,
                                      colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                                    ),
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
