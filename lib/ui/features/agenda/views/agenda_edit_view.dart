import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/decoration_addon.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';
import 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_calendar_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/views/addon_picker_screen.dart';
import 'package:dekorin_apps/ui/features/agenda/views/model_picker_screen.dart';
import 'package:dekorin_apps/ui/features/agenda/views/package_picker_screen.dart';
import 'package:dekorin_apps/ui/features/agenda/views/place_search_modal.dart';
import 'package:dekorin_apps/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

/// Screen form khusus untuk mengedit seluruh informasi agenda acara secara terstruktur.
class AgendaEditView extends ConsumerStatefulWidget {
  const AgendaEditView({super.key, required this.item});

  final AgendaItem item;

  @override
  ConsumerState<AgendaEditView> createState() => _AgendaEditViewState();
}

class _AgendaEditViewState extends ConsumerState<AgendaEditView> {
  final _formKey = GlobalKey<FormState>();

  late String _brandId;
  late TextEditingController _clientNameController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _backdropTitleController;
  late TextEditingController _eventAddressController;
  late TextEditingController _mapsUrlController;
  late TextEditingController _notesController;

  late DateTime _selectedDateTime;
  late String _packageId;
  late String _packageName;
  late TextEditingController _packagePriceController;

  late String _modelId;
  late String _modelName;
  late String _modelWidth;
  late String _modelImageUrl;
  late double _modelAdditionalPrice;

  List<SelectedAddonItem> _selectedAddons = [];

  late TextEditingController _transportFeeController;
  late TextEditingController _dpAmountController;
  late String _paymentStatus;
  late String _status;

  bool _isSaving = false;

  final _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _thousandFormatter = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _brandId = item.brandId;
    _clientNameController = TextEditingController(text: item.clientName);
    _clientPhoneController = TextEditingController(text: item.clientPhone);
    _backdropTitleController = TextEditingController(text: item.backdropTitle);
    _eventAddressController = TextEditingController(text: item.displayAddress);
    _mapsUrlController = TextEditingController(text: item.mapsUrl);

    // Parsing Addon dari notes jika ada
    const addonTag = '[Item Tambahan / Addon]:';
    String userNotes = item.notes;
    List<SelectedAddonItem> initialAddons = [];

    if (item.notes.contains(addonTag)) {
      final parts = item.notes.split(addonTag);
      userNotes = parts[0].trim();
      if (parts.length > 1) {
        final lines = parts[1].trim().split('\n');
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;
          if (line.startsWith('- ')) line = line.substring(2).trim();

          int qty = 1;
          final qtyMatch = RegExp(r'x(\d+)', caseSensitive: false).firstMatch(line);
          if (qtyMatch != null) {
            qty = int.tryParse(qtyMatch.group(1)!) ?? 1;
          }

          double unitPrice = 0.0;
          String itemName = line;

          if (line.contains('(') && line.contains(')')) {
            final openIdx = line.indexOf('(');
            final closeIdx = line.lastIndexOf(')');
            itemName = line.substring(0, openIdx).trim();
            final pricePart = line.substring(openIdx + 1, closeIdx).trim();

            if (pricePart.contains('=')) {
              final eqParts = pricePart.split('=');
              unitPrice = double.tryParse(eqParts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
            } else {
              unitPrice = double.tryParse(pricePart.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
            }
          }

          itemName = itemName.replaceAll(RegExp(r'\s+x\d+$', caseSensitive: false), '').trim();
          initialAddons.add(SelectedAddonItem(
            addon: DecorationAddon(id: itemName, name: itemName, price: unitPrice),
            quantity: qty,
          ));
        }
      }
    }

    _notesController = TextEditingController(text: userNotes);
    _selectedAddons = initialAddons;

    _selectedDateTime = item.eventDateTime;
    _packageId = item.packageId;
    _packageName = item.packageName;

    final initialPkgPrice = item.packagePrice > 0 ? _thousandFormatter.format(item.packagePrice.toInt()).replaceAll(',', '.') : '';
    _packagePriceController = TextEditingController(text: initialPkgPrice);

    _modelId = item.modelId;
    _modelName = item.modelName;
    _modelWidth = item.modelWidth;
    _modelImageUrl = item.modelImageUrl;
    _modelAdditionalPrice = item.modelAdditionalPrice;

    final initialTransport = item.transportFee > 0 ? _thousandFormatter.format(item.transportFee.toInt()).replaceAll(',', '.') : '';
    _transportFeeController = TextEditingController(text: initialTransport);

    final initialDp = item.dpAmount > 0 ? _thousandFormatter.format(item.dpAmount.toInt()).replaceAll(',', '.') : '';
    _dpAmountController = TextEditingController(text: initialDp);

    _paymentStatus = item.paymentStatus.isNotEmpty ? item.paymentStatus : 'unpaid';
    _status = item.status.isNotEmpty ? item.status : 'upcoming';
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _backdropTitleController.dispose();
    _eventAddressController.dispose();
    _mapsUrlController.dispose();
    _notesController.dispose();
    _packagePriceController.dispose();
    _transportFeeController.dispose();
    _dpAmountController.dispose();
    super.dispose();
  }

