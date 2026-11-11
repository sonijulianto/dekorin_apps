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
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';
import 'package:dekorin_apps/domain/models/picked_image_data.dart';
import 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/core/widgets/loading_overlay_dialog.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class _PackageModelItemEntry {
  final DecorationModel model;
  double additionalPrice;
  final TextEditingController controller;

  _PackageModelItemEntry({required this.model, required this.additionalPrice, required this.controller});
}

class ManagePackagesView extends ConsumerStatefulWidget {
  const ManagePackagesView({super.key});

  @override
  ConsumerState<ManagePackagesView> createState() => _ManagePackagesViewState();
}

class _ManagePackagesViewState extends ConsumerState<ManagePackagesView> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  List<DecorationPackage>? _localPackages;
  String? _selectedFilterBrandId; // null = Semua, '' = Brand Utama, 'brd_...' = Sub-Brand
  bool _isFormSheetOpen = false;

  void _showPackageFormSheet([DecorationPackage? package]) {
    if (_isFormSheetOpen) return;
    _isFormSheetOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PackageFormSheet(
        package: package,
        initialFilterBrandId: _selectedFilterBrandId,
        currencyFormatter: currencyFormatter,
      ),
    ).whenComplete(() {
      if (mounted) {
        _isFormSheetOpen = false;
      }
    });
  }

  Future<void> _confirmDelete(DecorationPackage package) async {
    try {
      await DekorinConfirmActionDialog.show(
        context,
        title: 'Hapus Paket',
        message: 'Apakah Anda yakin ingin menghapus paket "${package.name}"?',
        confirmLabel: 'Hapus',
        onConfirm: () async {
          await ref.read(masterServiceProvider).deletePackage(package.id);
          ref.invalidate(packagesProvider);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus paket: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
          ),
        );
      }
    }
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
    final brandsAsync = ref.watch(companyBrandsProvider);
    final brands = brandsAsync.valueOrNull ?? const <CompanyBrand>[];
    final mainBrandName = ref.watch(globalAuthProvider).valueOrNull?.companyName ?? 'Brand Utama';

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
          if (_localPackages == null || _localPackages!.length != packages.length) {
            _localPackages = List.from(packages);
          }
          final fullList = _localPackages!;
          final displayList = _selectedFilterBrandId == null
              ? fullList
              : fullList.where((p) => p.brandId == _selectedFilterBrandId).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(packagesProvider);
              ref.invalidate(companyBrandsProvider);
            },
            child: ReorderableListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: displayList.length,
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brands.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text(
                              'Semua Brand (${fullList.length})',
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
                  Padding(
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
                  if (displayList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Belum ada paket dekorasi untuk filter brand ini.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                        ),
                      ),
                    ),
                ],
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
                      SnackBar(
                        content: Text('Urutan paket berhasil disimpan', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                        duration: Duration(milliseconds: 1200),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menyimpan urutan paket: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                      ),
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
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
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
                                    if (brands.isNotEmpty || pkg.brandName.isNotEmpty) ...[
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: pkg.brandId.isNotEmpty
                                              ? AppColors.primaryGold.withValues(alpha: 0.14)
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: pkg.brandId.isNotEmpty
                                                ? AppColors.primaryGold.withValues(alpha: 0.4)
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          pkg.brandName.isNotEmpty
                                              ? pkg.brandName
                                              : (mainBrandName.isNotEmpty ? '$mainBrandName (Utama)' : 'Brand Utama'),
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: pkg.brandId.isNotEmpty ? AppColors.secondaryGold : AppColors.textLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                    Text(pkg.name, style: AppTypography.titleSmall),
                                    const SizedBox(height: 2),
                                    Text(
                                      currencyFormatter.format(pkg.basePrice),
                                      style: AppTypography.labelMedium.copyWith(color: AppColors.primaryGold),
                                    ),
                                    if (pkg.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(pkg.description, style: AppTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                                  decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(6)),
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
                                  final extraText = pm.additionalPrice > 0 ? '+${currencyFormatter.format(pm.additionalPrice)}' : 'Termasuk';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      '$name ($extraText)',
                                      style: AppTypography.caption.copyWith(fontSize: 10, color: Colors.grey.shade700),
                                    ),
                                  );
                                }),
                                if (pkg.packageModels.length > 3)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    child: Text(
                                      '+${pkg.packageModels.length - 3} lainnya',
                                      style: AppTypography.caption.copyWith(fontSize: 10, color: Colors.grey.shade500),
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

/// Bottom sheet form tambah/edit paket dekorasi yang langsung terbuka
/// dan menampilkan status loading saat mengambil data model & brand.
class _PackageFormSheet extends ConsumerStatefulWidget {
  const _PackageFormSheet({
    this.package,
    this.initialFilterBrandId,
    required this.currencyFormatter,
  });

  final DecorationPackage? package;
  final String? initialFilterBrandId;
  final NumberFormat currencyFormatter;

  @override
  ConsumerState<_PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends ConsumerState<_PackageFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _thousandFormatter = NumberFormat('#,###', 'id_ID');

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;

  PickedImageData? _selectedImage;
  late String _existingImageUrl;
  late String _selectedBrandId;
  final List<_PackageModelItemEntry> _selectedModels = [];

  List<DecorationModel> _masterModels = const [];
  List<CompanyBrand> _brands = const [];
  bool _isLoadingData = true;
  String? _loadError;
  bool _isSubmitting = false;

  bool get _isEdit => widget.package != null;

  @override
  void initState() {
    super.initState();
    final package = widget.package;
    _nameController = TextEditingController(text: package?.name ?? '');
    _priceController = TextEditingController(
      text: package != null && package.basePrice > 0
          ? _thousandFormatter.format(package.basePrice.toInt()).replaceAll(',', '.')
          : '',
    );
    _descController = TextEditingController(text: package?.description ?? '');
    _existingImageUrl = package?.imageUrl ?? '';
    _selectedBrandId = package?.brandId ?? (widget.initialFilterBrandId ?? '');

    _loadDependencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    for (final item in _selectedModels) {
      item.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDependencies() async {
    setState(() {
      _isLoadingData = true;
      _loadError = null;
    });

    try {
      final modelsFuture = ref.read(masterServiceProvider).getDecorationModels();
      final brandsFuture = ref.read(companyServiceProvider).getCompanyBrands();
      await Future.wait([modelsFuture, brandsFuture]);
      final masterModels = await modelsFuture;
      final brands = await brandsFuture;
      if (!mounted) return;

      final modelMap = {for (final m in masterModels) m.id: m};
      for (final item in _selectedModels) {
        item.controller.dispose();
      }
      _selectedModels.clear();

      final package = widget.package;
      if (package != null && package.packageModels.isNotEmpty) {
        for (final pm in package.packageModels) {
          final model = pm.decorationModel ?? modelMap[pm.decorationModelId];
          if (model != null) {
            final addPrice = pm.additionalPrice;
            final txt = addPrice > 0 ? _thousandFormatter.format(addPrice.toInt()).replaceAll(',', '.') : '0';
            _selectedModels.add(
              _PackageModelItemEntry(
                model: model,
                additionalPrice: addPrice,
                controller: TextEditingController(text: txt),
              ),
            );
          }
        }
      }

      setState(() {
        _masterModels = masterModels;
        _brands = brands;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoadingData = false;
      });
    }
  }

  String _resolveBrandLabel(String bId, String mainBrandName) {
    if (bId.isEmpty) return mainBrandName.isNotEmpty ? '$mainBrandName (Utama)' : 'Brand Utama';
    final found = _brands.where((b) => b.id == bId);
    return found.isNotEmpty ? found.first.name : 'Brand Utama';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1080, maxHeight: 1080);

      if (pickedFile != null && mounted) {
        final pickedImage = await PickedImageData.fromXFile(pickedFile);
        if (!mounted) return;
        setState(() {
          _selectedImage = pickedImage;
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

  Future<void> _showModelSelectorDialog(String brandLabel) async {
    final brandModels = _masterModels.where((m) => m.brandId == _selectedBrandId).toList();
    if (brandModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Belum ada master model dekorasi untuk brand "$brandLabel". Silakan buat model untuk brand tersebut terlebih dahulu.',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryGold,
        ),
      );
      return;
    }

    final selectedMap = <String, _PackageModelItemEntry>{for (final item in _selectedModels) item.model.id: item};

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
                child: Material(
                  color: Colors.transparent,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: brandModels.length,
                    separatorBuilder: (_, unused) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final m = brandModels[idx];
                      final isChecked = selectedMap.containsKey(m.id);

                      return CheckboxListTile(
                        value: isChecked,
                        activeColor: AppColors.primaryGold,
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.name, style: AppTypography.titleSmall),
                        subtitle: Text(
                          '${m.width.isNotEmpty ? 'Lebar: ${m.width} • ' : ''}${widget.currencyFormatter.format(m.price)}',
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgContext),
                  child: Text('Batal', style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold),
                  onPressed: () {
                    setState(() {
                      _selectedModels.clear();
                      _selectedModels.addAll(selectedMap.values);
                    });
                    Navigator.pop(dlgContext);
                  },
                  child: Text('Simpan Pilihan', style: AppTypography.button),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(masterServiceProvider);
      final cleanPrice = _priceController.text.replaceAll(RegExp(r'\D'), '');
      final price = double.parse(cleanPrice);
      String finalImageUrl = _existingImageUrl;

      if (_selectedImage != null) {
        finalImageUrl = await ApiClient.uploadImage(_selectedImage!);
      }

      final packageModelsPayload = _selectedModels.map((item) {
        final clean = item.controller.text.replaceAll(RegExp(r'\D'), '');
        final addPrice = double.tryParse(clean) ?? 0.0;
        return {'model_id': item.model.id, 'additional_price': addPrice};
      }).toList();

      if (_isEdit) {
        await service.updatePackage(
          widget.package!.id,
          brandId: _selectedBrandId,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          basePrice: price,
          imageUrl: finalImageUrl,
          packageModels: packageModelsPayload,
        );
      } else {
        await service.createPackage(
          brandId: _selectedBrandId,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          basePrice: price,
          imageUrl: finalImageUrl,
          packageModels: packageModelsPayload,
        );
      }
      ref.invalidate(packagesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan paket: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainBrandName = ref.watch(globalAuthProvider).value?.companyName ?? 'Brand Utama';

    return PopScope(
      canPop: !_isSubmitting,
      child: SafeArea(
        top: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(_isEdit ? 'Edit Paket Dekorasi' : 'Tambah Paket Baru', style: AppTypography.titleLarge)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoadingData)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primaryGold),
                        const SizedBox(height: 14),
                        Text(
                          'Memuat data paket...',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 42, color: AppColors.errorRed),
                        const SizedBox(height: 10),
                        Text(
                          'Gagal memuat data:\n$_loadError',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold),
                          onPressed: _loadDependencies,
                          child: Text('Coba Lagi', style: AppTypography.button),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label Upload Foto
                      Text('Foto Paket Dekorasi', style: AppTypography.labelLarge),
                      const SizedBox(height: 8),

                      // Box Preview Foto & Button Upload
                      GestureDetector(
                        onTap: _isSubmitting ? null : () => _pickImage(ImageSource.gallery),
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
                            child: _selectedImage != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(_selectedImage!.bytes, fit: BoxFit.cover),
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
                                : _existingImageUrl.isNotEmpty
                                ? Image.network(
                                    _existingImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image, size: 40, color: AppColors.textLight)),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primaryGold),
                                        const SizedBox(height: 8),
                                        Text('Ketuk untuk memilih foto paket', style: AppTypography.caption.copyWith(color: AppColors.textLight)),
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
                              onPressed: _isSubmitting ? null : () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: Text('Galeri', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryGold,
                                side: const BorderSide(color: AppColors.primaryGold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: Text('Kamera', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
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
                        controller: _nameController,
                        label: 'Nama Paket',
                        hint: 'Contoh: Paket Lamaran Modern Rustic',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama paket wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // Pilihan Brand Paket
                      Text('Brand Usaha untuk Paket Ini', style: AppTypography.labelLarge),
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
                                color: _selectedBrandId.isEmpty ? Colors.white : AppColors.textDark,
                              ),
                            ),
                            selected: _selectedBrandId.isEmpty,
                            selectedColor: AppColors.primaryGold,
                            backgroundColor: AppColors.goldLight,
                            onSelected: _isSubmitting
                                ? null
                                : (_) {
                                    setState(() {
                                      _selectedBrandId = '';
                                      _selectedModels.removeWhere((item) => item.model.brandId.isNotEmpty);
                                    });
                                  },
                          ),
                          ..._brands.map((b) {
                            final isSelected = _selectedBrandId == b.id;
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
                              onSelected: _isSubmitting
                                  ? null
                                  : (_) {
                                      setState(() {
                                        _selectedBrandId = b.id;
                                        _selectedModels.removeWhere((item) => item.model.brandId != b.id);
                                      });
                                    },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DekorinTextField(
                        controller: _priceController,
                        label: 'Harga Dasar',
                        hint: 'Contoh: 4.000.000',
                        prefixText: 'Rp ',
                        prefixStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
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
                        controller: _descController,
                        label: 'Deskripsi / Kelengkapan Paket',
                        hint: 'Rincian item kelengkapan...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // ── Bagian Model Dekorasi dalam Paket ──────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Model Dekorasi Paket', style: AppTypography.labelLarge),
                                const SizedBox(height: 2),
                                Text('Pilihan model & biaya tambahan (surcharge)', style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryGold,
                              backgroundColor: AppColors.goldLight.withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(
                              'Pilih Model',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryGold),
                            ),
                            onPressed: _isSubmitting ? null : () => _showModelSelectorDialog(_resolveBrandLabel(_selectedBrandId, mainBrandName)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_selectedModels.isEmpty)
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
                          itemCount: _selectedModels.length,
                          itemBuilder: (ctx, idx) {
                            final item = _selectedModels[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))],
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
                                          setState(() {
                                            _selectedModels.removeAt(idx);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Biaya Tambahan: ',
                                        style: AppTypography.labelMedium.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: item.controller,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                                          decoration: InputDecoration(
                                            prefixText: '+ Rp ',
                                            prefixStyle: AppTypography.labelMedium.copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryGold,
                                            ),
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
                                        label: Text(
                                          'Rp 0 (Termasuk)',
                                          style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textDark),
                                        ),
                                        selected: item.additionalPrice == 0,
                                        selectedColor: AppColors.goldLight,
                                        onSelected: (_) {
                                          setState(() {
                                            item.additionalPrice = 0;
                                            item.controller.text = '0';
                                          });
                                        },
                                      ),
                                      ChoiceChip(
                                        label: Text('+ 200.000', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textDark)),
                                        selected: item.additionalPrice == 200000,
                                        selectedColor: AppColors.goldLight,
                                        onSelected: (_) {
                                          setState(() {
                                            item.additionalPrice = 200000;
                                            item.controller.text = '200.000';
                                          });
                                        },
                                      ),
                                      ChoiceChip(
                                        label: Text('+ 500.000', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textDark)),
                                        selected: item.additionalPrice == 500000,
                                        selectedColor: AppColors.goldLight,
                                        onSelected: (_) {
                                          setState(() {
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Paket', style: AppTypography.button),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
