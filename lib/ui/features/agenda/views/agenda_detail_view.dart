import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/data/services/property_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/ui/core/widgets/loading_overlay_dialog.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_edit_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_pick_list_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/crew_brief_form_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_preview_view.dart';
import 'package:dekorin_apps/ui/features/agenda/widgets/agenda_pricing_widgets.dart';
import 'package:dekorin_apps/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

// Re-export formatter untuk kompatibilitas import di dashboard_view
export 'package:dekorin_apps/ui/core/formatters/thousands_separator_input_formatter.dart';

/// Screen detail agenda acara yang bersih, elegan, dan informatif (read-first).
/// Untuk mengubah rincian agenda, disediakan layar khusus [AgendaEditView].
class AgendaDetailView extends ConsumerStatefulWidget {
  const AgendaDetailView({super.key, required this.item});

  final AgendaItem item;

  @override
  ConsumerState<AgendaDetailView> createState() => _AgendaDetailViewState();
}

class _AgendaDetailViewState extends ConsumerState<AgendaDetailView> {
  late AgendaItem _item;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _updatePaymentStatus(String newStatus) async {
    if (_isUpdatingStatus) return;
    _isUpdatingStatus = true;
    final preservedSchedule = _item.eventDateTime;
    try {
      final updated = await DekorinLoadingDialog.run(
        context,
        message: 'Memperbarui status pembayaran...',
        task: () => ref.read(agendaServiceProvider).updatePaymentStatus(
          _item.id,
          newStatus,
          fallbackEventDateTime: preservedSchedule,
        ),
      );
      if (!mounted) return;
      setState(() {
        _item = preservedSchedule.year > 1970
            ? updated.copyWith(eventDateTime: preservedSchedule)
            : updated;
      });
      ref.invalidate(agendaViewModelProvider);
      ref.invalidate(dashboardViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'paid' ? 'Pembayaran berhasil ditandai LUNAS!' : 'Status pembayaran berhasil diperbarui!',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: newStatus == 'paid' ? Colors.green : AppColors.primaryGold,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status pembayaran: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isUpdatingStatus = false;
    }
  }

  Future<void> _updateEventStatus(String newStatus) async {
    final canEdit = ref.read(globalAuthProvider).value?.canEditAgenda ?? false;
    if (!canEdit || _isUpdatingStatus) return;
    _isUpdatingStatus = true;
    final preservedSchedule = _item.eventDateTime;

    try {
      final updated = await DekorinLoadingDialog.run(
        context,
        message: 'Memperbarui status acara...',
        task: () => ref.read(agendaServiceProvider).updateEventStatus(
          _item.id,
          newStatus,
          fallbackEventDateTime: preservedSchedule,
        ),
      );
      if (!mounted) return;
      setState(() {
        _item = preservedSchedule.year > 1970
            ? updated.copyWith(eventDateTime: preservedSchedule)
            : updated;
      });
      ref.invalidate(agendaViewModelProvider);
      ref.invalidate(dashboardViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'completed' ? 'Acara berhasil ditandai SELESAI!' : 'Status acara berhasil diperbarui!',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: newStatus == 'completed' ? Colors.green : AppColors.primaryGold,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status acara: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isUpdatingStatus = false;
    }
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    if (urlString.trim().isEmpty) return;
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tautan tidak dapat dibuka: $urlString', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka tautan: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
          ),
        );
      }
    }
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    String url = _item.mapsUrl.trim();
    if (url.isEmpty) {
      final address = _item.displayAddress.trim();
      if (address.isNotEmpty) {
        url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
      }
    }
    if (url.isNotEmpty) {
      await _launchUrl(context, url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alamat atau link Google Maps belum diatur.', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _sendWhatsAppMessage(BuildContext context) async {
    final formUrl = '${ApiEndpoint.webFormBaseUrl}/form/${_item.formToken}';

    String phone = _item.clientPhone.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nomor HP tidak valid.', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62') && phone.isNotEmpty) {
      phone = '62$phone';
    }

    final message =
        'Halo Kak ${_item.clientName}, terima kasih telah mempercayakan dekorasi acara Anda kepada kami! ✨\n\n'
        'Berikut adalah rincian detail pesanan / booking acara Anda:\n'
        '$formUrl\n\n'
        'Silakan dicek kembali ya Kak. Jika ada hal yang ingin ditanyakan, hubungi kami. Terima kasih! 🙏';

    final waUrl = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: '$message\n$formUrl'));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Nomor WA tidak dapat dibuka. Pesan & Link disalin ke Clipboard!',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.primaryGold,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: '$message\n$formUrl'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesan & Link disalin ke Clipboard!', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.primaryGold,
          ),
        );
      }
    }
  }

  void _showModelPhotoPreview(BuildContext context, String title, String imageUrl) {
    if (imageUrl.trim().isEmpty) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title, style: AppTypography.titleMedium),
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textDark),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              InteractiveViewer(
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Icon(Icons.broken_image, size: 64, color: AppColors.textLight),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayNotes() {
    String raw = '';
    if (_item.clientForm != null && _item.clientForm!.specialRequests.trim().isNotEmpty) {
      raw = _item.clientForm!.specialRequests.trim();
    } else {
      raw = _item.notes.trim();
    }

    const addonTag = '[Item Tambahan / Addon]:';
    if (raw.contains(addonTag)) {
      raw = raw.split(addonTag)[0].trim();
    }

    const modelTag = '[Model Dekorasi]:';
    if (raw.contains(modelTag)) {
      raw = raw.split('\n').where((l) => !l.trim().startsWith(modelTag)).join('\n').trim();
    }

    return raw;
  }

  Widget _buildEventStatusBadge() {
    final canEdit = ref.watch(globalAuthProvider).value?.canEditAgenda ?? false;
    Color bg;
    Color border;
    Color textCol;
    String label;
    IconData? icon;
    Widget? iconWidget;

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
      iconWidget = SvgPicture.asset(
        'assets/icons/calendar.svg',
        width: 13,
        height: 13,
        colorFilter: ColorFilter.mode(textCol, BlendMode.srcIn),
      );
    }

    final badgeContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget ?? Icon(icon!, size: 13, color: textCol),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: textCol),
          ),
          if (canEdit) ...[
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: textCol),
          ],
        ],
      ),
    );

    if (!canEdit) {
      return badgeContent;
    }

    return PopupMenuButton<String>(
      tooltip: 'Ubah Status Acara',
      onSelected: (val) => _updateEventStatus(val),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'upcoming',
          child: Text('Tandai: Akan Datang', style: AppTypography.labelLarge),
        ),
        PopupMenuItem(
          value: 'completed',
          child: Text('Tandai: Acara Selesai', style: AppTypography.labelLarge),
        ),
        PopupMenuItem(
          value: 'cancelled',
          child: Text('Tandai: Dibatalkan', style: AppTypography.labelLarge),
        ),
      ],
      child: badgeContent,
    );
  }

  List<Widget> _buildAddonsSection(BuildContext context, String rawNotes) {
    final widgets = <Widget>[];
    if (rawNotes.trim().isEmpty) return widgets;

    const addonTag = '[Item Tambahan / Addon]:';
    List<String> addonLines = [];

    if (rawNotes.contains(addonTag)) {
      final parts = rawNotes.split(addonTag);
      if (parts.length > 1) {
        final addonContent = parts[1].trim();
        addonLines = addonContent.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      }
    }

    if (addonLines.isNotEmpty) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_shopping_cart, size: 18, color: AppColors.primaryGold),
                const SizedBox(width: 8),
                Text('Item Tambahan (Add-on)', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    '${addonLines.length} Item',
                    style: AppTypography.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: addonLines.length,
                separatorBuilder: (context, index) => Divider(height: 12, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  String line = addonLines[index];
                  if (line.startsWith('- ')) {
                    line = line.substring(2).trim();
                  }

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
                          decoration: const BoxDecoration(color: AppColors.primaryGold, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(itemName, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            if (pricePart.isNotEmpty)
                              Text(pricePart, style: AppTypography.caption.copyWith(color: AppColors.textLight, fontSize: 11)),
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
      );
    }

    return widgets;
  }

  Widget _buildCleanCard({required List<Widget> children, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
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
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm', 'id_ID');
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final form = _item.clientForm;
    final currentUser = ref.watch(globalAuthProvider).value;
    final bool isCrew = currentUser?.isCrew ?? false;
    final bool canViewPrice = currentUser?.canViewPrice ?? (!isCrew);
    final bool canEditAgenda = currentUser?.canEditAgenda ?? (!isCrew);
    final bool canDownloadInvoice = currentUser?.canDownloadInvoice ?? (!isCrew);

    // Kalkulasi Harga Paket, Addon, Diskon (hanya potong dekorasi) & Transport
    final double packagePrice = _item.effectivePackagePrice;
    final double addonsPrice = _item.effectiveAddonsPrice;
    final double subtotal = packagePrice + _item.modelAdditionalPrice + addonsPrice;
    final double discountAmount = AgendaItem.calculateDiscountAmount(
      decorSubtotal: subtotal,
      discountType: _item.discountType,
      discountValue: _item.discountValue,
    );
    final double transportFee = _item.transportFee;
    final double totalBiaya = (subtotal - discountAmount).clamp(0.0, double.infinity) + transportFee;

    final brands = ref.watch(companyBrandsProvider).valueOrNull ?? const <CompanyBrand>[];
    final mainCompanyName = ref.watch(globalAuthProvider).valueOrNull?.companyName ?? 'Brand Utama';
    final currentBrandLabel = _item.brandName.isNotEmpty
        ? _item.brandName
        : (mainCompanyName.isNotEmpty ? '$mainCompanyName (Utama)' : 'Brand Utama');

    final displayNotes = _getDisplayNotes();
    final address = _item.displayAddress;

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
          // Cetak / Lihat Invoice
          if (canDownloadInvoice)
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/print.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
              ),
              tooltip: 'Cetak Invoice',
              onPressed: () async {
                final res = await Navigator.push<AgendaItem>(
                  context,
                  MaterialPageRoute(builder: (_) => InvoicePreviewView(agenda: _item)),
                );
                if (res != null && mounted) {
                  setState(() => _item = res);
                }
              },
            ),

          // Tombol Edit Agenda Terpusat
          if (canEditAgenda && !_item.isCancelled)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGold),
              tooltip: 'Edit Agenda Acara',
              onPressed: () async {
                final updated = await Navigator.push<AgendaItem>(
                  context,
                  MaterialPageRoute(builder: (_) => AgendaEditView(item: _item)),
                );
                if (updated != null && mounted) {
                  setState(() => _item = updated);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Client Card Header (Identitas Utama Acara)
                  _buildCleanCard(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildEventStatusBadge(),
                          if (brands.isNotEmpty || _item.brandName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.layers_outlined, size: 12, color: AppColors.secondaryGold),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentBrandLabel,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.secondaryGold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_item.displayEventLabel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.textDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _item.displayEventLabel,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (_item.isStandaloneModel)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Model: ${_item.modelName}',
                                style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (_item.packageName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _item.packageName,
                                style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nama Klien & Judul Backdrop
                      Text(_item.clientName, style: AppTypography.h2),
                      if (_item.backdropTitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          _item.backdropTitle,
                          style: AppTypography.titleMedium.copyWith(color: AppColors.primaryGold),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Quick Contact Actions Strip (Klik nomor HP untuk redirect ke WhatsApp)
                      InkWell(
                        onTap: _item.clientPhone.trim().isNotEmpty ? () => _sendWhatsAppMessage(context) : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/mobile-notch.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(AppColors.textLight, BlendMode.srcIn),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _item.clientPhone.isNotEmpty ? _item.clientPhone : 'Belum ada nomor HP',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: _item.clientPhone.isNotEmpty ? AppColors.textDark : AppColors.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 2. Jadwal & Lokasi Acara Card
                  _buildCleanCard(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.goldLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.calendar_today_outlined, color: AppColors.primaryGold, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Jadwal & Lokasi Acara', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Jadwal Tanggal & Jam
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/calendar.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateFormat.format(_item.eventDateTime),
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: AppColors.primaryGold),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Pukul ${timeFormat.format(_item.eventDateTime)} WIB',
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textLight, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Alamat Acara & Navigasi Google Maps
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/marker.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        address.isNotEmpty ? address : 'Alamat spesifik belum ditulis',
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: address.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                          color: address.isNotEmpty ? AppColors.textDark : AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            // Tombol Buka Rute Google Maps (Clean button)
                            InkWell(
                              onTap: () => _openGoogleMaps(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Image.asset('assets/icons/google-maps-icon.webp', width: 20, height: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Buka Rute di Google Maps',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 3. Model Dekorasi & Konsep Card
                  _buildCleanCard(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.goldLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.view_carousel_outlined, color: AppColors.primaryGold, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Model & Konsep Dekorasi', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Model Backdrop Card
                      if (_item.modelName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _item.modelImageUrl.isNotEmpty
                                    ? () => _showModelPhotoPreview(context, _item.modelName, _item.modelImageUrl)
                                    : null,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _item.modelImageUrl.isNotEmpty
                                          ? Image.network(
                                              _item.modelImageUrl,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 64,
                                                height: 64,
                                                color: AppColors.goldLight,
                                                child: const Icon(Icons.view_carousel, color: AppColors.primaryGold, size: 28),
                                              ),
                                            )
                                          : Container(
                                              width: 64,
                                              height: 64,
                                              color: AppColors.goldLight,
                                              child: const Icon(Icons.view_carousel, color: AppColors.primaryGold, size: 28),
                                            ),
                                    ),
                                    if (_item.modelImageUrl.isNotEmpty)
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(Icons.fullscreen, color: Colors.white, size: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _item.modelName,
                                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                    ),
                                    const SizedBox(height: 3),
                                    if (_item.modelWidth.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.straighten, size: 13, color: AppColors.textLight),
                                          const SizedBox(width: 4),
                                          Text('Lebar: ${_item.modelWidth}', style: AppTypography.caption.copyWith(color: AppColors.textDark)),
                                        ],
                                      ),
                                    if (canViewPrice && _item.modelAdditionalPrice > 0) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        _item.isStandaloneModel
                                            ? currencyFormatter.format(_item.modelAdditionalPrice)
                                            : '+${currencyFormatter.format(_item.modelAdditionalPrice)}',
                                        style: AppTypography.caption.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.textLight, size: 18),
                              const SizedBox(width: 8),
                              Text('Belum memilih model katalog backdrop', style: AppTypography.bodySmall.copyWith(color: AppColors.textLight)),
                            ],
                          ),
                        ),

                      // Tema & Preferensi Warna
                      if (form != null && (form.decorationTheme.isNotEmpty || form.colorPreference.isNotEmpty)) ...[
                        const SizedBox(height: 12),
                        if (form.decorationTheme.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.palette_outlined, size: 16, color: AppColors.primaryGold),
                                const SizedBox(width: 8),
                                Text('Tema: ', style: AppTypography.caption),
                                Text(form.decorationTheme, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        if (form.colorPreference.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.color_lens_outlined, size: 16, color: AppColors.primaryGold),
                              const SizedBox(width: 8),
                              Text('Warna: ', style: AppTypography.caption),
                              Expanded(
                                child: Text(form.colorPreference, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                      ],

                      // Item Tambahan (Addon) jika ada
                      if (_item.notes.contains('[Item Tambahan / Addon]:')) ...[
                        const SizedBox(height: 12),
                        ..._buildAddonsSection(context, _item.notes),
                      ],

                      // Foto Inspirasi Dekorasi dari Klien
                      if (form != null && form.referencePhotoUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _launchUrl(context, form.referencePhotoUrl),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
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
                                      Text('Foto Inspirasi Dekorasi (Klien)', style: AppTypography.caption.copyWith(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                                      Text(
                                        form.referencePhotoUrl,
                                        style: AppTypography.bodySmall.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.open_in_new, color: Colors.blue, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // 4. Card Pick List Barang (Logistik & Operasional Muat)
                  Consumer(
                    builder: (context, ref, _) {
                      final pickListAsync = ref.watch(agendaPropertiesProvider(_item.id));
                      final items = pickListAsync.valueOrNull ?? [];
                      final packedCount = items.where((it) => it.isPacked).length;
                      final returnedCount = items.where((it) => it.isReturned).length;
                      final totalCount = items.length;
                      final isAllPacked = totalCount > 0 && packedCount == totalCount;

                      return _buildCleanCard(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isAllPacked ? Colors.green.shade50 : AppColors.goldLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.checklist_rtl_rounded,
                                        color: isAllPacked ? Colors.green.shade700 : AppColors.primaryGold,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Operasional & Pick List Barang',
                                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAllPacked ? Colors.green.shade100 : AppColors.goldLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  totalCount > 0 ? '$packedCount/$totalCount Termuat' : 'Belum Ada',
                                  style: AppTypography.caption.copyWith(
                                    color: isAllPacked ? Colors.green.shade800 : AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (totalCount > 0) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalCount > 0 ? (packedCount / totalCount) : 0,
                                minHeight: 6,
                                backgroundColor: AppColors.backgroundLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isAllPacked ? Colors.green.shade600 : AppColors.primaryGold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Berangkat: $packedCount/$totalCount • Pulang: $returnedCount/$totalCount',
                              style: AppTypography.caption.copyWith(color: AppColors.textLight, fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AgendaPickListView(agenda: _item)),
                                );
                              },
                              icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                              label: Text(
                                totalCount > 0 ? 'Buka & Centang Pick List' : 'Atur Pick List Barang',
                                style: AppTypography.button.copyWith(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAllPacked ? Colors.green.shade600 : AppColors.primaryGold,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CrewBriefFormView(agenda: _item)),
                                );
                              },
                              icon: const Icon(Icons.assignment_outlined, size: 18, color: AppColors.primaryGold),
                              label: Text(
                                'Buat Lembar Kerja Crew A4',
                                style: AppTypography.button.copyWith(fontSize: 13, color: AppColors.primaryGold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // 5. Rincian Tagihan & Pembayaran (Hanya tampil jika memiliki izin canViewPrice)
                  if (canViewPrice) ...[
                    _buildCleanCard(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/icons/file-invoice-dollar.svg',
                                      width: 18,
                                      height: 18,
                                      colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Ringkasan Biaya & Pembayaran',
                                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status Badge Pembayaran
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _item.isPaidOff
                                    ? Colors.green.shade50
                                    : (_item.dpAmount > 0 ? Colors.amber.shade50 : Colors.red.shade50),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _item.isPaidOff
                                      ? Colors.green.shade300
                                      : (_item.dpAmount > 0 ? Colors.amber.shade300 : Colors.red.shade200),
                                ),
                              ),
                              child: Text(
                                _item.isPaidOff ? 'LUNAS' : (_item.dpAmount > 0 ? 'DP MASUK' : 'BELUM BAYAR'),
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _item.isPaidOff
                                      ? Colors.green.shade800
                                      : (_item.dpAmount > 0 ? Colors.amber.shade900 : Colors.red.shade700),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Rincian Baris Biaya (Subtotal -> Diskon -> Blok Transport + Total + DP + Sisa)
                        AgendaPricingSummaryBlock(
                          showHeader: false,
                          totalLabel: 'TOTAL BIAYA',
                          lines: [
                            if (_item.isStandaloneModel)
                              AgendaSummaryLine(
                                label: 'Model Dekorasi (${_item.modelName})',
                                amountText: _item.modelAdditionalPrice > 0
                                    ? currencyFormatter.format(_item.modelAdditionalPrice)
                                    : 'Rp 0',
                              )
                            else ...[
                              AgendaSummaryLine(
                                label: 'Paket: ${_item.packageName.isNotEmpty ? _item.packageName : "Default"}',
                                amountText: packagePrice > 0 ? currencyFormatter.format(packagePrice) : 'Rp 0',
                              ),
                              if (_item.modelAdditionalPrice > 0)
                                AgendaSummaryLine(
                                  label: 'Tambahan Model (${_item.modelName})',
                                  amountText: '+${currencyFormatter.format(_item.modelAdditionalPrice)}',
                                ),
                            ],
                            if (addonsPrice > 0)
                              AgendaSummaryLine(
                                label: 'Add-on Tambahan',
                                amountText: '+${currencyFormatter.format(addonsPrice)}',
                              ),
                          ],
                          decorSubtotal: subtotal,
                          discountType: _item.discountType,
                          discountValue: _item.discountValue,
                          transportFee: transportFee,
                          dpAmount: _item.dpAmount,
                        ),
                        const SizedBox(height: 12),

                        // Quick Aksi: Tandai Lunas jika belum lunas
                        if (!_item.isPaidOff) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: Text('Tandai Pembayaran Lunas?', style: AppTypography.h3),
                                    content: Text(
                                      'Apakah pembayaran agenda untuk "${_item.clientName}" sebesar ${currencyFormatter.format(totalBiaya)} sudah lunas diterima?',
                                      style: AppTypography.bodyMedium,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogCtx),
                                        child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.textLight)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(dialogCtx);
                                          _updatePaymentStatus('paid');
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                        child: Text('Ya, Sudah Lunas', style: AppTypography.button),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: Text('Tandai Pembayaran Lunas', style: AppTypography.button.copyWith(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Tombol Cetak Invoice
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final res = await Navigator.push<AgendaItem>(
                                context,
                                MaterialPageRoute(builder: (_) => InvoicePreviewView(agenda: _item)),
                              );
                              if (res != null && mounted) {
                                setState(() => _item = res);
                              }
                            },
                            icon: SvgPicture.asset(
                              'assets/icons/print.svg',
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                            ),
                            label: Text('Lihat / Cetak Invoice Resmi', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryGold),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // 6. Catatan Khusus & Request Klien Card
                  if (displayNotes.isNotEmpty)
                    _buildCleanCard(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.notes_outlined, color: AppColors.primaryGold, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Catatan & Request Klien', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(
                            displayNotes,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark, height: 1.4),
                          ),
                        ),
                      ],
                    ),

                  // 7. Hasil Isian Form Link Client & Status Penguncian
                  if (_item.formStatus.toLowerCase() == 'filled' || (form != null && form.customAnswers.isNotEmpty))
                    _buildCleanCard(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/lock.svg',
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(Colors.green.shade700, BlendMode.srcIn),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Isian Form Client (${_item.formStatus == 'filled' ? 'Terkonfirmasi & Terkunci' : 'Menunggu'})',
                                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Client tidak dapat mengubah data saat link terkunci.',
                                    style: AppTypography.caption.copyWith(color: AppColors.textLight),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (form != null && form.customAnswers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...form.customAnswers.map((ans) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ans.label,
                                    style: AppTypography.caption.copyWith(color: AppColors.textLight, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  if (ans.type == 'image' && ans.value.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        ans.value,
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Text(
                                          ans.value,
                                          style: AppTypography.caption.copyWith(color: AppColors.primaryGold),
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      ans.value,
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                        if (canEditAgenda && _item.formStatus.toLowerCase() == 'filled') ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  final unlocked = await DekorinConfirmActionDialog.show(
                                    context,
                                    title: 'Buka Kunci Form Client?',
                                    message: 'Link form akan kembali ke mode pengisian agar client bisa mengubah atau melengkapi data melalui link yang sama.',
                                    confirmLabel: 'Buka Kunci',
                                    confirmColor: AppColors.primaryGold,
                                    onConfirm: () async {
                                      final updated = await ref.read(agendaServiceProvider).unlockAgendaForm(_item.id);
                                      if (mounted) {
                                        setState(() => _item = updated);
                                        ref.read(agendaViewModelProvider.notifier).refresh();
                                      }
                                    },
                                  );
                                  if (unlocked && mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Form berhasil dibuka kembali untuk client!', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                                        backgroundColor: AppColors.successGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal membuka kunci: $e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.lock_open_rounded, size: 16, color: AppColors.secondaryGold),
                              label: Text('Buka Kunci Form (Izinkan Client Isi Ulang)', style: AppTypography.labelMedium.copyWith(color: AppColors.secondaryGold, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primaryGold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -3)),
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
                            content: Text('Link form pesanan disalin ke clipboard!', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                            backgroundColor: AppColors.primaryGold,
                          ),
                        );
                      },
                      icon: SvgPicture.asset(
                        'assets/icons/copy-alt.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                      ),
                      label: Text('Salin Link', style: AppTypography.labelLarge.copyWith(color: AppColors.textDark)),
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
                      icon: const Icon(Icons.send, size: 16),
                      label: Text('Bagikan ke WA', style: AppTypography.button),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
}