  double _parseFormattedNumber(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGold,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final initialTime = TimeOfDay(hour: _selectedDateTime.hour, minute: _selectedDateTime.minute);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGold,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
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

  Future<void> _openPackagePicker(String brandLabel) async {
    final result = await Navigator.of(context).push<DecorationPackage>(
      MaterialPageRoute(
        builder: (_) => PackagePickerScreen(
          selectedPackageId: _packageId.isNotEmpty ? _packageId : null,
          brandId: _brandId,
          brandName: brandLabel,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _packageId = result.id;
        _packageName = result.name;
        if (result.basePrice > 0) {
          _packagePriceController.text = _thousandFormatter.format(result.basePrice.toInt()).replaceAll(',', '.');
        }

        // Sinkronisasi harga model jika sudah ada model yang dipilih
        if (_modelId.isNotEmpty) {
          final matchingPm = result.packageModels.where((pm) => pm.decorationModelId == _modelId).firstOrNull;
          if (matchingPm != null) {
            _modelAdditionalPrice = matchingPm.additionalPrice;
          } else {
            _modelAdditionalPrice = 0.0;
          }
        }
      });
    }
  }

  Future<void> _openModelPicker(String brandLabel) async {
    final packages = ref.read(packagesProvider).valueOrNull ?? const <DecorationPackage>[];
    DecorationPackage? currentPackage;
    if (_packageId.isNotEmpty) {
      currentPackage = packages.where((p) => p.id == _packageId).firstOrNull;
    }

    final result = await Navigator.of(context).push<SelectedModelResult>(
      MaterialPageRoute(
        builder: (_) => ModelPickerScreen(
          package: currentPackage,
          selectedModelId: _modelId.isNotEmpty ? _modelId : null,
          canClearModel: true,
          brandId: _brandId,
          brandName: brandLabel,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result.isCleared || result.model == null) {
          _modelId = '';
          _modelName = '';
          _modelWidth = '';
          _modelImageUrl = '';
          _modelAdditionalPrice = 0.0;
        } else {
          _modelId = result.model!.id;
          _modelName = result.model!.name;
          _modelWidth = result.model!.width;
          _modelImageUrl = result.model!.imageUrl;
          _modelAdditionalPrice = result.additionalPrice;
        }
      });
    }
  }

