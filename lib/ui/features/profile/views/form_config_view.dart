import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/data/services/form_config_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/form_config.dart';

class FormConfigView extends ConsumerStatefulWidget {
  const FormConfigView({super.key});

  @override
  ConsumerState<FormConfigView> createState() => _FormConfigViewState();
}

class _FormConfigViewState extends ConsumerState<FormConfigView> {
  String _selectedBrandId = '';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPrice = true;
  bool _isInherited = false;
  String? _errorMessage;
  List<FormFieldDefinition> _fields = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cfg = await ref.read(formConfigServiceProvider).getFormConfig(brandId: _selectedBrandId);
      if (!mounted) return;
      setState(() {
        _fields = List<FormFieldDefinition>.from(cfg.fields);
        _showPrice = cfg.showPrice;
        _isInherited = cfg.isInherited;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final ordered = <FormFieldDefinition>[];
      for (var i = 0; i < _fields.length; i++) {
        ordered.add(_fields[i].copyWith(sortOrder: i + 1));
      }

      await ref.read(formConfigServiceProvider).updateFormConfig(
            brandId: _selectedBrandId,
            showPrice: _showPrice,
            fields: ordered,
          );

      if (!mounted) return;
      setState(() {
        _fields = ordered;
        _isInherited = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengaturan form client berhasil disimpan!',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan: $e',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Reset ke Setelan Default?', style: AppTypography.titleMedium),
        content: Text(
          'Daftar isian form untuk brand ini akan dikembalikan ke template standar sistem.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reset Default', style: AppTypography.button.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final cfg = await ref.read(formConfigServiceProvider).resetFormConfig(brandId: _selectedBrandId);
      if (!mounted) return;
      setState(() {
        _fields = List<FormFieldDefinition>.from(cfg.fields);
        _showPrice = cfg.showPrice;
        _isInherited = cfg.isInherited;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengaturan dikembalikan ke default.', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal reset: $e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showFieldEditorSheet({int? editIndex}) {
    final isEdit = editIndex != null && editIndex >= 0 && editIndex < _fields.length;
    final existing = isEdit ? _fields[editIndex] : null;
    final isSystem = existing?.isSystem ?? false;

    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final placeholderCtrl = TextEditingController(text: existing?.placeholder ?? '');
    final optionsCtrl = TextEditingController(text: (existing?.options ?? []).join('\n'));
    String selectedType = existing?.type ?? 'text';
    bool isRequired = existing?.isRequired ?? false;
    final formKey = GlobalKey<FormState>();

    const customTypes = [
      ('text', 'Teks Singkat'),
      ('textarea', 'Paragraf / Catatan'),
      ('number', 'Angka'),
      ('date', 'Tanggal'),
      ('time', 'Jam'),
      ('select', 'Dropdown Pilihan'),
      ('radio', 'Pilihan Tunggal (Radio)'),
      ('checkbox', 'Pilihan Ganda (Checkbox)'),
      ('image', 'Upload Foto / Gambar'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final needsOptions = selectedType == 'select' || selectedType == 'radio' || selectedType == 'checkbox';

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? (isSystem ? 'Ubah Label & Opsi Field' : 'Ubah Pertanyaan Kustom') : 'Tambah Pertanyaan Kustom',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atur pertanyaan yang akan tampil pada link isian client.',
                      style: AppTypography.caption.copyWith(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: labelCtrl,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Label Pertanyaan *',
                        labelStyle: AppTypography.bodySmall,
                        hintText: 'Misal: Jam Loading Gedung / Warna Bunga',
                        hintStyle: AppTypography.caption,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Label pertanyaan wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    if (!isSystem) ...[
                      DropdownButtonFormField<String>(
                        initialValue: customTypes.any((t) => t.$1 == selectedType) ? selectedType : 'text',
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Tipe Input',
                          labelStyle: AppTypography.bodySmall,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: customTypes
                            .map((t) => DropdownMenuItem<String>(
                                  value: t.$1,
                                  child: Text(t.$2, style: AppTypography.bodyMedium),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!isSystem && needsOptions) ...[
                      TextFormField(
                        controller: optionsCtrl,
                        maxLines: 3,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Daftar Pilihan (1 opsi per baris atau pisahkan koma) *',
                          labelStyle: AppTypography.bodySmall,
                          hintText: 'Indoor AC\nSemi Outdoor\nOutdoor / Tenda',
                          hintStyle: AppTypography.caption,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (needsOptions && (v == null || v.trim().isEmpty)) {
                            return 'Minimal masukkan 1 opsi pilihan';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: placeholderCtrl,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Petunjuk / Placeholder (Opsional)',
                        labelStyle: AppTypography.bodySmall,
                        hintText: 'Contoh: Isi jam akses loading gedung...',
                        hintStyle: AppTypography.caption,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                      ),
                      child: SwitchListTile(
                        activeThumbColor: AppColors.primaryGold,
                        title: Text('Wajib Diisi (Required)', style: AppTypography.titleSmall),
                        subtitle: Text(
                          'Client harus mengisi kolom ini sebelum link terkunci menjadi ringkasan.',
                          style: AppTypography.caption,
                        ),
                        value: isRequired,
                        onChanged: (val) => setModalState(() => isRequired = val),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final cleanLabel = labelCtrl.text.trim();
                          final cleanPlaceholder = placeholderCtrl.text.trim();
                          final parsedOpts = optionsCtrl.text
                              .split(RegExp(r'[\n,]+'))
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          setState(() {
                            if (isEdit && existing != null) {
                              _fields[editIndex] = existing.copyWith(
                                label: cleanLabel,
                                placeholder: cleanPlaceholder,
                                type: isSystem ? existing.type : selectedType,
                                options: isSystem ? existing.options : parsedOpts,
                                isRequired: isRequired,
                                isActive: isRequired ? true : existing.isActive,
                              );
                            } else {
                              final rand = Random().nextInt(999999).toString().padLeft(6, '0');
                              _fields.add(FormFieldDefinition(
                                key: 'custom_$rand',
                                label: cleanLabel,
                                type: selectedType,
                                placeholder: cleanPlaceholder,
                                options: parsedOpts,
                                isSystem: false,
                                isActive: true,
                                isRequired: isRequired,
                                sortOrder: _fields.length + 1,
                              ));
                            }
                          });

                          Navigator.pop(ctx);
                        },
                        child: Text('Simpan Pertanyaan', style: AppTypography.button.copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(companyBrandsProvider).valueOrNull ?? const <CompanyBrand>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Pengaturan Form Client', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            tooltip: 'Reset Default',
            icon: const Icon(Icons.restart_alt_rounded, color: AppColors.textLight),
            onPressed: _isLoading || _isSaving ? null : _confirmReset,
          ),
        ],
      ),
      body: Column(
        children: [
          // Brand / Sub-Brand Selector Tabs
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Brand / Sub-Brand:',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(
                          'Brand Utama',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _selectedBrandId.isEmpty ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        selected: _selectedBrandId.isEmpty,
                        selectedColor: AppColors.primaryGold,
                        backgroundColor: AppColors.goldLight,
                        onSelected: (_) {
                          setState(() => _selectedBrandId = '');
                          _loadConfig();
                        },
                      ),
                      ...brands.map((b) {
                        final isSelected = _selectedBrandId == b.id;
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
                            backgroundColor: AppColors.goldLight,
                            onSelected: (_) {
                              setState(() => _selectedBrandId = b.id);
                              _loadConfig();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (_isInherited && _selectedBrandId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      'Sub-brand ini masih mengikuti template default. Tekan Simpan di bawah untuk kustomisasi khusus brand ini.',
                      style: AppTypography.caption.copyWith(color: Colors.amber.shade900, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Gagal memuat pengaturan:\n$_errorMessage', textAlign: TextAlign.center, style: AppTypography.bodySmall),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold),
                        onPressed: _loadConfig,
                        child: Text('Coba Lagi', style: AppTypography.button.copyWith(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Global Show Price Toggle + Add Custom Field Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: SwitchListTile(
                            dense: true,
                            activeThumbColor: AppColors.primaryGold,
                            title: Text('Tampilkan Harga & Tagihan di Link', style: AppTypography.titleSmall.copyWith(fontSize: 13)),
                            subtitle: Text('Matikan jika link dikirim untuk klien melalui WO/EO', style: AppTypography.caption),
                            value: _showPrice,
                            onChanged: (val) => setState(() => _showPrice = val),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Tahan & geser (drag) atau ketuk panah untuk ubah urutan isian.',
                                style: AppTypography.caption.copyWith(color: AppColors.textLight),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _showFieldEditorSheet(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.secondaryGold,
                                side: const BorderSide(color: AppColors.primaryGold),
                                backgroundColor: AppColors.goldLight,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.secondaryGold),
                              label: Text('Pertanyaan', style: AppTypography.labelMedium.copyWith(color: AppColors.secondaryGold, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reorderable Field List
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: _fields.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _fields.removeAt(oldIndex);
                          _fields.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final field = _fields[index];
                        return Container(
                          key: ValueKey(field.key),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: field.isActive ? Colors.white : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: field.isActive ? AppColors.borderLight : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.goldLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.drag_indicator, size: 16, color: AppColors.secondaryGold),
                                          const SizedBox(width: 2),
                                          Text(
                                            '#${index + 1}',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.secondaryGold,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          field.label,
                                          style: AppTypography.titleSmall.copyWith(
                                            color: field.isActive ? AppColors.textDark : AppColors.textLight,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                field.typeDisplayLabel,
                                                style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textDark),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: field.isSystem ? AppColors.goldLight : Colors.purple.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                field.isSystem ? 'Bawaan' : 'Kustom',
                                                style: AppTypography.caption.copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: field.isSystem ? AppColors.secondaryGold : Colors.purple.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Ubah Label/Opsi',
                                    icon: SvgPicture.asset(
                                      'assets/icons/edit.svg',
                                      width: 16,
                                      height: 16,
                                      colorFilter: const ColorFilter.mode(AppColors.textLight, BlendMode.srcIn),
                                    ),
                                    onPressed: () => _showFieldEditorSheet(editIndex: index),
                                  ),
                                  if (!field.isSystem)
                                    IconButton(
                                      tooltip: 'Hapus Pertanyaan',
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.errorRed),
                                      onPressed: () {
                                        setState(() => _fields.removeAt(index));
                                      },
                                    ),
                                ],
                              ),
                              const Divider(height: 16, color: AppColors.dividerColor),
                              Row(
                                children: [
                                  // Toggle ON / OFF
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          final nextActive = !field.isActive;
                                          _fields[index] = field.copyWith(
                                            isActive: nextActive,
                                            isRequired: nextActive ? field.isRequired : false,
                                          );
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            height: 28,
                                            child: Switch(
                                              activeThumbColor: AppColors.successGreen,
                                              value: field.isActive,
                                              onChanged: (val) {
                                                setState(() {
                                                  _fields[index] = field.copyWith(
                                                    isActive: val,
                                                    isRequired: val ? field.isRequired : false,
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            field.isActive ? 'Aktif (ON)' : 'Nonaktif (OFF)',
                                            style: AppTypography.caption.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: field.isActive ? AppColors.successGreen : AppColors.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Toggle Required / Opsional
                                  Expanded(
                                    child: Opacity(
                                      opacity: field.isActive ? 1.0 : 0.4,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            field.isRequired ? 'Wajib Diisi' : 'Opsional',
                                            style: AppTypography.caption.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: field.isRequired ? AppColors.secondaryGold : AppColors.textLight,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          SizedBox(
                                            height: 28,
                                            child: Switch(
                                              activeThumbColor: AppColors.primaryGold,
                                              value: field.isRequired,
                                              onChanged: !field.isActive
                                                  ? null
                                                  : (val) {
                                                      setState(() {
                                                        _fields[index] = field.copyWith(isRequired: val);
                                                      });
                                                    },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Sticky Bottom Save Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: _isSaving ? null : _saveConfig,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/lock.svg',
                                      width: 18,
                                      height: 18,
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Simpan Pengaturan Form',
                                      style: AppTypography.button.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
