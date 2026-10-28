import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/expense_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/dashboard_summary.dart';
import 'package:dekorin_apps/domain/models/expense.dart';
import 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_detail_view.dart' hide ThousandsSeparatorInputFormatter;
import 'package:dekorin_apps/ui/features/dashboard/view_models/dashboard_view_model.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardViewModelProvider);

    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddExpenseModal(context, ref),
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_shopping_cart),
          label: Text(
            'Catat Pengeluaran',
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: dashboardState.when(
          data: (data) => RefreshIndicator(
            onRefresh: () => ref.read(dashboardViewModelProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Ringkasan Finansial & Booking
                _buildSummaryCards(data.summary),
                const SizedBox(height: 16),

                // 2. Tombol Aksi Cepat Input Pengeluaran
                InkWell(
                  onTap: () => _showAddExpenseModal(context, ref),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.post_add, color: AppTheme.primaryGold, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ada Pengeluaran Baru?',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                'Catat belanja bunga, properti dekor, sewa mobil, dll',
                                style: AppTypography.caption.copyWith(color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textLight),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Section Pengeluaran Terkini
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pengeluaran Terkini', style: AppTypography.titleLarge),
                    Text(
                      '${data.summary.recentExpenses.length} transaksi',
                      style: AppTypography.caption.copyWith(color: AppTheme.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRecentExpensesList(context, ref, data.summary.recentExpenses),
                const SizedBox(height: 24),

                // 4. Section Booking Mendatang
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Booking Mendatang (>= Hari Ini)', style: AppTypography.titleLarge),
                    Text(
                      '${data.summary.upcomingBookingsCount} Event',
                      style: AppTypography.caption.copyWith(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildUpcomingAgendasList(context, ref, data.summary.upcomingAgendas),
                const SizedBox(height: 80), // Padding untuk FAB
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
                const SizedBox(height: 16),
                Text('Terjadi kesalahan:\n$error', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(dashboardViewModelProvider.notifier).refresh(),
                  child: Text('Coba Lagi', style: AppTypography.button),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DashboardSummary summary) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      children: [
        // Baris 1: Pendapatan & Pengeluaran
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Pendapatan',
                subtitle: 'Hanya agenda lunas',
                value: currencyFormatter.format(summary.totalRevenue),
                icon: Icons.account_balance_wallet,
                color: AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Pengeluaran',
                subtitle: 'Biaya operasional',
                value: currencyFormatter.format(summary.totalExpense),
                iconWidget: SvgPicture.asset(
                  'assets/icons/expense.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(Colors.orange.shade700, BlendMode.srcIn),
                ),
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Baris 2: Keuntungan & Booking Mendatang
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Keuntungan',
                subtitle: 'Pendapatan - Beban',
                value: currencyFormatter.format(summary.totalProfit),
                iconWidget: SvgPicture.asset(
                  'assets/icons/chat-arrow-grow.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(Colors.blue.shade700, BlendMode.srcIn),
                ),
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Agenda',
                subtitle: 'Jadwal \u2265 Hari Ini',
                value: '${summary.upcomingBookingsCount} Event',
                iconWidget: SvgPicture.asset(
                  'assets/icons/calendar.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(AppTheme.primaryGold, BlendMode.srcIn),
                ),
                color: AppTheme.primaryGold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentExpensesList(BuildContext context, WidgetRef ref, List<ExpenseItem> expenses) {
    if (expenses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            'Belum ada catatan pengeluaran.',
            style: AppTypography.bodyMedium.copyWith(color: AppTheme.textLight, fontSize: 13),
          ),
        ),
      );
    }

    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final exp = expenses[index];
        IconData? categoryIcon = Icons.payments_outlined;
        Widget? categoryIconWidget;
        Color categoryColor = Colors.orange;

        final catLower = exp.category.toLowerCase();
        if (catLower.contains('bunga')) {
          categoryIcon = Icons.local_florist;
          categoryColor = Colors.pink;
        } else if (catLower.contains('properti') || catLower.contains('dekor')) {
          categoryIcon = Icons.weekend;
          categoryColor = Colors.purple;
        } else if (catLower.contains('transport') || catLower.contains('operasional')) {
          categoryColor = Colors.blue;
          categoryIconWidget = SvgPicture.asset(
            'assets/icons/shipping-fast.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(categoryColor, BlendMode.srcIn),
          );
        } else if (catLower.contains('crew') || catLower.contains('upah')) {
          categoryIcon = Icons.group;
          categoryColor = Colors.teal;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: categoryIconWidget ?? Icon(categoryIcon, color: categoryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.title,
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exp.category} \u2022 ${dateFormatter.format(exp.date)}',
                      style: AppTypography.caption.copyWith(color: AppTheme.textLight, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '- ${currencyFormatter.format(exp.amount)}',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.red.shade700,
                    ),
                  ),
                  InkWell(
                    onTap: () => _confirmDeleteExpense(context, ref, exp),
                    child: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Hapus', style: AppTypography.caption.copyWith(color: Colors.grey, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteExpense(BuildContext context, WidgetRef ref, ExpenseItem exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Pengeluaran?', style: AppTypography.h3),
        content: Text('Yakin ingin menghapus catatan "${exp.title}"?', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(expenseServiceProvider).deleteExpense(exp.id);
                ref.read(dashboardViewModelProvider.notifier).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pengeluaran berhasil dihapus',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus: $e',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAgendasList(BuildContext context, WidgetRef ref, List<AgendaItem> agendas) {
    if (agendas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            'Tidak ada booking mendatang yang terjadwal.',
            style: AppTypography.bodyMedium.copyWith(color: AppTheme.textLight),
          ),
        ),
      );
    }

    final dateFormatter = DateFormat('EEEE, dd MMM yyyy', 'id_ID');
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: agendas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final agenda = agendas[index];

        return InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaDetailView(item: agenda))).then((_) {
              ref.read(dashboardViewModelProvider.notifier).refresh();
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        agenda.clientName,
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Payment Status Badge
                    _PaymentStatusBadge(isPaid: agenda.isPaidOff, dpAmount: agenda.dpAmount),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.celebration, size: 15, color: AppTheme.primaryGold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        agenda.backdropTitle.isNotEmpty ? agenda.backdropTitle : agenda.packageName,
                        style: AppTypography.bodySmall.copyWith(color: AppTheme.textDark, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/calendar.svg',
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(AppTheme.textLight, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateFormatter.format(agenda.eventDateTime),
                      style: AppTypography.bodySmall.copyWith(color: AppTheme.textLight, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      currencyFormatter.format(agenda.calculatedTotalPrice),
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddExpenseModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddExpenseBottomSheet(ref: ref),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.isPaid, required this.dpAmount});

  final bool isPaid;
  final double dpAmount;

  @override
  Widget build(BuildContext context) {
    if (isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 11, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              'Lunas',
              style: AppTypography.caption.copyWith(
                color: Colors.green.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (dpAmount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.shade400),
        ),
        child: Text(
          'DP Masuk',
          style: AppTypography.caption.copyWith(
            color: Colors.amber.shade900,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          'Belum Bayar',
          style: AppTypography.caption.copyWith(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    this.subtitle,
    required this.value,
    this.icon,
    this.iconWidget,
    required this.color,
  });

  final String title;
  final String? subtitle;
  final String value;
  final IconData? icon;
  final Widget? iconWidget;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: iconWidget ?? Icon(icon!, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.caption.copyWith(color: AppTheme.textLight, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 15, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AddExpenseBottomSheet extends StatefulWidget {
  const _AddExpenseBottomSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<_AddExpenseBottomSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Bunga';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _categories = ['Bunga', 'Properti Dekor', 'Operasional', 'Transport', 'Honor Crew', 'Lainnya'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan judul/keterangan pengeluaran',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan nominal pengeluaran yang valid',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.ref
          .read(expenseServiceProvider)
          .createExpense(
            title: title,
            amount: amount,
            category: _selectedCategory,
            date: _selectedDate,
            notes: _notesController.text.trim(),
          );

      widget.ref.read(dashboardViewModelProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pengeluaran berhasil dicatat!',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mencatat pengeluaran: $e',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryGold, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('Catat Pengeluaran', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),

            // Keterangan / Judul
            Text(
              'Keterangan Pengeluaran *',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Misal: Pembelian Bunga Mawar & Baby Breath',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Nominal Pengeluaran
            Text(
              'Nominal Biaya (Rp) *',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                hintText: '500.000',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Kategori
            Text('Kategori *', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected ? AppTheme.primaryGold : AppTheme.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGold.withValues(alpha: 0.2),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Tanggal Pengeluaran
            Text(
              'Tanggal Transaksi',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateFormatter.format(_selectedDate), style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                    SvgPicture.asset(
                      'assets/icons/calendar.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(AppTheme.primaryGold, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Catatan Tambahan
            Text(
              'Catatan Tambahan (Opsional)',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Toko/vendor, no. nota, dll',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Simpan Pengeluaran',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
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
