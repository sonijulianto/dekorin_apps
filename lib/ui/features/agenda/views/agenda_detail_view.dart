import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_preview_view.dart';
import 'package:dekorin_apps/ui/features/dashboard/view_models/dashboard_view_model.dart';

class AgendaDetailView extends ConsumerStatefulWidget {
  const AgendaDetailView({super.key, required this.item});

  final AgendaItem item;

  @override
  ConsumerState<AgendaDetailView> createState() => _AgendaDetailViewState();
}

class _AgendaDetailViewState extends ConsumerState<AgendaDetailView> {
  late AgendaItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _updatePaymentStatus(String newStatus) async {
    try {
      final updated = await ref.read(agendaServiceProvider).updatePaymentStatus(_item.id, newStatus);
      setState(() {
        _item = updated;
      });
      ref.invalidate(agendaViewModelProvider);
      ref.invalidate(dashboardViewModelProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'paid'
                ? 'Pembayaran berhasil ditandai LUNAS!'
                : 'Status pembayaran berhasil diperbarui!'),
            backgroundColor: newStatus == 'paid' ? Colors.green : AppColors.primaryGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateEventStatus(String newStatus) async {
    try {
      final updated = await ref.read(agendaServiceProvider).updateEventStatus(_item.id, newStatus);
      setState(() {
        _item = updated;
      });
      ref.invalidate(agendaViewModelProvider);
      ref.invalidate(dashboardViewModelProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'completed'
                ? 'Acara berhasil ditandai SELESAI!'
                : 'Status acara berhasil diperbarui!'),
            backgroundColor: newStatus == 'completed' ? Colors.green : AppColors.primaryGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status acara: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tautan tidak dapat dibuka: $urlString')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka tautan: $e')),
        );
      }
    }
  }

  Future<void> _sendWhatsAppMessage(BuildContext context) async {
    final formUrl = '${ApiEndpoint.webFormBaseUrl}/form/${_item.formToken}';

    String phone = _item.clientPhone.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62') && phone.isNotEmpty) {
      phone = '62$phone';
    }

    final message =
        'Halo Kak ${_item.clientName}, terima kasih telah memesan dekorasi di Dekorin! ✨\n\n'
        'Mohon bantu lengkapi detail acara (alamat, tema, warna, dll) melalui tautan berikut ya:\n'
        '$formUrl';

    final waUrl = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: '$message\n$formUrl'));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nomor WA tidak dapat dibuka. Pesan & Link disalin ke Clipboard!'),
              backgroundColor: AppColors.primaryGold,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: '$message\n$formUrl'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesan & Link disalin ke Clipboard!'),
            backgroundColor: AppColors.primaryGold,
          ),
        );
      }
    }
  }

  void _showEditDpDialog(BuildContext context) {
    final thousandFormatter = NumberFormat('#,###', 'id_ID');
    final initialText = _item.dpAmount > 0
        ? thousandFormatter.format(_item.dpAmount.toInt()).replaceAll(',', '.')
        : '';

    final dpController = TextEditingController(text: initialText);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payments_outlined, color: AppColors.primaryGold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text('Input Pembayaran DP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan nominal DP yang telah dibayarkan oleh client:',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: dpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                      hintText: '1.000.000',
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          // Bersihkan titik pemisah ribuan sebelum dikirim ke backend
                          final cleanDigits = dpController.text.replaceAll(RegExp(r'\D'), '');
                          final newDp = double.tryParse(cleanDigits) ?? 0.0;

                          setDialogState(() => isSaving = true);
                          try {
                            final updated = await ref
                                .read(agendaServiceProvider)
                                .updateAgendaDp(_item.id, newDp);
                            
                            // Refresh list agenda & dashboard
                            ref.read(agendaViewModelProvider.notifier).refresh();
                            ref.invalidate(dashboardViewModelProvider);

                            if (mounted) {
                              setState(() {
                                _item = updated;
                              });
                            }
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pembayaran DP berhasil disimpan! 🎉'),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menyimpan DP: $e'),
                                  backgroundColor: AppColors.errorRed,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan DP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTransportDialog(BuildContext context) {
    final thousandFormatter = NumberFormat('#,###', 'id_ID');
    final initialText = _item.transportFee > 0
        ? thousandFormatter.format(_item.transportFee.toInt()).replaceAll(',', '.')
        : '';

    final transportController = TextEditingController(text: initialText);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_shipping_outlined, color: AppColors.primaryGold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text('Input Uang Transport', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan nominal biaya transportasi / pengiriman untuk agenda ini:',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: transportController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                      hintText: '150.000',
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final cleanDigits = transportController.text.replaceAll(RegExp(r'\D'), '');
                          final newTransport = double.tryParse(cleanDigits) ?? 0.0;

                          setDialogState(() => isSaving = true);
                          try {
                            final updated = await ref
                                .read(agendaServiceProvider)
                                .updateAgendaTransport(_item.id, newTransport);
                            
                            ref.read(agendaViewModelProvider.notifier).refresh();
                            ref.invalidate(dashboardViewModelProvider);

                            if (mounted) {
                              setState(() {
                                _item = updated;
                              });
                            }
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Uang transport berhasil disimpan! 🎉'),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menyimpan uang transport: $e'),
                                  backgroundColor: AppColors.errorRed,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Transport', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPackageDialog(BuildContext context) async {
    final thousandFormatter = NumberFormat('#,###', 'id_ID');

    final isUnselected = _item.packageName.toLowerCase().contains('belum dipilih') ||
        _item.packageName.isEmpty;

    double currentPrice = 0.0;
    if (!isUnselected) {
      if (_item.clientForm != null && _item.clientForm!.packagePrice > 0) {
        currentPrice = _item.clientForm!.packagePrice;
      } else if (_item.packagePrice > 0) {
        currentPrice = _item.packagePrice;
      }
    }

    String selectedPackageId = _item.packageId;
    final nameController = TextEditingController(
      text: !isUnselected
          ? (_item.packageName.isNotEmpty
              ? _item.packageName
              : (_item.clientForm?.packageName ?? ''))
          : '',
    );
    final priceController = TextEditingController(
      text: currentPrice > 0
          ? thousandFormatter.format(currentPrice.toInt()).replaceAll(',', '.')
          : '',
    );
    bool isSaving = false;

    // Ambil master paket dekorasi untuk opsi quick pick
    List<DecorationPackage> masterPackages = [];
    try {
      masterPackages = await ref.read(masterServiceProvider).getPackages();
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryGold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Ubah Paket Dekorasi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (masterPackages.isNotEmpty) ...[
                      const Text(
                        'Pilihan Master Paket:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...masterPackages.map((pkg) {
                            final isCurrent = selectedPackageId == pkg.id;
                            return ChoiceChip(
                              label: Text('${pkg.name} (${thousandFormatter.format(pkg.basePrice.toInt())})'),
                              selected: isCurrent,
                              selectedColor: AppColors.goldLight,
                              backgroundColor: Colors.grey.shade100,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? AppColors.primaryDark : AppColors.textDark,
                              ),
                              side: BorderSide(
                                color: isCurrent ? AppColors.primaryGold : Colors.grey.shade300,
                              ),
                              onSelected: (_) {
                                setDialogState(() {
                                  selectedPackageId = pkg.id;
                                  nameController.text = pkg.name;
                                  priceController.text = thousandFormatter.format(pkg.basePrice.toInt()).replaceAll(',', '.');
                                });
                              },
                            );
                          }),
                          ChoiceChip(
                            label: const Text('Belum Dipilih (Rp 0)'),
                            selected: selectedPackageId.isEmpty && (nameController.text == 'Belum Dipilih' || nameController.text.isEmpty),
                            backgroundColor: Colors.grey.shade100,
                            selectedColor: Colors.grey.shade200,
                            labelStyle: const TextStyle(fontSize: 11, color: AppColors.textLight),
                            onSelected: (_) {
                              setDialogState(() {
                                selectedPackageId = '';
                                nameController.text = 'Belum Dipilih';
                                priceController.text = '0';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],
                    const Text(
                      'Detail Paket & Harga (Bisa Diedit Manual):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Paket',
                        hintText: 'Contoh: Paket Platinum / Custom',
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Harga Paket',
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                        hintText: '1.100.000',
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final cleanDigits = priceController.text.replaceAll(RegExp(r'\D'), '');
                          final newPrice = double.tryParse(cleanDigits) ?? 0.0;
                          final pkgName = nameController.text.trim().isNotEmpty
                              ? nameController.text.trim()
                              : 'Belum Dipilih';

                          setDialogState(() => isSaving = true);
                          try {
                            final updated = await ref.read(agendaServiceProvider).updateAgendaPackage(
                                  _item.id,
                                  packageId: selectedPackageId,
                                  packageName: pkgName,
                                  packagePrice: newPrice,
                                  formToken: _item.formToken,
                                  eventAddress: _item.mapsUrl,
                                );

                            ref.read(agendaViewModelProvider.notifier).refresh();
                            ref.invalidate(dashboardViewModelProvider);

                            if (mounted) {
                              setState(() {
                                _item = updated;
                              });
                            }
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Paket dekorasi berhasil disimpan! 🎉'),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menyimpan paket: $e'),
                                  backgroundColor: AppColors.errorRed,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Paket', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm', 'id_ID');
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isFilled = _item.formStatus == 'filled';
    final form = _item.clientForm;

    final isUnselected = _item.packageName.toLowerCase().contains('belum dipilih') ||
        (form != null && form.packageName.toLowerCase().contains('belum dipilih')) ||
        (_item.packageName.isEmpty && (form == null || form.packageName.isEmpty));

    // Kalkulasi Harga Paket & Addon
    double packagePrice = 0.0;
    if (isUnselected) {
      packagePrice = 0.0;
    } else if (form != null && form.packagePrice > 0) {
      packagePrice = form.packagePrice;
    } else if (_item.packagePrice > 0) {
      packagePrice = _item.packagePrice;
    } else {
      final nameLower = _item.packageName.toLowerCase();
      if (nameLower.contains('akad') || nameLower.contains('minimalis')) {
        packagePrice = 2500000.0;
      } else if (nameLower.contains('lamaran') || nameLower.contains('rustic')) {
        packagePrice = 4000000.0;
      } else if (nameLower.contains('pernikahan') || nameLower.contains('elegan')) {
        packagePrice = 9500000.0;
      } else if (nameLower.contains('ballroom') || nameLower.contains('luxury')) {
        packagePrice = 18000000.0;
      } else {
        packagePrice = 0.0;
      }
    }

    double addonsPrice = form?.addonsPrice ?? 0.0;
    if (addonsPrice == 0 && _item.notes.contains('[Item Tambahan / Addon]:')) {
      final parts = _item.notes.split('[Item Tambahan / Addon]:');
      if (parts.length > 1) {
        final lines = parts[1].trim().split('\n');
        for (var line in lines) {
          if (line.contains('(') && line.contains(')')) {
            final openIdx = line.indexOf('(');
            final closeIdx = line.lastIndexOf(')');
            final pStr = line.substring(openIdx + 1, closeIdx);
            if (pStr.contains('=')) {
              final val = double.tryParse(pStr.split('=')[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
              addonsPrice += val;
            } else {
              final val = double.tryParse(pStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
              addonsPrice += val;
            }
          }
        }
      }
    }

    final double subtotal = packagePrice + addonsPrice;
    final double transportFee = _item.transportFee;
    final double totalBiaya = subtotal + transportFee;
    final double sisaPelunasan = (totalBiaya - _item.dpAmount) > 0 ? (totalBiaya - _item.dpAmount) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Detail Agenda Acara', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.primaryGold),
            tooltip: 'Cetak Invoice',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoicePreviewView(agenda: _item),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Client Card Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFilled ? Colors.green.shade50 : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isFilled ? Colors.green.shade300 : Colors.amber.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFilled ? Icons.check_circle : Icons.hourglass_top,
                                    size: 14,
                                    color: isFilled ? Colors.green.shade700 : Colors.amber.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isFilled ? 'Form Terisi' : 'Menunggu Form Client',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isFilled ? Colors.green.shade700 : Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildEventStatusBadge(),
                            if (_item.packageName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.goldLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _item.packageName,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (_item.modelName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.goldLight.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.view_carousel, size: 12, color: AppColors.primaryGold),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_item.modelName}${_item.modelWidth.isNotEmpty ? ' (${_item.modelWidth})' : ''}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Text(_item.clientName, style: AppTypography.h2),
                        if (_item.backdropTitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _item.backdropTitle,
                            style: AppTypography.titleMedium.copyWith(color: AppColors.primaryGold),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Action Contacts
                        Row(
                          children: [
                            const Icon(Icons.phone_android, size: 18, color: AppColors.textLight),
                            const SizedBox(width: 8),
                            Text(
                              _item.clientPhone.isNotEmpty ? _item.clientPhone : 'Belum ada nomor HP',
                              style: AppTypography.bodyMedium,
                            ),
                            const Spacer(),
                            if (_item.clientPhone.isNotEmpty) ...[
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.blue, size: 20),
                                tooltip: 'Telepon Client',
                                onPressed: () => _launchUrl(context, 'tel:${_item.clientPhone}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                tooltip: 'WhatsApp Client',
                                onPressed: () => _sendWhatsAppMessage(context),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Integrated Event & Decoration Information Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informasi Acara & Dekorasi', style: AppTypography.titleMedium),
                        const SizedBox(height: 14),

                        // Tanggal & Jam
                        _buildInfoRow(
                          Icons.calendar_month_outlined,
                          'Jadwal Acara',
                          '${dateFormat.format(_item.eventDateTime)} • ${timeFormat.format(_item.eventDateTime)} WIB',
                        ),
                        const SizedBox(height: 12),

                        // Alamat Acara (dari form client atau notes)
                        if (form != null && form.eventAddress.isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            'Alamat Acara',
                            form.eventAddress,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Link Google Maps
                        if (_item.mapsUrl.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.map_outlined, size: 20, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Link Google Maps', style: AppTypography.caption),
                                    const SizedBox(height: 2),
                                    GestureDetector(
                                      onTap: () => _launchUrl(context, _item.mapsUrl),
                                      child: Text(
                                        _item.mapsUrl,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Tema Dekorasi
                        if (form != null && form.decorationTheme.isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.palette_outlined,
                            'Tema Dekorasi',
                            form.decorationTheme,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Warna Favorit
                        if (form != null && form.colorPreference.isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.color_lens_outlined,
                            'Preferensi Warna',
                            form.colorPreference,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Permintaan Khusus / Catatan Tambahan & Item Tambahan (Addon)
                        ..._buildNotesAndAddonsSection(context, form?.specialRequests.isNotEmpty == true ? form!.specialRequests : _item.notes),

                        // Foto Inspirasi
                        if (form != null && form.referencePhotoUrl.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () => _launchUrl(context, form.referencePhotoUrl),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.image_outlined, color: Colors.blue, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Foto Inspirasi Dekorasi', style: AppTypography.caption.copyWith(color: Colors.blue.shade900)),
                                        Text(
                                          form.referencePhotoUrl,
                                          style: AppTypography.bodySmall.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new, color: Colors.blue, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Rincian Invoice & Status Pembayaran DP Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined, color: AppColors.primaryGold, size: 22),
                                const SizedBox(width: 8),
                                Text('Rincian Pembayaran & DP', style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark)),
                              ],
                            ),
                            // Tombol Edit / Input DP
                            InkWell(
                              onTap: () => _showEditDpDialog(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _item.dpAmount > 0 ? Icons.edit_outlined : Icons.add_circle_outline,
                                      size: 14,
                                      color: AppColors.primaryGold,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _item.dpAmount > 0 ? 'Ubah DP' : 'Input DP',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Rincian Paket Dekorasi
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primaryGold),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Paket: ${_item.packageName.isNotEmpty ? _item.packageName : (form?.packageName.isNotEmpty == true ? form!.packageName : "Belum Dipilih")}',
                                            style: AppTypography.bodySmall.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            packagePrice > 0 ? currencyFormatter.format(packagePrice) : 'Rp 0 (Belum diatur)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: packagePrice > 0 ? AppColors.primaryGold : AppColors.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showEditPackageDialog(context),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldLight.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        packagePrice > 0 ? Icons.edit_outlined : Icons.add_circle_outline,
                                        size: 12,
                                        color: AppColors.primaryGold,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        packagePrice > 0 ? 'Ubah' : 'Pilih',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_item.modelName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _item.modelImageUrl.isNotEmpty
                                      ? Image.network(
                                          _item.modelImageUrl,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 32,
                                            height: 32,
                                            color: AppColors.goldLight,
                                            child: const Icon(Icons.view_carousel, size: 16, color: AppColors.primaryGold),
                                          ),
                                        )
                                      : Container(
                                          width: 32,
                                          height: 32,
                                          color: AppColors.goldLight,
                                          child: const Icon(Icons.view_carousel, size: 16, color: AppColors.primaryGold),
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Model: ${_item.modelName}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      ),
                                      Row(
                                        children: [
                                          if (_item.modelWidth.isNotEmpty) ...[
                                            Text(
                                              'Lebar: ${_item.modelWidth}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (_item.modelAdditionalPrice > 0)
                                            Text(
                                              '+${currencyFormatter.format(_item.modelAdditionalPrice)}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                            )
                                          else
                                            const Text(
                                              'Tanpa Biaya Tambahan',
                                              style: TextStyle(fontSize: 11, color: AppColors.successGreen, fontWeight: FontWeight.w500),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (addonsPrice > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  form != null && form.selectedAddons.isNotEmpty
                                      ? 'Addon: ${form.selectedAddons}'
                                      : 'Addon (Item Tambahan)',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(currencyFormatter.format(addonsPrice), style: AppTypography.titleSmall),
                            ],
                          ),
                        ],

                        // Baris Uang Transport
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.primaryGold),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Uang Transport:',
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    transportFee > 0 ? currencyFormatter.format(transportFee) : 'Rp 0',
                                    style: AppTypography.titleSmall.copyWith(color: AppColors.textDark),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => _showEditTransportDialog(context),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldLight,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        transportFee > 0 ? Icons.edit_outlined : Icons.add_circle_outline,
                                        size: 12,
                                        color: AppColors.primaryGold,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        transportFee > 0 ? 'Ubah' : 'Input Transport',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (totalBiaya > 0) ...[
                          const Divider(height: 20, color: AppColors.primaryGold),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL BIAYA', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                currencyFormatter.format(totalBiaya),
                                style: AppTypography.h2.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],

                        // ── Banner Status Pembayaran ──
                        if (_item.isPaidOff)
                          Container(
                            margin: const EdgeInsets.only(top: 4, bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade400),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified, color: Colors.green.shade700, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'STATUS: LUNAS (SELESAI)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      Text(
                                        'Pendapatan agenda ini tercatat penuh di Dashboard.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: Colors.green.shade800, size: 20),
                                  tooltip: 'Ubah Status',
                                  onSelected: (val) => _updatePaymentStatus(val),
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'dp',
                                      child: Text('Ubah ke DP (Belum Lunas)'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'unpaid',
                                      child: Text('Ubah ke Belum Bayar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Container(
                            margin: const EdgeInsets.only(top: 4, bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _item.dpAmount > 0 ? Colors.amber.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _item.dpAmount > 0 ? Colors.amber.shade300 : Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _item.dpAmount > 0 ? Icons.pending_actions : Icons.warning_amber_rounded,
                                  color: _item.dpAmount > 0 ? Colors.amber.shade900 : Colors.red.shade700,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _item.dpAmount > 0 ? 'STATUS: DP MASUK (BELUM LUNAS)' : 'STATUS: BELUM BAYAR',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: _item.dpAmount > 0 ? Colors.amber.shade900 : Colors.red.shade700,
                                        ),
                                      ),
                                      Text(
                                        'Tandai LUNAS agar nominal dihitung ke pendapatan dashboard.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _item.dpAmount > 0 ? Colors.amber.shade800 : Colors.red.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: const Text('Tandai Pembayaran Lunas?'),
                                    content: Text(
                                      'Apakah pembayaran agenda untuk "${_item.clientName}" sebesar ${currencyFormatter.format(totalBiaya)} sudah lunas diterima?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogCtx),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(dialogCtx);
                                          _updatePaymentStatus('paid');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Ya, Sudah Lunas'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Tandai Pembayaran Lunas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Baris Informasi Pembayaran DP
                        InkWell(
                          onTap: () => _showEditDpDialog(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _item.dpAmount > 0 ? Colors.green.shade300 : Colors.amber.shade300,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _item.dpAmount > 0 ? Icons.check_circle_outline : Icons.pending_outlined,
                                          size: 16,
                                          color: _item.dpAmount > 0 ? Colors.green.shade700 : Colors.amber.shade800,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Pembayaran DP Masuk',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _item.dpAmount > 0 ? Colors.green.shade800 : Colors.amber.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          _item.dpAmount > 0 ? currencyFormatter.format(_item.dpAmount) : 'Belum Ada DP',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _item.dpAmount > 0 ? Colors.green.shade800 : Colors.amber.shade900,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.edit_outlined, size: 13, color: AppColors.primaryGold),
                                      ],
                                    ),
                                  ],
                                ),
                              if (totalBiaya > 0 && _item.dpAmount > 0) ...[
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Sisa Pelunasan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      currencyFormatter.format(sisaPelunasan),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                        // Tombol Cetak / Lihat Invoice
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InvoicePreviewView(agenda: _item),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_outlined, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Cetak / Lihat Invoice Resmi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final formUrl = '${ApiEndpoint.webFormBaseUrl}/form/${_item.formToken}';
                        Clipboard.setData(ClipboardData(text: formUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Link form disalin: $formUrl'),
                            backgroundColor: AppColors.primaryGold,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Salin Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _sendWhatsAppMessage(context),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Bagikan ke WA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              const SizedBox(height: 1),
              Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNotesAndAddonsSection(BuildContext context, String rawNotes) {
    final widgets = <Widget>[];
    if (rawNotes.trim().isEmpty) return widgets;

    // Deteksi tag addon [Item Tambahan / Addon]:
    const addonTag = '[Item Tambahan / Addon]:';
    String generalNotes = rawNotes;
    List<String> addonLines = [];

    if (rawNotes.contains(addonTag)) {
      final parts = rawNotes.split(addonTag);
      generalNotes = parts[0].trim();
      if (parts.length > 1) {
        final addonContent = parts[1].trim();
        addonLines = addonContent
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      }
    }

    // 1. Tampilkan List Addon jika ada
    if (addonLines.isNotEmpty) {
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.add_shopping_cart, size: 20, color: AppColors.primaryGold),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Item Tambahan (Addon)', style: AppTypography.caption),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${addonLines.length} Item',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: addonLines.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 12,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        String line = addonLines[index];
                        if (line.startsWith('- ')) {
                          line = line.substring(2).trim();
                        }

                        // Contoh format: "Standing Flower x3 (Rp 50.000/unit = Rp 150.000)"
                        // atau "Spotlight (Rp 75.000)"
                        String itemName = line;
                        String pricePart = '';

                        if (line.contains('(') && line.endsWith(')')) {
                          final openIdx = line.indexOf('(');
                          final closeIdx = line.lastIndexOf(')');
                          itemName = line.substring(0, openIdx).trim();
                          pricePart = line.substring(openIdx + 1, closeIdx).trim();
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemName,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  if (pricePart.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      pricePart,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    // 2. Tampilkan Catatan Biasa (jika ada sisa teks selain addon)
    if (generalNotes.isNotEmpty) {
      widgets.add(
        _buildInfoRow(
          Icons.notes_outlined,
          'Catatan & Permintaan Khusus',
          generalNotes,
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  Widget _buildEventStatusBadge() {
    Color bg;
    Color border;
    Color textCol;
    String label;
    IconData icon;

    if (_item.isEventCompleted) {
      bg = Colors.green.shade50;
      border = Colors.green.shade300;
      textCol = Colors.green.shade800;
      label = 'Acara Selesai';
      icon = Icons.check_circle;
    } else if (_item.isCancelled) {
      bg = Colors.red.shade50;
      border = Colors.red.shade300;
      textCol = Colors.red.shade800;
      label = 'Dibatalkan';
      icon = Icons.cancel;
    } else {
      bg = Colors.blue.shade50;
      border = Colors.blue.shade300;
      textCol = Colors.blue.shade800;
      label = 'Akan Datang';
      icon = Icons.event_note;
    }

    return PopupMenuButton<String>(
      tooltip: 'Ubah Status Acara',
      onSelected: (val) => _updateEventStatus(val),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'upcoming', child: Text('Tandai: Akan Datang')),
        const PopupMenuItem(value: 'completed', child: Text('Tandai: Acara Selesai')),
        const PopupMenuItem(value: 'cancelled', child: Text('Tandai: Dibatalkan')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textCol),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: textCol),
          ],
        ),
      ),
    );
  }
}


/// TextInputFormatter untuk memformat angka secara otomatis dengan pemisah ribuan titik (Indonesian format).
/// Contoh: mengetik "1000000" otomatis menjadi "1.000.000".
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Ambil hanya angka
    final cleanDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.tryParse(cleanDigits);
    if (number == null) return oldValue;

    final formatted = _formatter.format(number).replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
