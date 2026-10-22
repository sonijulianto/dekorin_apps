import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/views/addon_picker_screen.dart';
import 'package:dekorin_apps/ui/features/agenda/views/model_picker_screen.dart';
import 'package:dekorin_apps/ui/features/agenda/views/package_picker_screen.dart';

class CreateAgendaSheet extends ConsumerStatefulWidget {
  const CreateAgendaSheet({super.key});

  @override
  ConsumerState<CreateAgendaSheet> createState() => _CreateAgendaSheetState();
}

class _CreateAgendaSheetState extends ConsumerState<CreateAgendaSheet> {
  final _formKey = GlobalKey<FormState>();

  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _backdropTitleController = TextEditingController();
  final _mapsUrlController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DecorationPackage? _selectedPackage;
  DecorationModel? _selectedModel;
  double _selectedModelAdditionalPrice = 0.0;
  List<SelectedAddonItem> _selectedAddons = [];
  bool _isLoading = false;

  Future<void> _openPackagePicker() async {
    final result = await Navigator.of(context).push<DecorationPackage>(
      MaterialPageRoute(
        builder: (_) => PackagePickerScreen(
          selectedPackageId: _selectedPackage?.id,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedPackage = result;
        // Sinkronkan harga tambahan jika model sudah pernah dipilih
        if (_selectedModel != null) {
          final matchingPm = result.packageModels
              .where((pm) => pm.decorationModelId == _selectedModel!.id)
              .firstOrNull;
          if (matchingPm != null) {
            _selectedModelAdditionalPrice = matchingPm.additionalPrice;
          } else {
            _selectedModelAdditionalPrice = 0.0;
          }
        }
      });
    }
  }

  Future<void> _openModelPicker() async {
    final result = await Navigator.of(context).push<SelectedModelResult>(
      MaterialPageRoute(
        builder: (_) => ModelPickerScreen(
          package: _selectedPackage,
          selectedModelId: _selectedModel?.id,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedModel = result.model;
        _selectedModelAdditionalPrice = result.additionalPrice;
      });
    }
  }

