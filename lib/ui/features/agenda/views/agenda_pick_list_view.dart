import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/data/services/property_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/property.dart';
import 'package:dekorin_apps/ui/features/master/widgets/multi_select_property_sheet.dart';

class AgendaPickListView extends ConsumerStatefulWidget {
  const AgendaPickListView({
    super.key,
    required this.agenda,
  });

  final AgendaItem agenda;

  @override
  ConsumerState<AgendaPickListView> createState() => _AgendaPickListViewState();
}

class _AgendaPickListViewState extends ConsumerState<AgendaPickListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final dateFormatter = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddPropertyDialog() {
    final propertiesAsync = ref.read(propertiesProvider);
    final masterProps = propertiesAsync.value ?? <Property>[];

    Property? selectedMasterProp;
    final customNameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final notesController = TextEditingController();
    bool isCustom = masterProps.isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tambah Barang Bawaan', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Toggle Master vs Custom
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => isCustom = false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isCustom ? AppColors.goldLight : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !isCustom ? AppColors.primaryGold : Colors.transparent,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Pilih dari Master',
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: !isCustom ? FontWeight.bold : FontWeight.normal,
                                    color: !isCustom ? AppColors.primaryGold : AppColors.textLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => isCustom = true),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isCustom ? AppColors.goldLight : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCustom ? AppColors.primaryGold : Colors.transparent,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Barang Tambahan Bebas',
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
                                    color: isCustom ? AppColors.primaryGold : AppColors.textLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (!isCustom) ...[
                      Text('Pilih Properti / Alat', style: AppTypography.labelMedium),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<Property>(
                        initialValue: selectedMasterProp,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Pilih barang dari gudang',
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: masterProps.map((p) {
                          return DropdownMenuItem<Property>(
                            value: p,
                            child: Text(
                              '${p.isTool ? "🛠️" : "📦"} ${p.name} (${p.category})',
                              style: AppTypography.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setSheetState(() {
                            selectedMasterProp = val;
                          });
                        },
                      ),
                    ] else ...[
                      Text('Nama Barang', style: AppTypography.labelMedium),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: customNameController,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Kursi Tiffany Tambahan, Kabel Ekstra',
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jumlah (Qty)', style: AppTypography.labelMedium),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  hintText: '1',
                                  filled: true,
                                  fillColor: AppColors.backgroundLight,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Catatan (Opsional)', style: AppTypography.labelMedium),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: notesController,
                                decoration: InputDecoration(
                                  hintText: 'Contoh: warna gold',
                                  filled: true,
                                  fillColor: AppColors.backgroundLight,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                          final notes = notesController.text.trim();
                          String propertyId = '';
                          String customName = '';

                          if (isCustom) {
                            customName = customNameController.text.trim();
                            if (customName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Nama barang tidak boleh kosong', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            propertyId = 'custom';
                          } else {
                            if (selectedMasterProp == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Silakan pilih barang terlebih dahulu', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            propertyId = selectedMasterProp!.id;
                            customName = selectedMasterProp!.name;
                          }

                          try {
                            await ref.read(propertyServiceProvider).addAgendaProperty(
                              widget.agenda.id,
                              propertyId: propertyId,
                              customName: customName,
                              qty: qty,
                              notes: notes,
                            );

                            ref.invalidate(agendaPropertiesProvider(widget.agenda.id));
                            if (sheetCtx.mounted) {
                              Navigator.pop(sheetCtx);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Barang berhasil ditambahkan ke Pick List', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                                  backgroundColor: AppColors.primaryGold,
                                ),
                              );
                            }
                          } catch (e) {
                            if (sheetCtx.mounted) {
                              ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menambahkan: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Tambahkan ke Pick List', style: AppTypography.button),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSyncFromModelDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Sinkronkan dari Model?', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          content: Text(
            'Sistem akan mengisi ulang daftar bawaan sesuai template model "${widget.agenda.modelName.isNotEmpty ? widget.agenda.modelName : "Model Terpilih"}".',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Batal', style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  final result = await ref.read(propertyServiceProvider).populateAgendaProperties(
                    widget.agenda.id,
                    modelId: widget.agenda.modelId,
                    mode: 'replace',
                  );

                  ref.invalidate(agendaPropertiesProvider(widget.agenda.id));
                  final warnings = (result['warnings'] as List<dynamic>? ?? []);
                  if (mounted) {
                    if (warnings.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text('Peringatan Stok', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pick list berhasil diisi, namun ada beberapa barang dengan stok terbatas di tanggal ini:',
                                style: AppTypography.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              ...warnings.map((w) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('• $w', style: AppTypography.caption.copyWith(color: Colors.red.shade700)),
                                  )),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('Mengerti', style: AppTypography.button.copyWith(color: AppColors.primaryGold)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Pick list berhasil disinkronkan dari model!', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                          backgroundColor: AppColors.primaryGold,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal sinkronisasi: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.white),
              child: Text('Ya, Sinkronkan', style: AppTypography.button),
            ),
          ],
        );
      },
    );
  }

  void _showEditItemDialog(AgendaProperty item) {
    final qtyController = TextEditingController(text: item.qty.toString());
    final notesController = TextEditingController(text: item.notes);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Barang Bawaan', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.displayName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Jumlah (Qty)', style: AppTypography.labelMedium),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final n = int.tryParse(qtyController.text) ?? 1;
                      if (n > 1) {
                        qtyController.text = (n - 1).toString();
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryGold),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        suffixText: item.unit,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final n = int.tryParse(qtyController.text) ?? 1;
                      qtyController.text = (n + 1).toString();
                    },
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Catatan', style: AppTypography.labelMedium),
              const SizedBox(height: 4),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: 'Tambahkan catatan...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Batal', style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final newQty = int.tryParse(qtyController.text) ?? item.qty;
                final newNotes = notesController.text.trim();

                try {
                  await ref.read(propertyServiceProvider).updateAgendaProperty(
                    widget.agenda.id,
                    item.id,
                    qty: newQty,
                    notes: newNotes,
                  );
                  ref.invalidate(agendaPropertiesProvider(widget.agenda.id));
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memperbarui item: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white))),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.white),
              child: Text('Simpan', style: AppTypography.button),
            ),
          ],
        );
      },
    );
  }

  void _openMultiSelectPicker() async {
    final propertiesAsync = ref.read(propertiesProvider);
    final masterProps = propertiesAsync.value ?? <Property>[];
    if (masterProps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Master properti belum tersedia.', style: AppTypography.bodyMedium.copyWith(color: Colors.white))),
      );
      return;
    }

    final currentItems = ref.read(agendaPropertiesProvider(widget.agenda.id)).value ?? [];
    final currentIds = currentItems.map((it) => it.propertyId).toSet();
    final currentQtys = {for (var it in currentItems) it.propertyId: it.qty};

    final result = await MultiSelectPropertySheet.show(
      context,
      allProperties: masterProps,
      initiallySelectedPropertyIds: currentIds,
      initialQuantities: currentQtys,
    );

    if (result != null && mounted) {
      final itemsPayload = result.map((item) {
        return {
          'property_id': item.property.id,
          'qty': item.qty,
        };
      }).toList();

      try {
        await ref.read(propertyServiceProvider).batchAddAgendaProperties(
          widget.agenda.id,
          itemsPayload,
          mode: 'replace',
        );
        ref.invalidate(agendaPropertiesProvider(widget.agenda.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${result.length} barang berhasil diterapkan ke Pick List!', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
              backgroundColor: AppColors.primaryGold,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan barang: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showApplyFromAnotherModelDialog() async {
    final models = await ref.read(masterServiceProvider).getDecorationModels();
    final validModels = models.where((m) => m.modelProperties.isNotEmpty).toList();

    if (!mounted) return;
    if (validModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belum ada model dekorasi yang memiliki barang bawaan.', style: AppTypography.bodyMedium.copyWith(color: Colors.white)), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.copy_rounded, color: AppColors.primaryGold, size: 20),
            const SizedBox(width: 8),
            Text('Terapkan dari Model Lain', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih model untuk diterapkan barang bawaannya ke agenda ini:', style: AppTypography.bodySmall),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: validModels.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final m = validModels[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.view_carousel, color: AppColors.primaryGold, size: 20),
                      ),
                      title: Text(m.name, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('${m.modelProperties.length} Barang & Alat', style: AppTypography.caption),
                      onTap: () {
                        Navigator.pop(dialogCtx);
                        _confirmApplyModel(m);
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
      ),
    );
  }

  void _confirmApplyModel(DecorationModel m) {
    final currentItems = ref.read(agendaPropertiesProvider(widget.agenda.id)).value ?? [];

    void executeApply(String mode) async {
      try {
        final result = await ref.read(propertyServiceProvider).populateAgendaProperties(
          widget.agenda.id,
          modelId: m.id,
          mode: mode,
        );
        ref.invalidate(agendaPropertiesProvider(widget.agenda.id));
        final warnings = (result['warnings'] as List<dynamic>? ?? []);
        if (mounted) {
          if (warnings.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Peringatan: ${warnings.first}', style: AppTypography.bodyMedium.copyWith(color: Colors.white)), backgroundColor: Colors.orange),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Berhasil menerapkan ${m.modelProperties.length} barang dari "${m.name}"!', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                backgroundColor: AppColors.primaryGold,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menerapkan model: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)), backgroundColor: Colors.red),
          );
        }
      }
    }

    if (currentItems.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Metode Terapkan', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          content: Text('Daftar saat ini berisi ${currentItems.length} barang. Apakah ingin mengganti semua atau menggabungkannya?', style: AppTypography.bodySmall),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                executeApply('merge');
              },
              child: Text('Gabungkan', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                executeApply('replace');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.white),
              child: Text('Ganti Semua', style: AppTypography.button),
            ),
          ],
        ),
      );
    } else {
      executeApply('replace');
    }
  }

  void _clearPickList() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Kosongkan Pick List?', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus seluruh barang dari pick list agenda ini?', style: AppTypography.bodySmall),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text('Batal', style: AppTypography.caption)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref.read(propertyServiceProvider).clearAgendaProperties(widget.agenda.id);
                ref.invalidate(agendaPropertiesProvider(widget.agenda.id));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pick list berhasil dikosongkan', style: AppTypography.bodyMedium.copyWith(color: Colors.white)), backgroundColor: AppColors.primaryGold),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengosongkan: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Kosongkan', style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  void _deleteItem(AgendaProperty item) async {
    try {
      await ref.read(propertyServiceProvider).deleteAgendaProperty(widget.agenda.id, item.id);
      ref.invalidate(agendaPropertiesProvider(widget.agenda.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.displayName} dihapus dari Pick List', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.primaryGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final agendaPropsAsync = ref.watch(agendaPropertiesProvider(widget.agenda.id));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Checklist Muat Barang', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            Text(
              '${widget.agenda.clientName} • ${widget.agenda.modelName.isNotEmpty ? widget.agenda.modelName : "Custom"}',
              style: AppTypography.caption.copyWith(color: AppColors.textLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Pilih Banyak Sekaligus',
            icon: const Icon(Icons.checklist_rounded, color: AppColors.primaryGold),
            onPressed: _openMultiSelectPicker,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textLight),
            onSelected: (val) {
              if (val == 'apply_model') {
                _showApplyFromAnotherModelDialog();
              } else if (val == 'sync_current') {
                _showSyncFromModelDialog();
              } else if (val == 'add_custom') {
                _showAddPropertyDialog();
              } else if (val == 'clear_all') {
                _clearPickList();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'apply_model',
                child: Row(
                  children: [
                    const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryGold),
                    const SizedBox(width: 8),
                    Text('Terapkan dari Model Lain', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sync_current',
                child: Row(
                  children: [
                    const Icon(Icons.sync_rounded, size: 18, color: AppColors.primaryGold),
                    const SizedBox(width: 8),
                    Text('Sinkronkan Model Acara', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_custom',
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primaryGold),
                    const SizedBox(width: 8),
                    Text('Tambah Barang Bebas/Custom', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Kosongkan Pick List', style: AppTypography.bodySmall.copyWith(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          indicatorWeight: 3,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textLight,
          labelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTypography.titleSmall,
          tabs: const [
            Tab(text: '🚚 Muat Berangkat'),
            Tab(text: '📦 Bongkar Pulang'),
          ],
        ),
      ),
      body: agendaPropsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Gagal memuat pick list: $err', style: AppTypography.bodyMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(agendaPropertiesProvider(widget.agenda.id)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                child: Text('Coba Lagi', style: AppTypography.button),
              ),
            ],
          ),
        ),
        data: (items) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildChecklistTab(items, isPackMode: true),
              _buildChecklistTab(items, isPackMode: false),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMultiSelectPicker,
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.checklist_rounded, size: 20),
        label: Text('Pilih Cepat Sekaligus', style: AppTypography.button),
      ),
    );
  }

  Widget _buildChecklistTab(List<AgendaProperty> items, {required bool isPackMode}) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.playlist_add_check_rounded, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                'Belum ada barang di pick list acara ini',
                style: AppTypography.titleSmall.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 8),
              Text(
                'Ketuk tombol sinkronisasi di kanan atas atau tombol tambah di bawah untuk mengisi.',
                style: AppTypography.caption.copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showSyncFromModelDialog,
                icon: const Icon(Icons.sync, size: 18),
                label: Text('Isi Otomatis dari Model', style: AppTypography.button),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
              ),
            ],
          ),
        ),
      );
    }

    final totalCount = items.length;
    final checkedCount = items.where((it) => isPackMode ? it.isPacked : it.isReturned).length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;
    final isAllDone = checkedCount == totalCount;

    final properties = items.where((it) => !it.isTool).toList();
    final tools = items.where((it) => it.isTool).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Progress Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAllDone ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAllDone ? Colors.green.shade300 : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
                      Icon(
                        isAllDone
                            ? Icons.check_circle_rounded
                            : (isPackMode ? Icons.local_shipping_rounded : Icons.home_repair_service_rounded),
                        color: isAllDone ? Colors.green.shade700 : AppColors.primaryGold,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPackMode ? 'Status Muat Berangkat' : 'Status Bongkar Pulang',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isAllDone ? Colors.green.shade900 : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAllDone ? Colors.green.shade600 : AppColors.primaryGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$checkedCount / $totalCount Selesai',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.backgroundLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAllDone ? Colors.green.shade600 : AppColors.primaryGold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAllDone
                    ? (isPackMode ? '🎉 Semua barang & alat sudah masuk ke mobil!' : '🎉 Semua barang & alat lengkap kembali!')
                    : (isPackMode
                        ? 'Centang item di bawah saat dimuat ke mobil/kendaraan.'
                        : 'Centang item di bawah saat selesai dibongkar di venue.'),
                style: AppTypography.caption.copyWith(
                  color: isAllDone ? Colors.green.shade800 : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 1: Properti Dekorasi
        if (properties.isNotEmpty) ...[
          _buildSectionHeader('📦 PROPERTI DEKORASI', properties.length),
          const SizedBox(height: 8),
          ...properties.map((item) => _buildItemTile(item, isPackMode: isPackMode)),
          const SizedBox(height: 20),
        ],

        // Section 2: Alat Kerja
        if (tools.isNotEmpty) ...[
          _buildSectionHeader('🛠️ ALAT KERJA & PERLENGKAPAN', tools.length),
          const SizedBox(height: 8),
          ...tools.map((item) => _buildItemTile(item, isPackMode: isPackMode)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.goldLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count Item',
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(AgendaProperty item, {required bool isPackMode}) {
    final isChecked = isPackMode ? item.isPacked : item.isReturned;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isChecked ? Colors.green.shade50.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isChecked ? Colors.green.shade200 : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Transform.scale(
          scale: 1.15,
          child: Checkbox(
            value: isChecked,
            activeColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (val) async {
              HapticFeedback.lightImpact();
              try {
                if (isPackMode) {
                  await ref.read(propertyServiceProvider).togglePacked(widget.agenda.id, item.id);
                } else {
                  await ref.read(propertyServiceProvider).toggleReturned(widget.agenda.id, item.id);
                }
                ref.invalidate(agendaPropertiesProvider(widget.agenda.id));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengubah status: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ),
        title: Text(
          item.displayName,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            decoration: isChecked ? TextDecoration.lineThrough : null,
            color: isChecked ? Colors.grey.shade600 : AppColors.textDark,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isChecked ? Colors.green.shade100 : AppColors.goldLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${item.qty} ${item.unit}',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isChecked ? Colors.green.shade800 : AppColors.primaryGold,
                ),
              ),
            ),
            if (item.notes.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.notes,
                  style: AppTypography.caption.copyWith(color: AppColors.textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textLight),
          onSelected: (action) {
            if (action == 'edit') {
              _showEditItemDialog(item);
            } else if (action == 'delete') {
              _deleteItem(item);
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryGold),
                  const SizedBox(width: 8),
                  Text('Ubah Qty / Catatan', style: AppTypography.bodySmall),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Hapus Item', style: AppTypography.bodySmall.copyWith(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
