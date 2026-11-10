import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/ui/core/widgets/loading_overlay_dialog.dart';
import 'package:dekorin_apps/ui/features/profile/views/form_config_view.dart';

class PendingLinksSheet extends ConsumerStatefulWidget {
  const PendingLinksSheet({super.key});

  @override
  ConsumerState<PendingLinksSheet> createState() => _PendingLinksSheetState();
}

class _PendingLinksSheetState extends ConsumerState<PendingLinksSheet> {
  String _selectedBrandId = '';
  final _labelController = TextEditingController();
  bool _isLoading = true;
  bool _isGenerating = false;
  List<AgendaItem> _pendingLinks = [];
  AgendaItem? _newlyGenerated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingLinks();
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingLinks() async {
    setState(() => _isLoading = true);
    try {
      final list = await ref.read(agendaServiceProvider).getPendingClientLinks();
      if (!mounted) return;
      setState(() {
        _pendingLinks = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat daftar link: $e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _generateLink() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final created = await ref.read(agendaServiceProvider).generateClientFormLink(
            brandId: _selectedBrandId,
            label: _labelController.text.trim(),
          );
      _labelController.clear();
      if (!mounted) return;
      setState(() {
        _newlyGenerated = created;
        _pendingLinks = [created, ..._pendingLinks];
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat link: $e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _deletePendingLink(AgendaItem item) async {
    try {
      await DekorinConfirmActionDialog.show(
        context,
        title: 'Hapus Link Form?',
        message: 'Link ini belum diisi oleh client. Hapus link "${item.clientName}"?',
        confirmLabel: 'Hapus',
        onConfirm: () async {
          await ref.read(agendaServiceProvider).deleteAgenda(item.id);
          if (!mounted) return;
          setState(() {
            _pendingLinks.removeWhere((x) => x.id == item.id);
            if (_newlyGenerated?.id == item.id) {
              _newlyGenerated = null;
            }
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _buildFormUrl(String token) {
    return '${ApiEndpoint.webFormBaseUrl}/form/$token';
  }

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link form berhasil disalin ke clipboard!', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primaryGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareToWhatsApp(String url) async {
    final msg = 'Halo Kak, silakan lengkapi detail acara Anda melalui tautan formulir resmi berikut ini ya:\n\n$url\n\nTerima kasih!';
    final waUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } else {
      await _copyLink(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(companyBrandsProvider).valueOrNull ?? const <CompanyBrand>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.link_rounded, color: AppColors.primaryGold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Link Form Client', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      'Generate link kosong untuk diisi client. Belum tampil di Agenda sampai diisi.',
                      style: AppTypography.caption.copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Atur Daftar Isian Form',
                icon: const Icon(Icons.tune_rounded, color: AppColors.secondaryGold),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FormConfigView()));
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quick Generator Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (brands.isNotEmpty) ...[
                  Text(
                    'Pilih Brand / Sub-Brand:',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(
                            'Brand Utama',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _selectedBrandId.isEmpty ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          selected: _selectedBrandId.isEmpty,
                          selectedColor: AppColors.primaryGold,
                          backgroundColor: Colors.white,
                          onSelected: (_) => setState(() => _selectedBrandId = ''),
                        ),
                        ...brands.map((b) {
                          final sel = _selectedBrandId == b.id;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              label: Text(
                                b.name,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: sel ? Colors.white : AppColors.textDark,
                                ),
                              ),
                              selected: sel,
                              selectedColor: AppColors.primaryGold,
                              backgroundColor: Colors.white,
                              onSelected: (_) => setState(() => _selectedBrandId = b.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  controller: _labelController,
                  style: AppTypography.bodySmall,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Catatan label (opsional, boleh dikosongkan)...',
                    hintStyle: AppTypography.caption,
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
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isGenerating ? null : _generateLink,
                    icon: _isGenerating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                    label: Text(
                      _isGenerating ? 'Membuat Link...' : 'Generate Link Form Client',
                      style: AppTypography.button.copyWith(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Newly Created Link Card
          if (_newlyGenerated != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Link Baru Siap Dibagikan!', style: AppTypography.labelLarge.copyWith(color: Colors.green.shade800)),
                      Text('ID: ${_newlyGenerated!.formToken}', style: AppTypography.caption.copyWith(color: Colors.green.shade700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _buildFormUrl(_newlyGenerated!.formToken),
                    style: AppTypography.caption.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyLink(_buildFormUrl(_newlyGenerated!.formToken)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.green.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: SvgPicture.asset(
                            'assets/icons/copy-alt.svg',
                            width: 15,
                            height: 15,
                            colorFilter: ColorFilter.mode(Colors.green.shade800, BlendMode.srcIn),
                          ),
                          label: Text('Salin Link', style: AppTypography.labelMedium.copyWith(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareToWhatsApp(_buildFormUrl(_newlyGenerated!.formToken)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: SvgPicture.asset(
                            'assets/icons/wa.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          label: Text('Kirim WA', style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menunggu Isian Client (${_pendingLinks.length})',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _loadPendingLinks,
                icon: const Icon(Icons.refresh, size: 18, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                : _pendingLinks.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada link yang menunggu isian client.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _pendingLinks.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final item = _pendingLinks[idx];
                          final url = _buildFormUrl(item.formToken);
                          final createdText = item.createdAt != null
                              ? DateFormat('dd MMM HH:mm', 'id_ID').format(item.createdAt!.toLocal())
                              : '';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.brandName.isNotEmpty ? AppColors.goldLight : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.brandName.isNotEmpty ? item.brandName : 'Brand Utama',
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: item.brandName.isNotEmpty ? AppColors.secondaryGold : AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.clientName.isNotEmpty ? item.clientName : 'Menunggu Isian Client',
                                        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (createdText.isNotEmpty)
                                      Text(createdText, style: AppTypography.caption.copyWith(fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  url,
                                  style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _copyLink(url),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: const Size(0, 32),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: SvgPicture.asset(
                                        'assets/icons/copy-alt.svg',
                                        width: 13,
                                        height: 13,
                                        colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                                      ),
                                      label: Text('Salin', style: AppTypography.caption.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _shareToWhatsApp(url),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF25D366),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: const Size(0, 32),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      icon: SvgPicture.asset(
                                        'assets/icons/wa.svg',
                                        width: 13,
                                        height: 13,
                                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                      ),
                                      label: Text('Kirim WA', style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Hapus Link',
                                      onPressed: () => _deletePendingLink(item),
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.errorRed),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