  Future<void> _openAddonPicker() async {
    final masterAddons = ref.read(addonsProvider).valueOrNull ?? [];
    // Rekonsiliasi addon yang sudah ada agar objek cocok dengan master data
    final reconciledAddons = _selectedAddons.map((sel) {
      final found = masterAddons.where((m) => m.name.toLowerCase() == sel.addon.name.toLowerCase()).firstOrNull;
      if (found != null) {
        return SelectedAddonItem(addon: found, quantity: sel.quantity);
      }
      return sel;
    }).toList();

    final result = await Navigator.of(context).push<List<SelectedAddonItem>>(
      MaterialPageRoute(
        builder: (_) => AddonPickerScreen(initiallySelectedAddons: reconciledAddons),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAddons = result;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double packagePrice = _parseFormattedNumber(_packagePriceController.text);
      final double transportFee = _parseFormattedNumber(_transportFeeController.text);
      final double dpAmount = _parseFormattedNumber(_dpAmountController.text);

      // Susun notes baru yang menggabungkan catatan teks dan blok [Item Tambahan / Addon]
      String finalNotes = _notesController.text.trim();
      if (_selectedAddons.isNotEmpty) {
        final addonLines = _selectedAddons.map((item) {
          final unitPriceFormatted = 'Rp ${_thousandFormatter.format(item.addon.price.toInt()).replaceAll(',', '.')}';
          if (item.quantity > 1) {
            final totalPriceFormatted = 'Rp ${_thousandFormatter.format(item.totalPrice.toInt()).replaceAll(',', '.')}';
            return '- ${item.addon.name} x${item.quantity} ($unitPriceFormatted/unit = $totalPriceFormatted)';
          }
          return '- ${item.addon.name} ($unitPriceFormatted)';
        }).join('\n');

        final addonBlock = '[Item Tambahan / Addon]:\n$addonLines';
        if (finalNotes.isNotEmpty) {
          finalNotes = '$finalNotes\n\n$addonBlock';
        } else {
          finalNotes = addonBlock;
        }
      }

      final updated = await ref.read(agendaServiceProvider).updateAgenda(
        widget.item.id,
        brandId: _brandId,
        clientName: _clientNameController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        backdropTitle: _backdropTitleController.text.trim(),
        eventDateTime: _selectedDateTime,
        eventAddress: _eventAddressController.text.trim(),
        mapsUrl: _mapsUrlController.text.trim(),
        packageId: _packageId,
        packageName: _packageName,
        packagePrice: packagePrice,
        modelId: _modelId,
        modelName: _modelName,
        modelWidth: _modelWidth,
        modelImageUrl: _modelImageUrl,
        modelAdditionalPrice: _modelAdditionalPrice,
        transportFee: transportFee,
        dpAmount: dpAmount,
        paymentStatus: _paymentStatus,
        status: _status,
        notes: finalNotes,
      );

      // Invalidate providers
      ref.invalidate(agendaViewModelProvider);
      ref.invalidate(agendaCalendarViewModelProvider);
      ref.invalidate(dashboardViewModelProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Perubahan agenda berhasil disimpan!',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan perubahan: $e',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primaryGold, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm', 'id_ID');
    final brands = ref.watch(companyBrandsProvider).valueOrNull ?? const <CompanyBrand>[];
    final mainCompanyName = ref.watch(globalAuthProvider).valueOrNull?.companyName ?? 'Brand Utama';
    final isCrew = ref.watch(globalAuthProvider).value?.isCrew ?? false;

    String currentBrandName = 'Brand Utama';
    if (_brandId.isNotEmpty) {
      final found = brands.where((b) => b.id == _brandId).firstOrNull;
      if (found != null) {
        currentBrandName = found.name;
      }
    } else if (mainCompanyName.isNotEmpty) {
      currentBrandName = '$mainCompanyName (Utama)';
    }

    final double totalAddonsPrice = _selectedAddons.fold<double>(0.0, (sum, i) => sum + i.totalPrice);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Edit Agenda Acara', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Informasi Klien & Acara
                    _buildSectionCard(
                      title: 'Informasi Klien & Acara',
                      icon: Icons.person_outline,
                      children: [
                        // Pilihan Brand jika tersedia multi-brand
                        if (brands.isNotEmpty) ...[
                          Text('Pilihan Brand Bisnis', style: AppTypography.caption),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _brandId,
                                items: [
                                  DropdownMenuItem(
                                    value: '',
                                    child: Text(
                                      mainCompanyName.isNotEmpty ? '$mainCompanyName (Utama)' : 'Brand Utama',
                                      style: AppTypography.bodyMedium,
                                    ),
                                  ),
                                  ...brands.map(
                                    (b) => DropdownMenuItem(
                                      value: b.id,
                                      child: Text(b.name, style: AppTypography.bodyMedium),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _brandId = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Nama Klien
                        Text('Nama Klien *', style: AppTypography.caption),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _clientNameController,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama klien',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                            filled: true,
                            fillColor: AppColors.backgroundLight,
                            prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primaryGold, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGold, width: 2)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama klien wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Nomor HP / WhatsApp
                        Text('Nomor WhatsApp / HP', style: AppTypography.caption),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _clientPhoneController,
                          keyboardType: TextInputType.phone,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Contoh: 081234567890',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                            filled: true,
                            fillColor: AppColors.backgroundLight,
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryGold, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGold, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Judul Acara / Backdrop
                        Text('Judul Acara / Tulisan Backdrop', style: AppTypography.caption),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _backdropTitleController,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Contoh: The Engagement of Rian & Nisa',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                            filled: true,
                            fillColor: AppColors.backgroundLight,
                            prefixIcon: const Icon(Icons.celebration_outlined, color: AppColors.primaryGold, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGold, width: 2)),
                          ),
                        ),
                      ],
                    ),

                    // 2. Jadwal & Waktu Acara
                    _buildSectionCard(
                      title: 'Jadwal & Waktu Acara',
                      icon: Icons.calendar_month_outlined,
                      children: [
                        Row(
                          children: [
                            // Tanggal
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryGold),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          dateFormat.format(_selectedDateTime),
                                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Jam
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.access_time_outlined, size: 18, color: AppColors.primaryGold),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${timeFormat.format(_selectedDateTime)} WIB',
                                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 3. Alamat & Lokasi Google Maps
                    _buildSectionCard(
                      title: 'Alamat & Lokasi Acara',
                      icon: Icons.location_on_outlined,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Alamat Acara Lengkap', style: AppTypography.caption),
                            InkWell(
                              onTap: _searchGoogleMaps,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset('assets/icons/google-maps-icon.webp', width: 14, height: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Cari di Maps',
                                      style: AppTypography.caption.copyWith(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _eventAddressController,
                          maxLines: 2,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Nama gedung / jalan / nomor rumah / patokan lokasi',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                            filled: true,
                            fillColor: AppColors.backgroundLight,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGold, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text('Link Google Maps (Opsional)', style: AppTypography.caption),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _mapsUrlController,
                          style: AppTypography.bodySmall,
                          decoration: InputDecoration(
                            hintText: 'https://maps.google.com/?q=...',
                            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                            filled: true,
                            fillColor: AppColors.backgroundLight,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset('assets/icons/google-maps-icon.webp', width: 16, height: 16),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGold, width: 2)),
                          ),
                        ),
                      ],
                    ),

                    // 4. Paket & Model Dekorasi
                    _buildSectionCard(
                      title: 'Paket & Model Dekorasi',
                      icon: Icons.palette_outlined,
                      children: [
                        // Paket
                        Text('Paket Dekorasi', style: AppTypography.caption),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _openPackagePicker(currentBrandName),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.inventory_2_outlined, color: AppColors.primaryGold, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _packageName.isNotEmpty ? _packageName : 'Belum Memilih Paket (Ketuk untuk memilih)',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: _packageName.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                      color: _packageName.isNotEmpty ? AppColors.textDark : AppColors.textLight,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Model Dekorasi
                        Text('Model Backdrop Katalog', style: AppTypography.caption),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _openModelPicker(currentBrandName),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                if (_modelImageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _modelImageUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 48,
                                        height: 48,
                                        color: AppColors.goldLight,
                                        child: const Icon(Icons.view_carousel, color: AppColors.primaryGold),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.goldLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.view_carousel_outlined, color: AppColors.primaryGold, size: 24),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _modelName.isNotEmpty ? _modelName : 'Belum Ada Model Dipilih',
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: _modelName.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                          color: _modelName.isNotEmpty ? AppColors.textDark : AppColors.textLight,
                                        ),
                                      ),
                                      if (_modelWidth.isNotEmpty || _modelAdditionalPrice > 0) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (_modelWidth.isNotEmpty)
                                              Text('Lebar: $_modelWidth', style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                                            if (_modelWidth.isNotEmpty && _modelAdditionalPrice > 0)
                                              const Text(' • ', style: TextStyle(color: Colors.grey)),
                                            if (_modelAdditionalPrice > 0)
                                              Text(
                                                '+${_currencyFormatter.format(_modelAdditionalPrice)}',
                                                style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
                              ],
                            ),
                          ),
                        ),
                        if (_modelId.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _modelId = '';
                                  _modelName = '';
                                  _modelWidth = '';
                                  _modelImageUrl = '';
                                  _modelAdditionalPrice = 0.0;
                                });
                              },
                              icon: const Icon(Icons.clear, size: 14, color: Colors.red),
                              label: Text('Hapus Model Terpilih', style: AppTypography.caption.copyWith(color: Colors.red)),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // 5. Item Tambahan (Add-on)
                    _buildSectionCard(
                      title: 'Item Tambahan (Add-on)',
                      icon: Icons.add_shopping_cart,
                      children: [
                        InkWell(
                          onTap: _openAddonPicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: _selectedAddons.isEmpty
                                ? Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.add_circle_outline, color: AppColors.primaryGold, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pilih Item Tambahan (Add-on)',
                                              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Ketuk untuk memilih dari katalog addon',
                                              style: AppTypography.caption.copyWith(color: AppColors.textLight),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${_selectedAddons.fold<int>(0, (sum, i) => sum + i.quantity)} Item (${_selectedAddons.length} Jenis)',
                                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                          ),
                                          Text(
                                            _currencyFormatter.format(totalAddonsPrice),
                                            style: AppTypography.titleSmall.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      ..._selectedAddons.map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(6)),
                                                child: Text(
                                                  '${item.quantity}x',
                                                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(item.addon.name, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                                              ),
                                              Text(
                                                _currencyFormatter.format(item.totalPrice),
                                                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: _openAddonPicker,
                                            icon: const Icon(Icons.edit, size: 14, color: AppColors.primaryGold),
                                            label: Text(
                                              'Ubah Pilihan Addon',
                                              style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        if (_selectedAddons.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => setState(() => _selectedAddons = []),
                              icon: const Icon(Icons.clear, size: 14, color: Colors.red),
                              label: Text('Hapus Semua Add-on', style: AppTypography.caption.copyWith(color: Colors.red)),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // 6. Rincian Keuangan & Status (Hanya untuk Owner & Admin)
                    if (!isCrew)
                      _buildSectionCard(
                        title: 'Keuangan & Status Agenda',
                        icon: Icons.payments_outlined,
                        children: [
                          // Harga Paket
                          Text('Harga Paket Dekorasi', style: AppTypography.caption),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _packagePriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                            style: AppTypography.bodyMedium,
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
                              prefixStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              hintText: '0',
                              filled: true,
                              fillColor: AppColors.backgroundLight,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGold, width: 2)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Biaya Transport
                          Text('Ongkos Kirim / Uang Transport', style: AppTypography.caption),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _transportFeeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                            style: AppTypography.bodyMedium,
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
                              prefixStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              hintText: '0',
                              filled: true,
                              fillColor: AppColors.backgroundLight,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGold, width: 2)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // DP Masuk
                          Text('Nominal DP Masuk', style: AppTypography.caption),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _dpAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                            style: AppTypography.bodyMedium,
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
                              prefixStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              hintText: '0',
                              filled: true,
                              fillColor: AppColors.backgroundLight,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGold, width: 2)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Status Pembayaran
                          Text('Status Pembayaran', style: AppTypography.caption),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: Center(
                                    child: Text(
                                      'Belum Bayar',
                                      style: AppTypography.caption.copyWith(
                                        color: _paymentStatus == 'unpaid' ? Colors.white : AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  selected: _paymentStatus == 'unpaid',
                                  selectedColor: Colors.red.shade600,
                                  backgroundColor: AppColors.backgroundLight,
                                  onSelected: (_) => setState(() => _paymentStatus = 'unpaid'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ChoiceChip(
                                  label: Center(
                                    child: Text(
                                      'DP Masuk',
                                      style: AppTypography.caption.copyWith(
                                        color: _paymentStatus == 'dp' ? Colors.white : AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  selected: _paymentStatus == 'dp',
                                  selectedColor: Colors.amber.shade700,
                                  backgroundColor: AppColors.backgroundLight,
                                  onSelected: (_) => setState(() => _paymentStatus = 'dp'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ChoiceChip(
                                  label: Center(
                                    child: Text(
                                      'Lunas',
                                      style: AppTypography.caption.copyWith(
                                        color: _paymentStatus == 'paid' ? Colors.white : AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  selected: _paymentStatus == 'paid',
                                  selectedColor: Colors.green.shade600,
                                  backgroundColor: AppColors.backgroundLight,
                                  onSelected: (_) => setState(() => _paymentStatus = 'paid'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Status Acara
                          Text('Status Pelaksanaan Acara', style: AppTypography.caption),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: Center(
                                    child: Text(
                                      'Akan Datang',
                                      style: AppTypography.caption.copyWith(
                                        color: _status == 'upcoming' ? Colors.white : AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  selected: _status == 'upcoming',
                                  selectedColor: AppColors.primaryGold,
                                  backgroundColor: AppColors.backgroundLight,
                                  onSelected: (_) => setState(() => _status = 'upcoming'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ChoiceChip(
                                  label: Center(
                                    child: Text(
                                      'Selesai',
                                      style: AppTypography.caption.copyWith(
                                        color: _status == 'completed' ? Colors.white : AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  selected: _status == 'completed',
                                  selectedColor: Colors.green.shade600,
                                  backgroundColor: AppColors.backgroundLight,
                                  onSelected: (_) => setState(() => _status = 'completed'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ChoiceChip(
                                  label: Center(
                                    child: Text(
                                      'Batal',
                                      style: AppTypography.caption.copyWith(
                                        color: _status == 'cancelled' ? Colors.white : AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  selected: _status == 'cancelled',
                                  selectedColor: Colors.grey.shade600,
                                  backgroundColor: AppColors.backgroundLight,
                                  onSelected: (_) => setState(() => _status = 'cancelled'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    // 7. Catatan Khusus
                    _buildSectionCard(
                      title: 'Catatan Khusus & Request',
                      icon: Icons.notes_outlined,
                      children: [
                        TextFormField(
                          controller: _notesController,
                          maxLines: 4,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Tuliskan catatan khusus atau instruksi tim dekorasi...',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                            filled: true,
                            fillColor: AppColors.backgroundLight,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGold, width: 2)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Save Button
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Simpan Perubahan', style: AppTypography.button),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