  Future<void> _openAddonPicker() async {
    final result = await Navigator.of(context).push<List<SelectedAddonItem>>(
      MaterialPageRoute(
        builder: (_) => AddonPickerScreen(
          initiallySelectedAddons: _selectedAddons,
        ),
      ),
    );
    if (result != null) {
      setState(() => _selectedAddons = result);
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _backdropTitleController.dispose();
    _mapsUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGold,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGold,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi Nama Client dan Nomor HP terlebih dahulu'),
          backgroundColor: AppTheme.errorRed,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    DateTime? eventDateTime;
    if (_selectedDate != null && _selectedTime != null) {
      eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    try {
      final agendaService = ref.read(agendaServiceProvider);
      
      String combinedNotes = _notesController.text.trim();

      // Tambahkan info Model Dekorasi ke Catatan
      if (_selectedModel != null) {
        final extraText = _selectedModelAdditionalPrice > 0
            ? ' (+${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_selectedModelAdditionalPrice)})'
            : ' (Termasuk Paket)';
        final modelText = '[Model Dekorasi]: ${_selectedModel!.name}${_selectedModel!.width.isNotEmpty ? ' (Lebar: ${_selectedModel!.width})' : ''}$extraText';
        if (combinedNotes.isNotEmpty) {
          combinedNotes = '$combinedNotes\n\n$modelText';
        } else {
          combinedNotes = modelText;
        }
      }

      if (_selectedAddons.isNotEmpty) {
        final addonNames = _selectedAddons.map((item) {
          final unitPriceFormatted = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(item.addon.price);

          final totalPriceFormatted = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(item.totalPrice);

          if (item.quantity > 1) {
            return '- ${item.addon.name} x${item.quantity} ($unitPriceFormatted/unit = $totalPriceFormatted)';
          }
          return '- ${item.addon.name} ($unitPriceFormatted)';
        }).join('\n');
        
        final addonText = '[Item Tambahan / Addon]:\n$addonNames';
        if (combinedNotes.isNotEmpty) {
          combinedNotes = '$combinedNotes\n\n$addonText';
        } else {
          combinedNotes = addonText;
        }
      }

      final effectivePackagePrice = (_selectedPackage?.basePrice ?? 0.0) + _selectedModelAdditionalPrice;

      await agendaService.createAgenda(
        clientName: _clientNameController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        backdropTitle: _backdropTitleController.text.trim(),
        eventDateTime: eventDateTime,
        mapsUrl: _mapsUrlController.text.trim(),
        packageId: _selectedPackage?.id ?? '',
        packagePrice: effectivePackagePrice,
        modelId: _selectedModel?.id ?? '',
        modelName: _selectedModel?.name ?? '',
        modelWidth: _selectedModel?.width ?? '',
        modelImageUrl: _selectedModel?.imageUrl ?? '',
        modelAdditionalPrice: _selectedModelAdditionalPrice,
        notes: combinedNotes,
      );

      // Refresh list agenda
      await ref.read(agendaViewModelProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agenda berhasil ditambahkan! 🎉'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan agenda: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_note,
                      color: AppTheme.primaryGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat Agenda Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Wajib isi Nama Client. Detail lain dapat diisi oleh client via Web Form.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Nama Client
              const Text(
                'Nama Client *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _clientNameController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Rian & Nisa / Ibu Rina',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama client wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Nomor HP Client (WhatsApp)
              const Text(
                'Nomor HP / WA Client *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _clientPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Contoh: 08123456789',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nomor HP client wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Nama di Backdrop
              const Text(
                'Nama di Backdrop (Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _backdropTitleController,
                decoration: InputDecoration(
                  hintText: 'Contoh: The Engagement of Rian & Nisa',
                  prefixIcon: const Icon(Icons.title),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 14),

              // 3. Tanggal dan Jam Acara
              const Text(
                'Tanggal & Jam Acara (Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 18, color: AppTheme.primaryGold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Pilih Tanggal'
                                    : DateFormat('dd MMM yyyy', 'id_ID')
                                        .format(_selectedDate!),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedDate == null
                                      ? AppTheme.textLight
                                      : AppTheme.textDark,
                                  fontWeight: _selectedDate == null
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 18, color: AppTheme.primaryGold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTime == null
                                    ? 'Pilih Jam'
                                    : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')} WIB',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedTime == null
                                      ? AppTheme.textLight
                                      : AppTheme.textDark,
                                  fontWeight: _selectedTime == null
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Link Maps Google Maps
              const Text(
                'Link Google Maps Lokasi (Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _mapsUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://maps.google.com/?q=...',
                  prefixIcon: const Icon(Icons.map_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 14),

              // 5. Paket yang dipilih (Master Paket)
              const Text(
                'Pilih Paket Dekorasi (Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _openPackagePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(
                      color: _selectedPackage != null
                          ? AppTheme.primaryGold
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          color: AppTheme.primaryGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedPackage == null
                            ? const Text(
                                'Ketuk untuk pilih paket dekorasi',
                                style: TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 13,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedPackage!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(_selectedPackage!.basePrice),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primaryGold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: _selectedPackage != null
                            ? AppTheme.primaryGold
                            : AppTheme.textLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 6. Model Dekorasi yang dipilih (Master Model Dekorasi)
              const Text(
                'Pilih Model Dekorasi (Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _openModelPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(
                      color: _selectedModel != null
                          ? AppTheme.primaryGold
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _selectedModel != null && _selectedModel!.imageUrl.isNotEmpty
                            ? Image.network(
                                _selectedModel!.imageUrl,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 38,
                                  height: 38,
                                  color: AppTheme.primaryGold.withValues(alpha: 0.1),
                                  child: const Icon(Icons.view_carousel, color: AppTheme.primaryGold, size: 20),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.view_carousel, color: AppTheme.primaryGold, size: 20),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedModel == null
                            ? const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ketuk untuk pilih model dekorasi',
                                    style: TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tersedia model & ukuran lebar backdrop',
                                    style: TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedModel!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (_selectedModel!.width.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGold.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Lebar: ${_selectedModel!.width}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.primaryGold,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        _selectedModelAdditionalPrice > 0
                                            ? '+${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_selectedModelAdditionalPrice)}'
                                            : 'Tanpa Biaya Tambahan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _selectedModelAdditionalPrice > 0 ? AppTheme.primaryGold : AppTheme.successGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      if (_selectedModel != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.errorRed),
                          onPressed: () {
                            setState(() {
                              _selectedModel = null;
                              _selectedModelAdditionalPrice = 0.0;
                            });
                          },
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          color: _selectedModel != null
                              ? AppTheme.primaryGold
                              : AppTheme.textLight,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 7. Item Tambahan (Addon)
              const Text(
                'Pilih Item Tambahan / Addon (Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _openAddonPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(
                      color: _selectedAddons.isNotEmpty
                          ? AppTheme.primaryGold
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart,
                          color: AppTheme.primaryGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedAddons.isEmpty
                            ? const Text(
                                'Ketuk untuk pilih item tambahan',
                                style: TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 13,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedAddons.fold<int>(0, (sum, i) => sum + i.quantity)} item tambahan (${_selectedAddons.length} jenis)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedAddons.map((i) => '${i.addon.name} (x${i.quantity})').join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(
                                      _selectedAddons.fold<double>(
                                        0.0,
                                        (sum, item) => sum + item.totalPrice,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primaryGold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: _selectedAddons.isNotEmpty
                            ? AppTheme.primaryGold
                            : AppTheme.textLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Catatan tambahan
              const Text(
                'Catatan / Request Tambahan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Misal: Tema warna sage green, loading barang H-1...',
                  prefixIcon: const Icon(Icons.edit_note),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined),
                          SizedBox(width: 8),
                          Text(
                            'Simpan Agenda',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
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
