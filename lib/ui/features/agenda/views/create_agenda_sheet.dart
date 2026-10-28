import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/views/addon_picker_screen.dart';
import 'package:dekorin_apps/ui/features/agenda/views/model_picker_screen.dart';
import 'package:dekorin_apps/ui/features/agenda/views/package_picker_screen.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

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
  String _selectedBrandId = '';
  DecorationPackage? _selectedPackage;
  DecorationModel? _selectedModel;
  double _selectedModelAdditionalPrice = 0.0;
  List<SelectedAddonItem> _selectedAddons = [];
  bool _isLoading = false;

  String _resolveBrandLabel(List<CompanyBrand> brands, String mainCompanyName) {
    if (_selectedBrandId.isEmpty) {
      return mainCompanyName.isNotEmpty ? mainCompanyName : 'Brand Utama';
    }
    final found = brands.where((b) => b.id == _selectedBrandId);
    return found.isNotEmpty ? found.first.name : 'Brand Utama';
  }

  Future<void> _searchGoogleMaps() async {
    String query = _mapsUrlController.text.trim();
    if (query.isEmpty) {
      final searchResult = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final tempController = TextEditingController();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Image.asset('assets/icons/google-maps-icon.webp', width: 22, height: 22),
                const SizedBox(width: 8),
                Text(
                  'Cari Lokasi di Maps',
                  style: AppTypography.titleMedium.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ketik nama gedung, hotel, venue, atau alamat acara:',
                  style: AppTypography.bodySmall.copyWith(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tempController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Gedung Serbaguna Puri Begawan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: AppTypography.bodyMedium.copyWith(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, tempController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Buka Google Maps', style: AppTypography.button),
              ),
            ],
          );
        },
      );

      if (searchResult == null || searchResult.isEmpty) return;
      query = searchResult;
    }

    Uri url;
    if (query.startsWith('http://') || query.startsWith('https://')) {
      url = Uri.parse(query);
    } else {
      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
      _mapsUrlController.text = mapsUrl;
      url = Uri.parse(mapsUrl);
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuka Google Maps: $e',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openPackagePicker(String brandLabel) async {
    final result = await Navigator.of(context).push<DecorationPackage>(
      MaterialPageRoute(
        builder: (_) => PackagePickerScreen(
          selectedPackageId: _selectedPackage?.id,
          brandId: _selectedBrandId,
          brandName: brandLabel,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedPackage = result;
        // Sinkronkan harga tambahan jika model sudah pernah dipilih
        if (_selectedModel != null) {
          final matchingPm = result.packageModels.where((pm) => pm.decorationModelId == _selectedModel!.id).firstOrNull;
          if (matchingPm != null) {
            _selectedModelAdditionalPrice = matchingPm.additionalPrice;
          } else {
            _selectedModelAdditionalPrice = 0.0;
          }
        }
      });
    }
  }

  Future<void> _openModelPicker(String brandLabel) async {
    final result = await Navigator.of(context).push<SelectedModelResult>(
      MaterialPageRoute(
        builder: (_) => ModelPickerScreen(
          package: _selectedPackage,
          selectedModelId: _selectedModel?.id,
          canClearModel: _selectedModel != null,
          brandId: _selectedBrandId,
          brandName: brandLabel,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (result.isCleared) {
          _selectedModel = null;
          _selectedModelAdditionalPrice = 0.0;
        } else {
          _selectedModel = result.model;
          _selectedModelAdditionalPrice = result.additionalPrice;
        }
      });
    }
  }

  Future<void> _openAddonPicker() async {
    final result = await Navigator.of(context).push<List<SelectedAddonItem>>(
      MaterialPageRoute(builder: (_) => AddonPickerScreen(initiallySelectedAddons: _selectedAddons)),
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
        SnackBar(
          content: Text(
            'Mohon isi Nama Client dan Nomor HP terlebih dahulu',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
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
        final modelText =
            '[Model Dekorasi]: ${_selectedModel!.name}${_selectedModel!.width.isNotEmpty ? ' (Lebar: ${_selectedModel!.width})' : ''}$extraText';
        if (combinedNotes.isNotEmpty) {
          combinedNotes = '$combinedNotes\n\n$modelText';
        } else {
          combinedNotes = modelText;
        }
      }

      if (_selectedAddons.isNotEmpty) {
        final addonNames = _selectedAddons
            .map((item) {
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
            })
            .join('\n');

        final addonText = '[Item Tambahan / Addon]:\n$addonNames';
        if (combinedNotes.isNotEmpty) {
          combinedNotes = '$combinedNotes\n\n$addonText';
        } else {
          combinedNotes = addonText;
        }
      }

      final effectivePackagePrice = (_selectedPackage?.basePrice ?? 0.0) + _selectedModelAdditionalPrice;

      String mapsUrl = _mapsUrlController.text.trim();
      if (mapsUrl.isNotEmpty && !mapsUrl.startsWith('http://') && !mapsUrl.startsWith('https://')) {
        mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(mapsUrl)}';
      }

      await agendaService.createAgenda(
        brandId: _selectedBrandId,
        clientName: _clientNameController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        backdropTitle: _backdropTitleController.text.trim(),
        eventDateTime: eventDateTime,
        mapsUrl: mapsUrl,
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
          SnackBar(
            content: Text(
              'Agenda berhasil ditambahkan! 🎉',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan agenda: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
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
    final brandsAsync = ref.watch(companyBrandsProvider);
    final brands = brandsAsync.value ?? const <CompanyBrand>[];
    final mainCompanyName = ref.watch(globalAuthProvider).value?.companyName ?? 'Brand Utama';
    final selectedBrandLabel = _resolveBrandLabel(brands, mainCompanyName);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
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
                    child: SvgPicture.asset(
                      'assets/icons/calendar.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(AppTheme.primaryGold, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat Agenda Baru',
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Wajib isi Nama Client. Detail lain dapat diisi oleh client via Web Form.',
                        style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 0. Pilihan Brand Usaha (Muncul jika punya Sub-Brand)
              if (brands.isNotEmpty) ...[
                Text(
                  'Pilih Brand Usaha *',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Menentukan nama & logo invoice serta daftar Paket & Model yang tampil.',
                  style: AppTypography.caption.copyWith(fontSize: 11, color: AppTheme.textLight),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(
                        mainCompanyName.isNotEmpty ? '$mainCompanyName (Utama)' : 'Brand Utama',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _selectedBrandId.isEmpty ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      selected: _selectedBrandId.isEmpty,
                      selectedColor: AppTheme.primaryGold,
                      backgroundColor: AppColors.goldLight,
                      onSelected: (_) {
                        setState(() {
                          _selectedBrandId = '';
                          if (_selectedPackage != null && _selectedPackage!.brandId.isNotEmpty) {
                            _selectedPackage = null;
                          }
                          if (_selectedModel != null && _selectedModel!.brandId.isNotEmpty) {
                            _selectedModel = null;
                            _selectedModelAdditionalPrice = 0.0;
                          }
                        });
                      },
                    ),
                    ...brands.map((b) {
                      final isSelected = _selectedBrandId == b.id;
                      return ChoiceChip(
                        label: Text(
                          b.name,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryGold,
                        backgroundColor: AppColors.goldLight,
                        onSelected: (_) {
                          setState(() {
                            _selectedBrandId = b.id;
                            if (_selectedPackage != null && _selectedPackage!.brandId != b.id) {
                              _selectedPackage = null;
                            }
                            if (_selectedModel != null && _selectedModel!.brandId != b.id) {
                              _selectedModel = null;
                              _selectedModelAdditionalPrice = 0.0;
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 1. Nama Client
              Text(
                'Nama Client *',
                style: AppTypography.titleSmall.copyWith(
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
              Text(
                'Nomor HP / WA Client *',
                style: AppTypography.titleSmall.copyWith(
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
              Text(
                'Nama di Backdrop (Opsional)',
                style: AppTypography.titleSmall.copyWith(
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
              Text(
                'Tanggal & Jam Acara (Opsional)',
                style: AppTypography.titleSmall.copyWith(
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/calendar.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(AppTheme.primaryGold, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Pilih Tanggal'
                                    : DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate!),
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 13,
                                  color: _selectedDate == null ? AppTheme.textLight : AppTheme.textDark,
                                  fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w600,
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 18, color: AppTheme.primaryGold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTime == null
                                    ? 'Pilih Jam'
                                    : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')} WIB',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 13,
                                  color: _selectedTime == null ? AppTheme.textLight : AppTheme.textDark,
                                  fontWeight: _selectedTime == null ? FontWeight.normal : FontWeight.w600,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Link Google Maps Lokasi (Opsional)',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  InkWell(
                    onTap: _searchGoogleMaps,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/icons/google-maps-icon.webp', width: 14, height: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Cari di Maps',
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _mapsUrlController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Tempel link atau ketik nama gedung/lokasi...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset('assets/icons/google-maps-icon.webp', width: 20, height: 20),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: AppTheme.primaryGold, size: 20),
                    tooltip: 'Cari di Google Maps',
                    onPressed: _searchGoogleMaps,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bisa langsung ketik nama gedung/tempat, lalu tekan "Cari di Maps".',
                style: AppTypography.caption.copyWith(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 14),

              // 5. Paket yang dipilih (Master Paket)
              Text(
                'Pilih Paket Dekorasi (Opsional)',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _openPackagePicker(selectedBrandLabel),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: _selectedPackage != null ? AppTheme.primaryGold : Colors.grey.shade300),
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
                        child: const Icon(Icons.card_giftcard, color: AppTheme.primaryGold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedPackage == null
                            ? Text(
                                'Ketuk untuk pilih paket dekorasi',
                                style: AppTypography.bodyMedium.copyWith(color: AppTheme.textLight, fontSize: 13),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedPackage!.name,
                                    style: AppTypography.labelLarge.copyWith(
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
                                    style: AppTypography.caption.copyWith(
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
                        color: _selectedPackage != null ? AppTheme.primaryGold : AppTheme.textLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 6. Model Dekorasi yang dipilih (Master Model Dekorasi)
              Text(
                'Pilih Model Dekorasi (Opsional)',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _openModelPicker(selectedBrandLabel),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: _selectedModel != null ? AppTheme.primaryGold : Colors.grey.shade300),
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
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ketuk untuk pilih model dekorasi',
                                    style: AppTypography.bodyMedium.copyWith(color: AppTheme.textLight, fontSize: 13),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tersedia model & ukuran lebar backdrop',
                                    style: AppTypography.caption.copyWith(color: AppTheme.textLight, fontSize: 11),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedModel!.name,
                                    style: AppTypography.labelLarge.copyWith(
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
                                            style: AppTypography.caption.copyWith(
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
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 11,
                                          color: _selectedModelAdditionalPrice > 0
                                              ? AppTheme.primaryGold
                                              : AppTheme.successGreen,
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
                          color: _selectedModel != null ? AppTheme.primaryGold : AppTheme.textLight,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 7. Item Tambahan (Addon)
              Text(
                'Pilih Item Tambahan / Addon (Opsional)',
                style: AppTypography.titleSmall.copyWith(
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
                    border: Border.all(color: _selectedAddons.isNotEmpty ? AppTheme.primaryGold : Colors.grey.shade300),
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
                        child: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryGold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedAddons.isEmpty
                            ? Text(
                                'Ketuk untuk pilih item tambahan',
                                style: AppTypography.bodyMedium.copyWith(color: AppTheme.textLight, fontSize: 13),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedAddons.fold<int>(0, (sum, i) => sum + i.quantity)} item tambahan (${_selectedAddons.length} jenis)',
                                    style: AppTypography.labelLarge.copyWith(
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
                                    style: AppTypography.caption.copyWith(fontSize: 11, color: AppTheme.textLight),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(_selectedAddons.fold<double>(0.0, (sum, item) => sum + item.totalPrice)),
                                    style: AppTypography.caption.copyWith(
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
                        color: _selectedAddons.isNotEmpty ? AppTheme.primaryGold : AppTheme.textLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Catatan tambahan
              Text(
                'Catatan / Request Tambahan',
                style: AppTypography.titleSmall.copyWith(
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
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/icons/edit.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(AppTheme.textLight, BlendMode.srcIn),
                    ),
                  ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined),
                          SizedBox(width: 8),
                          Text(
                            'Simpan Agenda',
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
