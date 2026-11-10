import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';

/// Mengurai input teks angka berformat ribuan (contoh: "1.500.000") menjadi double.
double parseAgendaCurrencyInput(String text) {
  final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
  return double.tryParse(cleaned) ?? 0.0;
}

/// Mengurai input teks nilai diskon sesuai tipenya ('amount' atau 'percent').
double parseAgendaDiscountInput(String text, String discountType) {
  if (AgendaItem.normalizeDiscountType(discountType) == 'percent') {
    final normalized = text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized) ?? 0.0;
    return parsed < 0 ? 0.0 : parsed;
  }
  return parseAgendaCurrencyInput(text);
}

/// Memformat angka nominal/persentase menjadi teks awal TextEditingController.
String formatAgendaPricingInput(double value, {bool isPercent = false}) {
  if (value <= 0) return '';
  if (isPercent) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
  return NumberFormat('#,###', 'id_ID').format(value.toInt()).replaceAll(',', '.');
}

/// Baris data item ringkasan harga pada tampilan detail/form agenda.
class AgendaSummaryLine {
  const AgendaSummaryLine({
    required this.label,
    required this.amountText,
  });

  final String label;
  final String amountText;
}

/// Input nominal Rupiah dengan formatter ribuan dan ikon opsional dari aset lokal.
class AgendaCurrencyInputField extends StatelessWidget {
  const AgendaCurrencyInputField({
    super.key,
    required this.label,
    required this.controller,
    this.svgIconPath,
    this.hintText = '0',
    this.fillColor = AppColors.backgroundLight,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? svgIconPath;
  final String hintText;
  final Color fillColor;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandsSeparatorInputFormatter(),
          ],
          onChanged: onChanged,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            prefixIcon: svgIconPath != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      svgIconPath!,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primaryGold,
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                : null,
            prefixText: 'Rp ',
            prefixStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
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
    );
  }
}

/// Input diskon fleksibel (Rp atau %) yang hanya memotong subtotal dekorasi (di luar transport).
class AgendaDiscountInputField extends StatelessWidget {
  const AgendaDiscountInputField({
    super.key,
    required this.discountType,
    required this.controller,
    required this.decorSubtotal,
    required this.onTypeChanged,
    required this.onValueChanged,
    this.fillColor = AppColors.backgroundLight,
  });

  final String discountType;
  final TextEditingController controller;
  final double decorSubtotal;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onValueChanged;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final isPercent = AgendaItem.normalizeDiscountType(discountType) == 'percent';
    final rawVal = parseAgendaDiscountInput(controller.text, discountType);
    final effectiveCut = AgendaItem.calculateDiscountAmount(
      decorSubtotal: decorSubtotal,
      discountType: discountType,
      discountValue: rawVal,
    );
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Diskon Harga Dekorasi (Opsional)',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.35),
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DiscountTypePill(
                    label: 'Rp',
                    selected: !isPercent,
                    onTap: () => onTypeChanged('amount'),
                  ),
                  _DiscountTypePill(
                    label: '%',
                    selected: isPercent,
                    onTap: () => onTypeChanged('percent'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isPercent),
          inputFormatters: isPercent
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
              : [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
          onChanged: onValueChanged,
          validator: (val) {
            if (!isPercent) return null;
            final parsed = parseAgendaDiscountInput(val ?? '', 'percent');
            if (parsed > 100) {
              return 'Diskon persen maksimal 100%';
            }
            return null;
          },
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            prefixText: isPercent ? null : 'Rp ',
            prefixStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            suffixText: isPercent ? '%' : null,
            suffixStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
            hintText: isPercent ? '0 (misal: 10)' : '0',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          effectiveCut > 0
              ? 'Potongan: -${currencyFormatter.format(effectiveCut)} (tidak memotong biaya transport)'
              : 'Hanya memotong harga dekorasi (Paket/Model/Add-on), tidak memotong transport.',
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            color: effectiveCut > 0 ? Colors.green.shade700 : AppColors.textLight,
            fontWeight: effectiveCut > 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _DiscountTypePill extends StatelessWidget {
  const _DiscountTypePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

/// Blok ringkasan biaya dengan urutan standar Dekorin:
/// Item Dekorasi -> Subtotal -> Diskon (disembunyikan jika 0) -> Blok Bawah (Transport + Total + DP + Sisa).
class AgendaPricingSummaryBlock extends StatelessWidget {
  const AgendaPricingSummaryBlock({
    super.key,
    required this.lines,
    required this.decorSubtotal,
    required this.discountType,
    required this.discountValue,
    required this.transportFee,
    required this.dpAmount,
    this.title = 'Estimasi Biaya & Pembayaran',
    this.totalLabel = 'TOTAL BIAYA',
    this.dpLabel = 'DP Diterima',
    this.remainingLabel = 'Sisa Pelunasan',
    this.showHeader = true,
    this.showPaymentDetails = true,
    this.containerColor,
  });

  final List<AgendaSummaryLine> lines;
  final double decorSubtotal;
  final String discountType;
  final double discountValue;
  final double transportFee;
  final double dpAmount;
  final String title;
  final String totalLabel;
  final String dpLabel;
  final String remainingLabel;
  final bool showHeader;
  final bool showPaymentDetails;
  final Color? containerColor;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final discountAmount = AgendaItem.calculateDiscountAmount(
      decorSubtotal: decorSubtotal,
      discountType: discountType,
      discountValue: discountValue,
    );
    final discountLabel = AgendaItem.formatDiscountLabel(
      discountType: discountType,
      discountValue: discountValue,
    );
    final netDecor = (decorSubtotal - discountAmount).clamp(0.0, double.infinity);
    final totalBiaya = netDecor + transportFee;
    final sisaPelunasan = (totalBiaya - dpAmount).clamp(0.0, double.infinity);

    return Container(
      padding: showHeader ? const EdgeInsets.all(14) : EdgeInsets.zero,
      decoration: showHeader
          ? BoxDecoration(
              color: containerColor ?? AppColors.goldLight.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.35),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 1. Item Dekorasi (Paket, Model, Add-on)
          ...lines.map((line) => _buildRow(line.label, line.amountText)),

          // 2. Subtotal Dekorasi (sebelum Diskon & di luar Transport)
          if (discountAmount > 0 || transportFee > 0) ...[
            const Divider(height: 16),
            _buildRow(
              'Subtotal Dekorasi',
              currencyFormatter.format(decorSubtotal),
              boldLabel: true,
            ),
          ],

          // 3. Diskon (disembunyikan otomatis jika 0)
          if (discountAmount > 0)
            _buildRow(
              discountLabel,
              '-${currencyFormatter.format(discountAmount)}',
              valueColor: Colors.green.shade700,
            ),

          const SizedBox(height: 8),

          // 4. Blok Bawah Sejajar: Transport + Total + DP + Sisa Pelunasan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: showHeader ? Colors.white.withValues(alpha: 0.85) : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                if (transportFee > 0) ...[
                  _buildRow(
                    'Ongkos Kirim / Transport',
                    '+${currencyFormatter.format(transportFee)}',
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      totalLabel,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(totalBiaya),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                if (showPaymentDetails) ...[
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dpLabel, style: AppTypography.bodySmall),
                      Text(
                        dpAmount > 0 ? '-${currencyFormatter.format(dpAmount)}' : 'Rp 0',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dpAmount > 0 ? Colors.green.shade700 : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        remainingLabel,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(sisaPelunasan),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: sisaPelunasan > 0 ? AppColors.primaryGold : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool boldLabel = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textDark,
                fontWeight: boldLabel ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
