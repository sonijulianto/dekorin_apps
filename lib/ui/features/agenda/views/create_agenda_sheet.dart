import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/data/services/form_config_service.dart';
import 'package:dekorin_apps/data/services/property_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';
import 'package:dekorin_apps/domain/models/form_config.dart';
import 'package:dekorin_apps/ui/core/widgets/contact_picker_action.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/views/addon_picker_screen.dart';
import 'package:dekorin_apps/ui/features/agenda/views/model_picker_screen.dart';
import 'package:dekorin_apps/ui/features/agenda/views/package_picker_screen.dart';
import 'package:dekorin_apps/ui/features/agenda/views/place_search_modal.dart';
import 'package:dekorin_apps/ui/features/agenda/widgets/agenda_pricing_widgets.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class CreateAgendaSheet extends ConsumerStatefulWidget {
  const CreateAgendaSheet({super.key, this.initialDate});

  final DateTime? initialDate;

  /// Combines selected date and optional time without dropping selectedDate
  /// when the user leaves the time picker untouched (defaults to 10:00).
  static DateTime? resolveEventDateTime(
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
  ) {
    if (selectedDate == null) return null;
    final effectiveTime = selectedTime ?? const TimeOfDay(hour: 10, minute: 0);
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      effectiveTime.hour,
      effectiveTime.minute,
    );
  }

  @override
  ConsumerState<CreateAgendaSheet> createState() => _CreateAgendaSheetState();
}

