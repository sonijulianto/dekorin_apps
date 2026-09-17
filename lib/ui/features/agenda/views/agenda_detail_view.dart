import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';

class AgendaDetailView extends StatelessWidget {
  const AgendaDetailView({super.key, required this.item});

  final AgendaItem item;

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tautan tidak dapat dibuka: $urlString')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka tautan: $e')),
        );
      }
    }
  }

  Future<void> _sendWhatsAppMessage(BuildContext context) async {
    final formUrl = '${ApiEndpoint.webFormBaseUrl}/form/${item.formToken}';

    String phone = item.clientPhone.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62') && phone.isNotEmpty) {
      phone = '62$phone';
    }

    final message =
        'Halo Kak ${item.clientName}, terima kasih telah memesan dekorasi di Dekorin! ✨\n\n'
        'Mohon bantu lengkapi detail acara (alamat, tema, warna, dll) melalui tautan berikut ya:\n'
        '$formUrl';

    final waUrl = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: '$message\n$formUrl'));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nomor WA tidak dapat dibuka. Pesan & Link disalin ke Clipboard!'),
              backgroundColor: AppColors.primaryGold,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: '$message\n$formUrl'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesan & Link disalin ke Clipboard!'),
            backgroundColor: AppColors.primaryGold,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm', 'id_ID');
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isFilled = item.formStatus == 'filled';
    final form = item.clientForm;

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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Client Card Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFilled ? Colors.green.shade50 : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isFilled ? Colors.green.shade300 : Colors.amber.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFilled ? Icons.check_circle : Icons.hourglass_top,
                                    size: 14,
                                    color: isFilled ? Colors.green.shade700 : Colors.amber.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isFilled ? 'Form Terisi' : 'Menunggu Form Client',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isFilled ? Colors.green.shade700 : Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item.packageName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.goldLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.packageName,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(item.clientName, style: AppTypography.h2),
                        if (item.backdropTitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.backdropTitle,
                            style: AppTypography.titleMedium.copyWith(color: AppColors.primaryGold),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Action Contacts
                        Row(
                          children: [
                            const Icon(Icons.phone_android, size: 18, color: AppColors.textLight),
                            const SizedBox(width: 8),
                            Text(
                              item.clientPhone.isNotEmpty ? item.clientPhone : 'Belum ada nomor HP',
                              style: AppTypography.bodyMedium,
                            ),
                            const Spacer(),
                            if (item.clientPhone.isNotEmpty) ...[
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.blue, size: 20),
                                tooltip: 'Telepon Client',
                                onPressed: () => _launchUrl(context, 'tel:${item.clientPhone}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                tooltip: 'WhatsApp Client',
                                onPressed: () => _sendWhatsAppMessage(context),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Integrated Event & Decoration Information Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informasi Acara & Dekorasi', style: AppTypography.titleMedium),
                        const SizedBox(height: 14),

                        // Tanggal & Jam
                        _buildInfoRow(
                          Icons.calendar_month_outlined,
                          'Jadwal Acara',
                          '${dateFormat.format(item.eventDateTime)} • ${timeFormat.format(item.eventDateTime)} WIB',
                        ),
                        const SizedBox(height: 12),

                        // Alamat Acara (dari form client atau notes)
                        if (form != null && form.eventAddress.isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            'Alamat Acara',
                            form.eventAddress,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Link Google Maps
                        if (item.mapsUrl.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.map_outlined, size: 20, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Link Google Maps', style: AppTypography.caption),
                                    const SizedBox(height: 2),
                                    GestureDetector(
                                      onTap: () => _launchUrl(context, item.mapsUrl),
                                      child: Text(
                                        item.mapsUrl,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Tema Dekorasi
                        if (form != null && form.decorationTheme.isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.palette_outlined,
                            'Tema Dekorasi',
                            form.decorationTheme,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Warna Favorit
                        if (form != null && form.colorPreference.isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.color_lens_outlined,
                            'Preferensi Warna',
                            form.colorPreference,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Permintaan Khusus / Catatan
                        if ((form != null && form.specialRequests.isNotEmpty) || item.notes.isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.notes_outlined,
                            'Catatan & Permintaan Khusus',
                            form?.specialRequests.isNotEmpty == true
                                ? form!.specialRequests
                                : item.notes,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Foto Inspirasi
                        if (form != null && form.referencePhotoUrl.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () => _launchUrl(context, form.referencePhotoUrl),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
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
                                        Text('Foto Inspirasi Dekorasi', style: AppTypography.caption.copyWith(color: Colors.blue.shade900)),
                                        Text(
                                          form.referencePhotoUrl,
                                          style: AppTypography.bodySmall.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new, color: Colors.blue, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Rincian Invoice Card
                  if (form != null && (form.totalPrice > 0 || form.packagePrice > 0)) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long_outlined, color: AppColors.primaryGold, size: 22),
                              const SizedBox(width: 8),
                              Text('Rincian Invoice & Kalkulasi Biaya', style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (form.packageName.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Paket: ${form.packageName}', style: AppTypography.bodyMedium),
                                Text(currencyFormatter.format(form.packagePrice), style: AppTypography.titleSmall),
                              ],
                            ),
                          if (form.selectedAddons.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text('Addon: ${form.selectedAddons}', style: AppTypography.bodyMedium),
                                ),
                                const SizedBox(width: 8),
                                Text(currencyFormatter.format(form.addonsPrice), style: AppTypography.titleSmall),
                              ],
                            ),
                          ],
                          const Divider(height: 20, color: AppColors.primaryGold),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL INVOICE', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                currencyFormatter.format(form.totalPrice),
                                style: AppTypography.h2.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final formUrl = '${ApiEndpoint.webFormBaseUrl}/form/${item.formToken}';
                        Clipboard.setData(ClipboardData(text: formUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Link form disalin: $formUrl'),
                            backgroundColor: AppColors.primaryGold,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Salin Link'),
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
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Bagikan ke WA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              const SizedBox(height: 1),
              Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
