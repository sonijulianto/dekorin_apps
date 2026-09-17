import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';

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
  String? _selectedPackageId;
  bool _isLoading = false;

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
      await agendaService.createAgenda(
        clientName: _clientNameController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        backdropTitle: _backdropTitleController.text.trim(),
        eventDateTime: eventDateTime,
        mapsUrl: _mapsUrlController.text.trim(),
        packageId: _selectedPackageId ?? '',
        notes: _notesController.text.trim(),
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
    final packagesAsync = ref.watch(packagesProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
              packagesAsync.when(
                data: (packages) {
                  return DropdownButtonFormField<String>(
                    value: _selectedPackageId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.card_giftcard),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    hint: const Text('Pilih paket master dekorasi'),
                    items: packages.map((pkg) {
                      return DropdownMenuItem<String>(
                        value: pkg.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              pkg.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              currencyFormatter.format(pkg.basePrice),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryGold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPackageId = value;
                      });
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Text(
                  'Gagal memuat master paket: $e',
                  style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
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