class _CreateAgendaSheetState extends ConsumerState<CreateAgendaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameFieldKey = GlobalKey<FormFieldState<String>>();
  final _clientPhoneFieldKey = GlobalKey<FormFieldState<String>>();

  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _backdropTitleController = TextEditingController();
  final _eventAddressController = TextEditingController();
  final _mapsUrlController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController();
  final _transportFeeController = TextEditingController();
  final _dpAmountController = TextEditingController();

  String _discountType = 'amount';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedBrandId = '';
  String _selectedEventType = '';
  String _selectedEventLabel = 'Umum (Default)';
  List<FormTemplateSummary> _templates = FormTemplateSummary.builtInDefaults;
  DecorationPackage? _selectedPackage;
  DecorationModel? _selectedModel;
  double _selectedModelAdditionalPrice = 0.0;
  List<SelectedAddonItem> _selectedAddons = [];
  bool _isLoading = false;
  bool _isOpeningPicker = false;
  bool _isPickingContact = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEventTemplates();
    });
  }

  Future<void> _loadEventTemplates() async {
    final list = await ref.read(formConfigServiceProvider).getFormTemplates(brandId: _selectedBrandId);
    if (!mounted) return;
    setState(() {
      _templates = list;
      if (!_templates.any((t) => t.eventType == _selectedEventType)) {
        _selectedEventType = '';
        _selectedEventLabel = 'Umum (Default)';
      } else {
        _selectedEventLabel = _templates.firstWhere((t) => t.eventType == _selectedEventType).eventLabel;
      }
    });
  }

  String get _backdropHintText {
    switch (_selectedEventType) {
      case 'wedding':
        return 'Contoh: The Wedding of Rian & Nisa';
      case 'lamaran':
        return 'Contoh: The Engagement of Rian & Nisa';
      case 'birthday':
        return 'Contoh: Happy 5th Birthday Kenzo';
      case 'aqiqah':
        return 'Contoh: Tasyakuran Aqiqah Baby Arsyil';
      default:
        return 'Contoh: The Engagement of Rian & Nisa';
    }
  }

  double get _currentDecorSubtotal {
    final packagePrice = _selectedPackage?.basePrice ?? 0.0;
    final addonsPrice = _selectedAddons.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
    return packagePrice + _selectedModelAdditionalPrice + addonsPrice;
  }

  double get _currentDiscountValue => parseAgendaDiscountInput(_discountController.text, _discountType);
  double get _currentTransportFee => parseAgendaCurrencyInput(_transportFeeController.text);
  double get _currentDpAmount => parseAgendaCurrencyInput(_dpAmountController.text);

  String _resolveBrandLabel(List<CompanyBrand> brands, String mainCompanyName) {
    if (_selectedBrandId.isEmpty) {
      return mainCompanyName.isNotEmpty ? mainCompanyName : 'Brand Utama';
    }
    final found = brands.where((b) => b.id == _selectedBrandId);
    return found.isNotEmpty ? found.first.name : 'Brand Utama';
  }

  Future<void> _pickContactPhone() async {
    if (_isPickingContact) return;
    setState(() => _isPickingContact = true);
    try {
      await pickClientContactIntoFields(
        context: context,
        ref: ref,
        phoneController: _clientPhoneController,
        phoneFieldKey: _clientPhoneFieldKey,
        nameController: _clientNameController,
        nameFieldKey: _clientNameFieldKey,
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingContact = false);
      }
    }
  }

  Future<void> _searchGoogleMaps() async {
    final initial = _mapsUrlController.text.trim().isNotEmpty
        ? _mapsUrlController.text.trim()
        : _eventAddressController.text.trim();

    final result = await PlaceSearchModal.show(context, initialQuery: initial);
    if (result != null) {
      setState(() {
        _eventAddressController.text = result.fullAddress;
        _mapsUrlController.text = result.mapsUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi "${result.name}" berhasil dipilih!',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _syncSelectedModelPrice() {
    if (_selectedModel == null) {
      _selectedModelAdditionalPrice = 0.0;
      return;
    }
    if (_selectedPackage == null) {
      _selectedModelAdditionalPrice = _selectedModel!.price;
    } else {
      final matchingPm = _selectedPackage!.packageModels
          .where((pm) => pm.decorationModelId == _selectedModel!.id)
          .firstOrNull;
      _selectedModelAdditionalPrice = matchingPm?.additionalPrice ?? 0.0;
    }
  }

  Future<void> _openPackagePicker(String brandLabel) async {
    if (_isOpeningPicker) return;
    _isOpeningPicker = true;
    try {
      final result = await Navigator.of(context).push<DecorationPackage>(
        MaterialPageRoute(
          builder: (_) => PackagePickerScreen(
            selectedPackageId: _selectedPackage?.id,
            brandId: _selectedBrandId,
            brandName: brandLabel,
          ),
        ),
      );
      if (result != null && mounted) {
        setState(() {
          _selectedPackage = result;
          _syncSelectedModelPrice();
        });
      }
    } finally {
      _isOpeningPicker = false;
    }
  }

  List<String> _modelStockWarnings = [];

  Future<void> _checkStockAvailabilityForModel(DecorationModel model, DateTime eventDate) async {
    try {
      final availabilities = await ref.read(propertyServiceProvider).getPropertiesAvailability(eventDate);
      final availMap = {for (var a in availabilities) a.property.id: a};

      final warnings = <String>[];
      for (final mp in model.modelProperties) {
        final avail = availMap[mp.propertyId];
        if (avail != null && avail.property.trackStock) {
          if (mp.defaultQty > avail.availableQty) {
            warnings.add(
              '${avail.property.name} (Tersisa: ${avail.availableQty}, Dibutuhkan: ${mp.defaultQty})',
            );
          }
        }
      }

      setState(() {
        _modelStockWarnings = warnings;
      });

      if (warnings.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text('Peringatan Stok Properti', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Untuk tanggal ${DateFormat("d MMMM yyyy", "id_ID").format(eventDate)}, beberapa properti bawaan model ini sedang terpakai di agenda lain:',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 10),
                ...warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Colors.red)),
                          Expanded(
                            child: Text(w, style: AppTypography.caption.copyWith(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
                Text(
                  'Model tetap dapat dipilih, barang akan tetap dimasukkan ke Pick List namun pastikan menyediakan solusi sewa/cadangan.',
                  style: AppTypography.caption.copyWith(color: AppTheme.textLight),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.white),
                child: Text('Mengerti', style: AppTypography.button),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      // Abaikan jika network error saat background availability check
    }
  }

  Future<void> _openModelPicker(String brandLabel) async {
    if (_isOpeningPicker) return;
    _isOpeningPicker = true;
    try {
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
      if (result != null && mounted) {
        setState(() {
          if (result.isCleared) {
            _selectedModel = null;
            _selectedModelAdditionalPrice = 0.0;
            _modelStockWarnings = [];
          } else {
            _selectedModel = result.model;
            _selectedModelAdditionalPrice = result.additionalPrice;
            _modelStockWarnings = [];
          }
        });

        if (_selectedModel != null && _selectedDate != null) {
          _checkStockAvailabilityForModel(_selectedModel!, _selectedDate!);
        }
      }
    } finally {
      _isOpeningPicker = false;
    }
  }

  Future<void> _openAddonPicker() async {
    if (_isOpeningPicker) return;
    _isOpeningPicker = true;
    try {
      final result = await Navigator.of(context).push<List<SelectedAddonItem>>(
        MaterialPageRoute(builder: (_) => AddonPickerScreen(initiallySelectedAddons: _selectedAddons)),
      );
      if (result != null && mounted) {
        setState(() => _selectedAddons = result);
      }
    } finally {
      _isOpeningPicker = false;
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _backdropTitleController.dispose();
    _eventAddressController.dispose();
    _mapsUrlController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _transportFeeController.dispose();
    _dpAmountController.dispose();
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
      if (_selectedModel != null) {
        _checkStockAvailabilityForModel(_selectedModel!, pickedDate);
      }
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
            'Mohon lengkapi data wajib dan periksa kembali isian formulir',
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

    final DateTime? eventDateTime = CreateAgendaSheet.resolveEventDateTime(
      _selectedDate,
      _selectedTime,
    );

    try {
      final agendaService = ref.read(agendaServiceProvider);

      String combinedNotes = _notesController.text.trim();

      // Tambahkan info Model Dekorasi ke Catatan
      if (_selectedModel != null) {
        final formattedModelPrice = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(_selectedModelAdditionalPrice);
        final String extraText;
        if (_selectedPackage == null) {
          extraText = _selectedModelAdditionalPrice > 0 ? ' ($formattedModelPrice)' : '';
        } else {
          extraText = _selectedModelAdditionalPrice > 0 ? ' (+$formattedModelPrice)' : ' (Termasuk Paket)';
        }
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

      final packageBasePrice = _selectedPackage?.basePrice ?? 0.0;

      String mapsUrl = _mapsUrlController.text.trim();
      if (mapsUrl.isNotEmpty && !mapsUrl.startsWith('http://') && !mapsUrl.startsWith('https://')) {
        mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(mapsUrl)}';
      }

      await agendaService.createAgenda(
        brandId: _selectedBrandId,
        eventType: _selectedEventType,
        eventLabel: _selectedEventLabel,
        clientName: _clientNameController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        backdropTitle: _backdropTitleController.text.trim(),
        eventDateTime: eventDateTime,
        eventAddress: _eventAddressController.text.trim(),
        mapsUrl: mapsUrl,
        packageId: _selectedPackage?.id ?? '',
        packagePrice: packageBasePrice,
        modelId: _selectedModel?.id ?? '',
        modelName: _selectedModel?.name ?? '',
        modelWidth: _selectedModel?.width ?? '',
        modelImageUrl: _selectedModel?.imageUrl ?? '',
        modelAdditionalPrice: _selectedModelAdditionalPrice,
        discountType: _discountType,
        discountValue: _currentDiscountValue,
        transportFee: _currentTransportFee,
        dpAmount: _currentDpAmount,
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
    final brands = brandsAsync.valueOrNull ?? const <CompanyBrand>[];
    final currentUser = ref.watch(globalAuthProvider).value;
    final mainCompanyName = currentUser?.companyName ?? 'Brand Utama';
    final bool canViewPrice = currentUser?.canViewPrice ?? !(currentUser?.isCrew ?? false);
    final selectedBrandLabel = _resolveBrandLabel(brands, mainCompanyName);
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomSafePadding = mediaQuery.padding.bottom;

    final formFieldsColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

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
                            _modelStockWarnings = [];
                          } else {
                            _syncSelectedModelPrice();
                          }
                        });
                        _loadEventTemplates();
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
                              _modelStockWarnings = [];
                            } else {
                              _syncSelectedModelPrice();
                            }
                          });
                          _loadEventTemplates();
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 0B. Pilihan Jenis Acara (Menentukan template form link client)
              Text(
                'Jenis Acara / Template Form',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Menyesuaikan daftar pertanyaan pada form link client (Wedding, Lamaran, Ultah, Aqiqah, atau Custom).',
                style: AppTypography.caption.copyWith(fontSize: 11, color: AppTheme.textLight),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _templates.map((tpl) {
                  final isSelected = _selectedEventType == tpl.eventType;
                  return ChoiceChip(
                    label: Text(
                      tpl.eventLabel,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.textDark,
                    backgroundColor: AppColors.backgroundLight,
                    onSelected: (_) {
                      setState(() {
                        _selectedEventType = tpl.eventType;
                        _selectedEventLabel = tpl.eventLabel;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

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
                key: _clientNameFieldKey,
                controller: _clientNameController,
                style: AppTypography.bodyMedium,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Nomor HP / WA Client *',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ContactPickerChip(
                    onTap: _pickContactPhone,
                    isLoading: _isPickingContact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: _clientPhoneFieldKey,
                controller: _clientPhoneController,
                keyboardType: TextInputType.phone,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Contoh: 08123456789',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/icons/mobile-notch.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(AppTheme.textLight, BlendMode.srcIn),
                    ),
                  ),
                  suffixIcon: kIsWeb
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.contacts_outlined, color: AppTheme.primaryGold, size: 20),
                          tooltip: 'Ambil dari Kontak',
                          onPressed: _isPickingContact ? null : _pickContactPhone,
                        ),
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
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: _backdropHintText,
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

              // 4. Alamat Acara (Opsional)
              Text(
                'Alamat Acara (Opsional)',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _eventAddressController,
                keyboardType: TextInputType.streetAddress,
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Contoh: Gedung Pernikahan Harmoni, Jl. Melati No. 12',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/icons/marker.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(AppTheme.primaryGold, BlendMode.srcIn),
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: AppTheme.primaryGold, size: 20),
                    tooltip: 'Cari Tempat / Venue',
                    onPressed: _searchGoogleMaps,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 14),

              // 5. Link Maps Google Maps
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Link Google Maps Lokasi (Opsional)',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      if (_selectedPackage != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.errorRed),
                          onPressed: () {
                            setState(() {
                              _selectedPackage = null;
                              _syncSelectedModelPrice();
                            });
                          },
                        )
                      else
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textLight,
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
                                      Flexible(
                                        child: Text(
                                          _selectedPackage == null
                                              ? 'Harga Model: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_selectedModelAdditionalPrice)}'
                                              : (_selectedModelAdditionalPrice > 0
                                                  ? '+${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_selectedModelAdditionalPrice)}'
                                                  : 'Tanpa Biaya Tambahan'),
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 11,
                                            color: (_selectedPackage == null || _selectedModelAdditionalPrice > 0)
                                                ? AppTheme.primaryGold
                                                : AppTheme.successGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                              _modelStockWarnings = [];
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
              if (_selectedModel != null && _modelStockWarnings.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_modelStockWarnings.length} properti stoknya terbatas di tanggal ini',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

              // Penyesuaian Harga & Pembayaran (Diskon, Transport & DP)
              if (canViewPrice) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diskon, Transport & DP (Opsional)',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AgendaDiscountInputField(
                        discountType: _discountType,
                        controller: _discountController,
                        decorSubtotal: _currentDecorSubtotal,
                        fillColor: Colors.white,
                        onTypeChanged: (nextType) {
                          setState(() {
                            if (_discountType != nextType) {
                              _discountType = nextType;
                              _discountController.clear();
                            }
                          });
                        },
                        onValueChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      AgendaCurrencyInputField(
                        label: 'Ongkos Kirim / Uang Transport',
                        controller: _transportFeeController,
                        svgIconPath: 'assets/icons/shipping-fast.svg',
                        fillColor: Colors.white,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      AgendaCurrencyInputField(
                        label: 'Nominal DP Masuk',
                        controller: _dpAmountController,
                        svgIconPath: 'assets/icons/wallet-income.svg',
                        fillColor: Colors.white,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

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
              if (canViewPrice &&
                  (_selectedPackage != null ||
                      _selectedModel != null ||
                      _selectedAddons.isNotEmpty ||
                      _currentTransportFee > 0 ||
                      _currentDiscountValue > 0 ||
                      _currentDpAmount > 0)) ...[
                const SizedBox(height: 16),
                _buildEstimatedCostSummary(),
              ],
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
    );

    return PopScope(
      canPop: !_isLoading,
      child: SafeArea(
        top: true,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight;
            final double? maxSheetHeight;
            if (hasBoundedHeight) {
              final baseMaxHeight = constraints.maxHeight * 0.90;
              maxSheetHeight = (baseMaxHeight - bottomInset) < 220
                  ? math.min(constraints.maxHeight, bottomInset + 220)
                  : baseMaxHeight;
            } else {
              maxSheetHeight = null;
            }
            final contentBottomPadding = bottomInset > 0 ? 20.0 : bottomSafePadding + 24.0;

            return Container(
              constraints: maxSheetHeight != null ? BoxConstraints(maxHeight: maxSheetHeight) : null,
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context),
                    Divider(height: 1, color: Colors.grey.shade200),
                    if (hasBoundedHeight)
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, contentBottomPadding),
                          child: formFieldsColumn,
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, contentBottomPadding),
                        child: formFieldsColumn,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar dipin di luar area scroll agar mudah di-drag ke bawah
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
          const SizedBox(height: 14),
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
              Expanded(
                child: Column(
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
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Tutup',
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.goldLight,
                  foregroundColor: AppTheme.textDark,
                  minimumSize: const Size(36, 36),
                ),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedCostSummary() {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final packagePrice = _selectedPackage?.basePrice ?? 0.0;
    final addonsPrice = _selectedAddons.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
    final lines = <AgendaSummaryLine>[
      if (_selectedPackage != null)
        AgendaSummaryLine(
          label: 'Paket: ${_selectedPackage!.name}',
          amountText: currencyFormatter.format(packagePrice),
        ),
      if (_selectedModel != null && (_selectedPackage == null || _selectedModelAdditionalPrice > 0))
        AgendaSummaryLine(
          label: _selectedPackage == null
              ? 'Model: ${_selectedModel!.name}'
              : 'Tambahan Model (${_selectedModel!.name})',
          amountText: _selectedPackage == null
              ? currencyFormatter.format(_selectedModelAdditionalPrice)
              : '+${currencyFormatter.format(_selectedModelAdditionalPrice)}',
        ),
      if (addonsPrice > 0)
        AgendaSummaryLine(
          label: 'Item Tambahan (${_selectedAddons.length} jenis)',
          amountText: '+${currencyFormatter.format(addonsPrice)}',
        ),
    ];

    return AgendaPricingSummaryBlock(
      title: 'Estimasi Biaya & Pembayaran',
      totalLabel: 'TOTAL TAGIHAN',
      lines: lines,
      decorSubtotal: _currentDecorSubtotal,
      discountType: _discountType,
      discountValue: _currentDiscountValue,
      transportFee: _currentTransportFee,
      dpAmount: _currentDpAmount,
      showPaymentDetails: _currentDpAmount > 0,
    );
  }
}
