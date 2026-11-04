import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/domain/models/expense.dart';

/// Gaya visual dan ikon untuk masing-masing kategori pengeluaran dekorasi.
class ExpenseCategoryStyle {
  const ExpenseCategoryStyle({
    required this.bgColor,
    required this.fgColor,
    this.iconData,
    this.svgAsset,
  });

  final Color bgColor;
  final Color fgColor;
  final IconData? iconData;
  final String? svgAsset;

  /// Membangun widget ikon berdasarkan SVG lokal atau icon material
  Widget buildIcon({double size = 22}) {
    if (svgAsset != null) {
      return SvgPicture.asset(
        svgAsset!,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(fgColor, BlendMode.srcIn),
      );
    }
    return Icon(iconData ?? Icons.receipt_long_outlined, color: fgColor, size: size);
  }

  /// Factory untuk memetakan nama kategori ke gaya warna & ikon yang sesuai
  static ExpenseCategoryStyle fromCategory(String category) {
    final catLower = category.toLowerCase();
    if (catLower.contains('bunga')) {
      return const ExpenseCategoryStyle(
        bgColor: Color(0xFFFCE4EC),
        fgColor: Color(0xFFC2185B),
        iconData: Icons.local_florist_outlined,
      );
    } else if (catLower.contains('properti') || catLower.contains('dekor')) {
      return const ExpenseCategoryStyle(
        bgColor: Color(0xFFF3E5F5),
        fgColor: Color(0xFF7B1FA2),
        iconData: Icons.weekend_outlined,
      );
    } else if (catLower.contains('transport')) {
      return const ExpenseCategoryStyle(
        bgColor: Color(0xFFDCEBFB),
        fgColor: Color(0xFF2E6DA4),
        svgAsset: 'assets/icons/shipping-fast.svg',
      );
    } else if (catLower.contains('crew') || catLower.contains('upah') || catLower.contains('honor')) {
      return const ExpenseCategoryStyle(
        bgColor: Color(0xFFE0F2F1),
        fgColor: Color(0xFF00796B),
        svgAsset: 'assets/icons/user.svg',
      );
    } else if (catLower.contains('operasional')) {
      return const ExpenseCategoryStyle(
        bgColor: Color(0xFFE8F5E9),
        fgColor: Color(0xFF2E7D32),
        svgAsset: 'assets/icons/expense.svg',
      );
    } else {
      return const ExpenseCategoryStyle(
        bgColor: AppColors.goldLight,
        fgColor: Color(0xFF8F6431),
        svgAsset: 'assets/icons/expense.svg',
      );
    }
  }
}

/// Bottom Sheet untuk menampilkan detail lengkap dari satu catatan pengeluaran secara rapi.
class ExpenseDetailBottomSheet extends StatelessWidget {
  const ExpenseDetailBottomSheet({
    super.key,
    required this.expense,
    this.onDelete,
  });

  final ExpenseItem expense;
  final VoidCallback? onDelete;

  /// Membuka modal detail pengeluaran
  static Future<void> show(
    BuildContext context, {
    required ExpenseItem expense,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExpenseDetailBottomSheet(
        expense: expense,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final catStyle = ExpenseCategoryStyle.fromCategory(expense.category);
    final hasTime = expense.date.hour != 0 || expense.date.minute != 0;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDD7CE),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // 2. Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detail Pengeluaran',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: const Color(0xFFF4ECE2),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF5D4A3A)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Hero Card (Icon, Judul, Nominal Utama & Badge)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFF9F2),
                      Color(0xFFF9F3EC),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEBDDCB), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: catStyle.bgColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: catStyle.fgColor.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: catStyle.buildIcon(size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      expense.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '- ${currencyFormatter.format(expense.amount)}',
                      style: AppTypography.h2.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        color: const Color(0xFF9E3329),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF5C6CB), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC0392B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pengeluaran',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: const Color(0xFF9E3329),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Section: Informasi Transaksi
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Informasi Transaksi',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDE8E1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      iconWidget: catStyle.buildIcon(size: 16),
                      iconBg: catStyle.bgColor,
                      label: 'Kategori',
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: catStyle.bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          expense.category,
                          style: AppTypography.bodySmall.copyWith(
                            color: catStyle.fgColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: Color(0xFFF2ECE4)),
                    ),
                    _buildInfoRow(
                      context,
                      iconWidget: SvgPicture.asset(
                        'assets/icons/calendar.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                      ),
                      iconBg: AppColors.goldLight,
                      label: 'Tanggal Transaksi',
                      value: dateFormatter.format(expense.date),
                    ),
                    if (hasTime) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFF2ECE4)),
                      ),
                      _buildInfoRow(
                        context,
                        iconWidget: const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColors.primaryGold,
                        ),
                        iconBg: AppColors.goldLight,
                        label: 'Waktu / Jam',
                        value: '${DateFormat('HH:mm', 'id_ID').format(expense.date)} WIB',
                      ),
                    ],
                    if (expense.id.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFF2ECE4)),
                      ),
                      _buildInfoRow(
                        context,
                        iconWidget: SvgPicture.asset(
                          'assets/icons/copy-alt.svg',
                          width: 15,
                          height: 15,
                          colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                        ),
                        iconBg: AppColors.goldLight,
                        label: 'ID Transaksi',
                        valueWidget: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: expense.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'ID Transaksi berhasil disalin',
                                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    expense.id.length > 14 ? '${expense.id.substring(0, 14)}...' : expense.id,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF555555),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SvgPicture.asset(
                                  'assets/icons/copy-alt.svg',
                                  width: 12,
                                  height: 12,
                                  colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 5. Section: Catatan
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Catatan / Keterangan',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: expense.notes.trim().isNotEmpty ? const Color(0xFFFAF7F2) : const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: expense.notes.trim().isNotEmpty ? const Color(0xFFE8DCCF) : const Color(0xFFEEEEEE),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 19,
                      color: expense.notes.trim().isNotEmpty ? AppColors.primaryGold : AppColors.textLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        expense.notes.trim().isNotEmpty
                            ? expense.notes.trim()
                            : 'Tidak ada catatan tambahan untuk pengeluaran ini.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: expense.notes.trim().isNotEmpty ? AppColors.textDark : AppColors.textLight,
                          fontStyle: expense.notes.trim().isNotEmpty ? FontStyle.normal : FontStyle.italic,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 6. Action Buttons (Hapus & Tutup)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Row(
                  children: [
                    if (onDelete != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.errorRed),
                          label: Text(
                            'Hapus',
                            style: AppTypography.button.copyWith(
                              color: AppColors.errorRed,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF5C6CB)),
                            backgroundColor: const Color(0xFFFDF2F2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: onDelete != null ? 2 : 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryGold, AppColors.secondaryGold],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Tutup',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
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
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required Widget iconWidget,
    required Color iconBg,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: iconWidget,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: const Color(0xFF666666),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: valueWidget ??
                Text(
                  value ?? '',
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontSize: 12,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}
