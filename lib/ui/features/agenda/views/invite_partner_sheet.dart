import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/collaboration_service.dart';
import 'package:dekorin_apps/domain/models/collaboration.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';
import 'package:dekorin_apps/ui/features/agenda/widgets/agenda_pricing_widgets.dart';

/// Bottom sheet 3 langkah untuk mengundang vendor partner (MUA, FG, MC, dll.)
/// ke sebuah agenda dengan harga & transport yang ditentukan oleh Lead Vendor.
class InvitePartnerSheet extends ConsumerStatefulWidget {
  const InvitePartnerSheet({super.key, required this.agendaId});

  final String agendaId;

  static Future<bool?> show(BuildContext context, {required String agendaId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvitePartnerSheet(agendaId: agendaId),
    );
  }

  @override
  ConsumerState<InvitePartnerSheet> createState() => _InvitePartnerSheetState();
}

class _InvitePartnerSheetState extends ConsumerState<InvitePartnerSheet> {
  String _selectedCategory = 'mua';
  final _searchController = TextEditingController();
  final _priceController = TextEditingController();
  final _transportController = TextEditingController();
  final _notesController = TextEditingController();

  List<CollaborationVendorOption> _vendors = [];
  CollaborationVendorOption? _selectedVendor;
  bool _isLoadingVendors = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _priceController.dispose();
    _transportController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoadingVendors = true;
      _errorMessage = null;
    });
    try {
      final results = await ref.read(collaborationServiceProvider).searchVendors(
            category: _selectedCategory,
            query: _searchController.text.trim(),
          );
      if (mounted) {
        setState(() {
          _vendors = results;
          if (_selectedVendor != null &&
              !results.any((v) => v.id == _selectedVendor!.id)) {
            _selectedVendor = null;
          }
          _isLoadingVendors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVendors = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedVendor == null) {
      setState(() => _errorMessage = 'Silakan pilih vendor partner terlebih dahulu.');
      return;
    }
    final price = parseAgendaCurrencyInput(_priceController.text);
    final transport = parseAgendaCurrencyInput(_transportController.text);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(collaborationServiceProvider).invitePartner(
            agendaId: widget.agendaId,
            partnerCompanyId: _selectedVendor!.id,
            partnerPrice: price,
            partnerTransportFee: transport,
            notes: _notesController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final price = parseAgendaCurrencyInput(_priceController.text);
    final transport = parseAgendaCurrencyInput(_transportController.text);
    final totalCost = price + transport;
    final currencyFmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final categoryOptions = VendorCategoryOption.all
        .where((c) => c.id != 'decoration')
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Undang Vendor Partner', style: AppTypography.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Pilih tipe usaha, cari vendor, lalu tentukan harga & transport.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Pilih Tipe Company
                  Text(
                    '1. Pilih Tipe Company Partner',
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoryOptions.map((cat) {
                      final selected = _selectedCategory == cat.id;
                      return ChoiceChip(
                        label: Text(
                          cat.shortLabel,
                          style: AppTypography.labelMedium.copyWith(
                            color: selected ? Colors.white : AppColors.textDark,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppColors.primaryGold,
                        backgroundColor: AppColors.backgroundLight,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = cat.id;
                            _selectedVendor = null;
                          });
                          _loadVendors();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // 2. Cari & Pilih Vendor
                  Text(
                    '2. Cari & Pilih Vendor',
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    style: AppTypography.bodyMedium,
                    onChanged: (_) => _loadVendors(),
                    decoration: InputDecoration(
                      hintText: 'Cari nama usaha, kota, atau no. HP...',
                      hintStyle: AppTypography.bodySmall,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
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
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingVendors)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: AppColors.primaryGold),
                      ),
                    )
                  else if (_vendors.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        'Belum ada vendor terdaftar pada kategori ini.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _vendors.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final v = _vendors[idx];
                          final isSelected = _selectedVendor?.id == v.id;
                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: AppColors.goldLight,
                            onTap: () => setState(() => _selectedVendor = v),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.goldLight,
                              child: Icon(
                                Icons.storefront_outlined,
                                size: 18,
                                color: AppColors.primaryGold,
                              ),
                            ),
                            title: Text(
                              v.name,
                              style: AppTypography.titleSmall.copyWith(fontSize: 13),
                            ),
                            subtitle: Text(
                              [v.city, v.phone].where((s) => s.isNotEmpty).join(' • '),
                              style: AppTypography.caption,
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.primaryGold)
                                : null,
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 18),

                  // 3. Nominal Harga & Transport Partner
                  Text(
                    '3. Harga Layanan & Transport Partner',
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nominal ini akan menjadi harga di agenda partner dan mengurangi net revenue paket Anda.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ThousandsSeparatorInputFormatter(),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Harga Partner',
                            labelStyle: AppTypography.caption,
                            prefixText: 'Rp ',
                            prefixStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: AppColors.backgroundLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _transportController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ThousandsSeparatorInputFormatter(),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Transport',
                            labelStyle: AppTypography.caption,
                            prefixText: 'Rp ',
                            prefixStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: AppColors.backgroundLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Catatan / Brief untuk Partner (Opsional)',
                      labelStyle: AppTypography.caption,
                      hintText: 'Contoh: Standby jam 05.00 WIB, tema adat Sunda...',
                      hintStyle: AppTypography.bodySmall,
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Biaya Partner',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.textDark),
                        ),
                        Text(
                          currencyFmt.format(totalCost),
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.secondaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Kirim Undangan Kolaborasi', style: AppTypography.button),
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
}
